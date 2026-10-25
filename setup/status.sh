#!/usr/bin/env bash
# Show which Craft CLIs are installed, their version, and the latest release.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRAFT_HOME="${CRAFT_HOME:-$REPO_ROOT/.craft}"
org_of() { case "$1" in solidcraft) echo tangency-labs ;; *) echo "${CRAFT_ORG:-storytold}" ;; esac; }
printf '%-12s %-10s %-10s %s\n' APP INSTALLED LATEST NOTE
for app in photocraft effectcraft filmcraft vectorcraft lightcraft pdfcraft designcraft soundcraft solidcraft; do
  have="$(cat "$CRAFT_HOME/versions/$app" 2>/dev/null || echo -)"
  [ -x "$CRAFT_HOME/bin/$app-cli" ] || have=-
  latest="$(git ls-remote --tags --refs "https://github.com/$(org_of "$app")/$app" 2>/dev/null | awk -F/ '{print $3}' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)"
  note=""
  [ "$have" = - ] && note="not installed"
  [ "$have" != - ] && [ -n "$latest" ] && [ "$have" != "$latest" ] && note="update available"
  printf '%-12s %-10s %-10s %s\n' "$app" "$have" "${latest:-?}" "$note"
done
