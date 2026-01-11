#!/usr/bin/env python3
"""
Merge leads from multiple sources (local + server)
==================================================
Deduplicates by (name, website) and keeps the most complete record.

Usage:
    python3 scripts/utils/merge_leads.py --inputs local.csv server.csv --output merged.csv
    python3 scripts/utils/merge_leads.py --dir detector_output/florida --output florida_merged.csv
"""

import csv
import argparse
import os
from pathlib import Path


def normalize_key(name: str, website: str) -> tuple:
    """Create a normalized key for deduplication."""
    name = (name or "").strip().lower()
    website = (website or "").strip().lower()
    # Remove protocol and www
    website = website.replace("https://", "").replace("http://", "").replace("www.", "")
    website = website.rstrip("/")
    return (name, website)


def score_row(row: dict) -> int:
    """Score a row by completeness - higher is better."""
    score = 0
    # Prioritize rows with booking URLs
    if row.get("booking_url"):
        score += 100
    # Prioritize known engines over unknown
    engine = row.get("booking_engine", "")
    if engine and engine not in ("unknown", "unknown_booking_api", "unknown_third_party"):
        score += 50
    # Prioritize rows without errors
    if not row.get("error"):
        score += 30
    # Count non-empty fields
    for key, val in row.items():
        if val and str(val).strip():
            score += 1
    return score


def merge_files(input_files: list, output_file: str) -> dict:
    """Merge multiple CSV files, keeping best record per hotel."""
    seen = {}  # key -> (row, score, source_file)
    fieldnames = None
    stats = {"total_input": 0, "duplicates": 0, "output": 0}

    for filepath in input_files:
        if not os.path.exists(filepath):
            print(f"  Skipping (not found): {filepath}")
            continue

        print(f"  Reading: {filepath}")
        with open(filepath, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            if fieldnames is None:
                fieldnames = reader.fieldnames
            else:
                # Merge fieldnames from all files
                for fn in reader.fieldnames:
                    if fn not in fieldnames:
                        fieldnames.append(fn)

            for row in reader:
                stats["total_input"] += 1
                name = row.get("name") or row.get("hotel", "")
                website = row.get("website", "")
                key = normalize_key(name, website)

                if not key[0] and not key[1]:
                    continue

                score = score_row(row)

                if key in seen:
                    stats["duplicates"] += 1
                    existing_score = seen[key][1]
                    if score > existing_score:
                        seen[key] = (row, score, filepath)
                else:
                    seen[key] = (row, score, filepath)

    # Write output
    if not seen:
        print("  No records to write!")
        return stats

    stats["output"] = len(seen)

    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for key, (row, score, source) in sorted(seen.items()):
            writer.writerow(row)

    return stats


def find_leads_files(directory: str, pattern: str = "*_leads.csv") -> list:
    """Find all leads files in a directory."""
    from glob import glob
    files = glob(os.path.join(directory, pattern))
    # Exclude backup and aggregate files
    files = [f for f in files if not f.endswith(".bak")
             and "_all_leads" not in f
             and "_merged" not in f]
    return sorted(files)


def main():
    parser = argparse.ArgumentParser(description="Merge leads from multiple sources")
    parser.add_argument("--inputs", "-i", nargs="+", help="Input CSV files to merge")
    parser.add_argument("--dir", "-d", help="Directory to find *_leads.csv files")
    parser.add_argument("--output", "-o", required=True, help="Output merged CSV file")
    parser.add_argument("--pattern", default="*_leads.csv", help="Glob pattern for --dir")
    args = parser.parse_args()

    if args.dir:
        input_files = find_leads_files(args.dir, args.pattern)
    elif args.inputs:
        input_files = args.inputs
    else:
        parser.error("Must specify --inputs or --dir")

    if not input_files:
        print("No input files found!")
        return

    print(f"\nMerging {len(input_files)} files...")
    stats = merge_files(input_files, args.output)

    print(f"\n✅ Merge complete:")
    print(f"   Input rows:  {stats['total_input']}")
    print(f"   Duplicates:  {stats['duplicates']}")
    print(f"   Output rows: {stats['output']}")
    print(f"   Output file: {args.output}")


if __name__ == "__main__":
    main()
