#!/usr/bin/env python3
"""
Merge and deduplicate CSV files.

Usage:
    # Merge specific files:
    python3 merge_unique.py file1.csv file2.csv file3.csv -o merged.csv
    
    # Merge all CSVs in a folder:
    python3 merge_unique.py scraper_output/*.csv -o all_hotels.csv
    
    # Merge with custom dedup key:
    python3 merge_unique.py *.csv -o merged.csv --key hotel,phone
"""

import argparse
import csv
import glob
import os
import re
import sys
from collections import OrderedDict


def normalize_name(name: str) -> str:
    """Normalize hotel name for deduplication."""
    if not name:
        return ""
    # Lowercase, remove extra whitespace, remove common suffixes
    name = name.lower().strip()
    name = re.sub(r'\s+', ' ', name)
    # Remove common hotel suffixes for matching
    for suffix in [' hotel', ' motel', ' inn', ' resort', ' suites', ' apartments']:
        if name.endswith(suffix):
            name = name[:-len(suffix)]
    return name


def normalize_phone(phone: str) -> str:
    """Normalize phone number - keep only digits."""
    if not phone:
        return ""
    return re.sub(r'[^\d]', '', phone)


def get_dedup_key(row: dict, key_columns: list) -> str:
    """Create a deduplication key from specified columns."""
    parts = []
    for col in key_columns:
        val = row.get(col, "") or ""
        if col in ['hotel', 'name', 'title']:
            val = normalize_name(val)
        elif col == 'phone':
            val = normalize_phone(val)
        else:
            val = val.lower().strip()
        parts.append(val)
    return "|".join(parts)


def merge_csv_files(input_files: list, output_file: str, key_columns: list, verbose: bool = True):
    """Merge multiple CSV files and deduplicate."""
    
    all_rows = []
    all_fieldnames = OrderedDict()
    files_processed = 0
    
    for pattern in input_files:
        # Handle glob patterns
        files = glob.glob(pattern) if '*' in pattern else [pattern]
        
        for filepath in files:
            if not os.path.isfile(filepath):
                if verbose:
                    print(f"  Skip (not a file): {filepath}")
                continue
            
            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    # Detect delimiter
                    sample = f.read(2048)
                    f.seek(0)
                    
                    if '\t' in sample and sample.count('\t') > sample.count(','):
                        delimiter = '\t'
                    else:
                        delimiter = ','
                    
                    reader = csv.DictReader(f, delimiter=delimiter)
                    
                    # Track all fieldnames
                    if reader.fieldnames:
                        for fn in reader.fieldnames:
                            all_fieldnames[fn] = True
                    
                    rows_in_file = 0
                    for row in reader:
                        all_rows.append(row)
                        rows_in_file += 1
                    
                    files_processed += 1
                    if verbose:
                        print(f"  ✓ {filepath}: {rows_in_file} rows")
                        
            except Exception as e:
                if verbose:
                    print(f"  ✗ {filepath}: {e}")
    
    if verbose:
        print(f"\nTotal: {len(all_rows)} rows from {files_processed} files")
    
    # Deduplicate
    seen = set()
    unique_rows = []
    duplicates = 0
    
    for row in all_rows:
        key = get_dedup_key(row, key_columns)
        
        # Skip if empty key
        if not key or key == "|" * (len(key_columns) - 1):
            continue
        
        if key in seen:
            duplicates += 1
            continue
        
        seen.add(key)
        unique_rows.append(row)
    
    if verbose:
        print(f"Duplicates removed: {duplicates}")
        print(f"Unique rows: {len(unique_rows)}")
    
    # Write output
    fieldnames = list(all_fieldnames.keys())
    
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(unique_rows)
    
    if verbose:
        print(f"\nOutput: {output_file}")
    
    return len(unique_rows)


def main():
    parser = argparse.ArgumentParser(
        description="Merge and deduplicate CSV files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 merge_unique.py file1.csv file2.csv -o merged.csv
  python3 merge_unique.py 'scraper_output/*.csv' -o all.csv
  python3 merge_unique.py *.csv -o merged.csv --key hotel
  python3 merge_unique.py *.csv -o merged.csv --key hotel,phone
        """
    )
    
    parser.add_argument('files', nargs='+', help='CSV files to merge (supports glob patterns)')
    parser.add_argument('-o', '--output', default='merged_unique.csv', help='Output file')
    parser.add_argument('--key', default='hotel', 
                        help='Comma-separated column names to use as dedup key (default: hotel)')
    parser.add_argument('-q', '--quiet', action='store_true', help='Quiet mode')
    
    args = parser.parse_args()
    
    key_columns = [k.strip() for k in args.key.split(',')]
    
    if not args.quiet:
        print(f"Merging {len(args.files)} file pattern(s)...")
        print(f"Dedup key: {key_columns}")
        print()
    
    count = merge_csv_files(
        input_files=args.files,
        output_file=args.output,
        key_columns=key_columns,
        verbose=not args.quiet
    )
    
    return 0 if count > 0 else 1


if __name__ == "__main__":
    sys.exit(main())

