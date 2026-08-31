#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Runs every nmap command the README documents against the local servers, so
# that a command which stops working is caught even if no dedicated test
# covers it. Commands aimed at scanme.nmap.org are skipped because the CI
# container has no route to the internet during the scan steps.
commands=$(python3 - <<'PY'
import re
inside = False
for line in open("README.md"):
    if line.startswith("```bash"):
        inside = True
        continue
    if line.startswith("```"):
        inside = False
        continue
    if inside and line.startswith("nmap ") and "scanme.nmap.org" not in line:
        print(line.rstrip().rstrip("\\"), end=" " if line.rstrip().endswith("\\") else "\n")
PY
)

failed=0
: > /tmp/readme-results.txt
while IFS= read -r command; do
  [ -z "$command" ] && continue
  echo "== $command"
  if ! output=$(eval "timeout 120 $command" 2>&1); then
    echo "$output"
    echo "FAILED: $command" | tee -a /tmp/readme-results.txt
    failed=1
    continue
  fi
  if ! grep -q "Nmap done" <<< "$output"; then
    echo "$output"
    echo "NO RESULT: $command" | tee -a /tmp/readme-results.txt
    failed=1
    continue
  fi
  # A scan of a closed port still finishes cleanly, so a command that names a
  # script must also produce script output.
  if grep -q -- "--script" <<< "$command" && ! grep -qE "^\|" <<< "$output"; then
    echo "$output"
    echo "NO SCRIPT OUTPUT: $command" | tee -a /tmp/readme-results.txt
    failed=1
  fi
done <<< "$commands"

if [ "$failed" -ne 0 ]; then
  echo "--- commands that did not produce a result ---"
  cat /tmp/readme-results.txt || true
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
      echo "### README commands without a result"
      echo '```'
      cat /tmp/readme-results.txt
      echo '```'
    } >> "$GITHUB_STEP_SUMMARY"
  fi
fi
exit "$failed"
