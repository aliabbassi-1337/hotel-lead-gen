#!/usr/bin/env python3
"""
Sadie Deduplication Script
===========================
Deduplicates leads based on name + domain combination.

Usage:
    python3 sadie_dedupe.py detector_output/sydney_leads_split_post.csv
    python3 sadie_dedupe.py --all  # Process all post files
"""

import csv
import glob
import os
import sys
from urllib.parse import urlparse
from datetime import datetime


def extract_domain(url: str) -> str:
    """Extract just the domain from a URL (e.g., 'example.com' from 'https://www.example.com/page/stuff')"""
    if not url:
        return ""
    
    url = url.strip().lower()
    
    # Add scheme if missing
    if not url.startswith(('http://', 'https://')):
        url = 'http://' + url
    
    try:
        parsed = urlparse(url)
        domain = parsed.netloc or parsed.path.split('/')[0]
        
        # Remove www. prefix
        if domain.startswith('www.'):
            domain = domain[4:]
        
        # Remove port if present
        if ':' in domain:
            domain = domain.split(':')[0]
        
        return domain
    except:
        return ""


def normalize_name(name: str) -> str:
    """Normalize hotel name for comparison."""
    if not name:
        return ""
    
    # Lowercase, strip, remove common suffixes
    name = name.strip().lower()
    
    # Remove trailing punctuation
    name = name.rstrip('.,!?')
    
    # Remove common suffixes that don't affect uniqueness
    suffixes = [' hotel', ' motel', ' inn', ' resort', ' lodge', ' suites', ' b&b', ' bnb']
    for suffix in suffixes:
        if name.endswith(suffix):
            name = name[:-len(suffix)]
    
    return name


def create_unique_key(name: str, website: str) -> str:
    """Create unique key from name + domain."""
    norm_name = normalize_name(name)
    domain = extract_domain(website)
    
    # If no domain, just use name
    if not domain:
        return f"NAME:{norm_name}"
    
    # Combine name + domain
    return f"{norm_name}|{domain}"


def find_duplicates(filepath: str, apply: bool = False) -> tuple:
    """Find duplicates in a CSV file. 
    If apply=True, removes duplicates and saves the file.
    Returns (duplicates_list, rows_removed_count)
    """
    
    if not os.path.exists(filepath):
        print(f"  ✗ File not found: {filepath}")
        return [], 0
    
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    
    # Track first occurrence of each key
    first_seen = {}  # key -> row
    duplicates = []  # list of duplicate info
    unique_rows = []  # rows to keep
    
    for r in rows:
        name = r.get('name', '')
        website = r.get('website', '')
        
        key = create_unique_key(name, website)
        
        if key in first_seen:
            # This is a duplicate - record both the original and the duplicate
            duplicates.append({
                'key': key,
                'kept': {
                    'name': first_seen[key].get('name', ''),
                    'website': first_seen[key].get('website', ''),
                    'booking_url': first_seen[key].get('booking_url', '')[:50],
                },
                'duplicate': {
                    'name': name,
                    'website': website,
                    'booking_url': r.get('booking_url', '')[:50],
                }
            })
            # Don't add to unique_rows (this is the duplicate)
        else:
            first_seen[key] = r
            unique_rows.append(r)
    
    removed_count = 0
    if apply and duplicates:
        # Write back without duplicates
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(unique_rows)
        removed_count = len(duplicates)
    
    return duplicates, removed_count


def main():
    # Default files to process (canonical list)
    # Dynamically find all post-processed files
    all_files = sorted(glob.glob('detector_output/*_post.csv'))
    
    # Exclude old/backup files
    exclude_patterns = ['_old_', '_backup', '_test']
    all_files = [f for f in all_files if not any(p in f for p in exclude_patterns)]
    
    # Parse args
    if len(sys.argv) < 2:
        print("Usage: python3 sadie_dedupe.py <file.csv> [--all] [--apply]")
        print("       --all    Process all canonical lead files")
        print("       --apply  Actually remove duplicates (without this, only reports)")
        sys.exit(1)
    
    apply_changes = '--apply' in sys.argv
    
    if '--all' in sys.argv:
        files = all_files
    else:
        files = [f for f in sys.argv[1:] if f.endswith('.csv')]
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Duplicate Detection (key: name + domain)")
    if apply_changes:
        print("  🔧 APPLY MODE - Duplicates will be removed!")
    else:
        print("  ⚠️  REPORT ONLY - No files will be modified (use --apply to remove)")
    print()
    
    total_duplicates = 0
    total_removed = 0
    
    for filepath in files:
        if not os.path.exists(filepath):
            continue
        
        duplicates, removed = find_duplicates(filepath, apply=apply_changes)
        
        if duplicates:
            fname = os.path.basename(filepath)
            print(f"{'=' * 60}")
            if apply_changes:
                print(f"📁 {fname} - Removed {removed} duplicates")
            else:
                print(f"📁 {fname} - Found {len(duplicates)} potential duplicates")
            print(f"{'=' * 60}")
            
            for i, dup in enumerate(duplicates):
                print(f"\n  Duplicate #{i+1}:")
                print(f"    Key: {dup['key'][:60]}")
                print(f"    ✓ KEPT:      {dup['kept']['name'][:45]}")
                print(f"                 {dup['kept']['website'][:50]}")
                print(f"                 booking: {dup['kept']['booking_url'] or '(none)'}")
                print(f"    ✗ {'REMOVED' if apply_changes else 'DUPLICATE'}: {dup['duplicate']['name'][:45]}")
                print(f"                 {dup['duplicate']['website'][:50]}")
                print(f"                 booking: {dup['duplicate']['booking_url'] or '(none)'}")
            
            total_duplicates += len(duplicates)
            total_removed += removed
            print()
    
    print(f"{'=' * 60}")
    if apply_changes:
        print(f"✅ Removed {total_removed} duplicates from {len(files)} files")
    else:
        print(f"Total potential duplicates found: {total_duplicates}")
        if total_duplicates > 0:
            print(f"\nTo remove these duplicates, run:")
            print(f"  python3 sadie_dedupe.py --all --apply")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()

