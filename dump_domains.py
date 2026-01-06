#!/usr/bin/env python3
"""Dump all domains found on a webpage."""
import re
import sys
import requests

url = sys.argv[1] if len(sys.argv) > 1 else None
if not url:
    print("Usage: python3 dump_domains.py <url>")
    sys.exit(1)

if not url.startswith("http"):
    url = "https://" + url

print(f"Fetching: {url}\n")
html = requests.get(url, timeout=15, headers={"User-Agent": "Mozilla/5.0"}).text

# Extract all domains
domains = set(re.findall(r'https?://([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})', html))

print(f"=== DOMAINS FOUND ({len(domains)}) ===\n")
for d in sorted(domains):
    print(d)

