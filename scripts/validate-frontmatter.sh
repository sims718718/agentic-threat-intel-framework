#!/usr/bin/env bash
# Validates that a Markdown file's YAML frontmatter contains the given
# fields, non-empty. Usage: validate-frontmatter.sh <file> <field1> [field2 ...]
set -euo pipefail

FILE="$1"
shift

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist"
  exit 1
fi

STATUS=0
for FIELD in "$@"; do
  VALUE=$(sed -n "s/^${FIELD}: *//p" "$FILE" | head -1)
  if [ -z "$VALUE" ]; then
    echo "FAIL: $FILE missing '${FIELD}:' in frontmatter"
    STATUS=1
  else
    echo "OK: ${FIELD}=${VALUE}"
  fi
done
exit $STATUS
