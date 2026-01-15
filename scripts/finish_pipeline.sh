#!/bin/bash
# Finish Pipeline: Launch ready hotels and export to S3
#
# Usage:
#   ./scripts/finish_pipeline.sh                     # Export all states
#   ./scripts/finish_pipeline.sh "Florida" "USA"    # Export specific state

set -e

cd "$(dirname "$0")/.."

echo "=== STATUS ==="
uv run python workflows/launcher.py status

echo ""
echo "=== LAUNCHING ==="
uv run python workflows/launcher.py launch-all

echo ""
echo "=== EXPORTING ==="

if [ $# -ge 2 ]; then
    STATE="$1"
    COUNTRY="$2"
    echo "Exporting $STATE, $COUNTRY..."
    uv run python workflows/export.py --state "$STATE" --country "$COUNTRY"
else
    echo "Exporting all states..."
    uv run python workflows/export.py --all-states
fi

echo ""
echo "=== DONE ==="
echo "Leads exported to S3."
