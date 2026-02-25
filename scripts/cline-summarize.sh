#!/usr/bin/env bash
# =============================================================================
# cline-summarize.sh — Aggregate multi-agent results into executive summary
#
# Reads all report.md files from a results directory and generates
# a unified executive summary using Cline CLI.
#
# Usage: bash cline-summarize.sh <results-dir> [output-file]
#
# Example:
#   bash cline-summarize.sh ~/upbro/security-audit/ ~/upbro/security-audit/summary/executive-summary.md
# =============================================================================

set -euo pipefail

RESULTS_DIR="${1:-}"
OUTPUT="${2:-${RESULTS_DIR}/executive-summary.md}"

if [[ -z "$RESULTS_DIR" || ! -d "$RESULTS_DIR" ]]; then
  echo "Usage: $0 <results-dir> [output-file]"
  echo "  Aggregates all *.md files in results-dir into an executive summary."
  exit 1
fi

# Collect all report files
REPORTS=""
COUNT=0
for f in "$RESULTS_DIR"/*/*.md "$RESULTS_DIR"/*.md; do
  [[ -f "$f" && -s "$f" ]] || continue
  # Skip the output file itself
  [[ "$(realpath "$f")" == "$(realpath "$OUTPUT" 2>/dev/null)" ]] && continue
  REPORTS+="--- $(basename "$(dirname "$f")")/$(basename "$f") ---"$'\n'
  REPORTS+="$(head -100 "$f")"$'\n\n'
  COUNT=$((COUNT + 1))
done

if [[ $COUNT -eq 0 ]]; then
  echo "No report files found in $RESULTS_DIR"
  exit 1
fi

echo "Found $COUNT report(s). Generating executive summary..."

mkdir -p "$(dirname "$OUTPUT")"

# Use Cline to synthesize
echo "$REPORTS" | cline -y \
  "You are given $COUNT agent reports. Create an executive summary in Markdown with:
1. Overall risk assessment (emoji severity)
2. Total findings count by severity (table)
3. Top 5 most critical findings with file paths
4. Positive findings / what's done well
5. Remediation priority (immediate/short-term/medium-term)
6. One-paragraph conclusion

Write the summary to $OUTPUT" \
  --timeout 300

if [[ -f "$OUTPUT" && -s "$OUTPUT" ]]; then
  echo "✅ Executive summary: $OUTPUT ($(wc -l < "$OUTPUT") lines)"
else
  echo "⚠️  Summary generation may have failed. Check $OUTPUT"
fi
