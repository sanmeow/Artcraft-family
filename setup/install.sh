#!/usr/bin/env bash
# Install (or update) the command-line tools of the ArtCraft "Crafting Apps".
#
#   ./setup/install.sh                     # PhotoCraft only (the default)
#   ./setup/install.sh photocraft pdfcraft # several apps
#   ./setup/install.sh all                 # every app
#   ./setup/install.sh --update all        # re-install when a newer release exists
#   ./setup/install.sh --method source photocraft
#
# Methods (--method, default auto):
#   release  download the latest GitHub release tarball and check it against SHA256SUMS.txt
#   source   git clone the latest release tag and build <app>-cli with cargo
#   auto     try release, fall back to source
#
# Everything goes under $CRAFT_HOME (default: <repo>/.craft):
#   .craft/bin/<app>-cli      the tools (put this on PATH: `source setup/env.sh`)
#   .craft/versions/<app>     the installed version tag
#   .craft/src/<app>          source checkouts (source method only)
set -euo pipefail

ALL_APPS=(photocraft effectcraft filmcraft vectorcraft lightcraft pdfcraft designcraft)
ORG="${CRAFT_ORG:-storytold}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRAFT_HOME="${CRAFT_HOME:-$REPO_ROOT/.craft}"
METHOD=auto
UPDATE=0
APPS=()

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '\033[1;34m[craft]\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m[craft]\033[0m %s\n' "$*" >&2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --method) METHOD="$2"; shift 2 ;;
    --method=*) METHOD="${1#*=}"; shift ;;
    --update) UPDATE=1; shift ;;
    -h|--help) usage 0 ;;
    all) APPS=("${ALL_APPS[@]}"); shift ;;
    -*) warn "unknown option $1"; usage 2 ;;
    *) APPS+=("$1"); shift ;;
  esac
done
[ ${#APPS[@]} -eq 0 ] && APPS=(photocraft)
case "$METHOD" in auto|release|source) ;; *) warn "bad --method $METHOD"; exit 2 ;; esac

mkdir -p "$CRAFT_HOME/bin" "$CRAFT_HOME/versions" "$CRAFT_HOME/src" "$CRAFT_HOME/downloads"

case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64 ;;
  aarch64|arm64) ARCH=aarch64 ;;
  riscv64) ARCH=riscv64 ;;
  *) ARCH="$(uname -m)" ;;
esac

# Latest release tag, read with git so it works where the GitHub API is blocked.
latest_tag() {
  git ls-remote --tags --refs "https://github.com/$ORG/$1" 2>/dev/null \
    | awk -F/ '{print $3}' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1
}

install_release() {
  local app="$1" tag="$2" ver="${2#v}"
  local base="$app-$ver-linux-$ARCH" url="https://github.com/$ORG/$app/releases/download/$tag"
  local dl="$CRAFT_HOME/downloads/$app-$ver"
  rm -rf "$dl"; mkdir -p "$dl"
  log "$app: downloading $base.tar.gz"
  curl -fsSL --retry 3 -o "$dl/$base.tar.gz" "$url/$base.tar.gz" || return 1
  if curl -fsSL --retry 3 -o "$dl/SHA256SUMS.txt" "$url/SHA256SUMS.txt"; then
    (cd "$dl" && grep " \*\?$base.tar.gz\$" SHA256SUMS.txt | sha256sum -c -) >&2 \
      || { warn "$app: checksum mismatch"; return 1; }
  else
    warn "$app: no SHA256SUMS.txt, checksum not verified"
  fi
  tar -xzf "$dl/$base.tar.gz" -C "$dl"
  local bin; bin="$(find "$dl" -type f -name "$app-cli" -perm -u+x | head -1)"
  [ -n "$bin" ] || { warn "$app: $app-cli not found in the tarball"; return 1; }
  install -m755 "$bin" "$CRAFT_HOME/bin/$app-cli"
  rm -rf "$dl"
}

install_source() {
  local app="$1" tag="$2" src="$CRAFT_HOME/src/$app"
  command -v cargo >/dev/null || { warn "cargo not found: install Rust from https://rustup.rs"; return 1; }
  rm -rf "$src"
  log "$app: cloning $tag"
  GIT_LFS_SKIP_SMUDGE=1 git clone -q --depth 1 --branch "$tag" "https://github.com/$ORG/$app" "$src"
  log "$app: building $app-cli (cargo build --release, this takes several minutes)"
  (cd "$src" && cargo build --release --locked -p "$app-cli") >&2 \
    || (cd "$src" && cargo build --release -p "$app-cli") >&2
  install -m755 "${CARGO_TARGET_DIR:-$src/target}/release/$app-cli" "$CRAFT_HOME/bin/$app-cli"
  # Keep the source (docs, examples) but drop the multi-GB build cache.
  [ "${CRAFT_KEEP_TARGET:-0}" = 1 ] || rm -rf "$src/target"
}

failed=()
for app in "${APPS[@]}"; do
  if [[ ! " ${ALL_APPS[*]} " == *" $app "* ]]; then warn "unknown app $app (known: ${ALL_APPS[*]})"; failed+=("$app"); continue; fi
  tag="$(latest_tag "$app")"
  [ -n "$tag" ] || { warn "$app: could not read release tags"; failed+=("$app"); continue; }
  have="$(cat "$CRAFT_HOME/versions/$app" 2>/dev/null || true)"
  if [ -x "$CRAFT_HOME/bin/$app-cli" ] && { [ "$have" = "$tag" ] || [ $UPDATE = 0 ]; }; then
    log "$app: $have already installed$([ "$have" != "$tag" ] && echo " (latest is $tag; use --update)")"
    continue
  fi
  ok=0
  if [ "$METHOD" != source ]; then install_release "$app" "$tag" && ok=1 || warn "$app: release download failed"; fi
  if [ $ok = 0 ] && [ "$METHOD" != release ]; then install_source "$app" "$tag" && ok=1 || warn "$app: source build failed"; fi
  if [ $ok = 1 ]; then
    echo "$tag" > "$CRAFT_HOME/versions/$app"
    log "$app: installed $tag -> $CRAFT_HOME/bin/$app-cli ($("$CRAFT_HOME/bin/$app-cli" --version 2>/dev/null | head -1))"
  else
    failed+=("$app")
  fi
done

log "add the tools to PATH with: source setup/env.sh"
[ ${#failed[@]} -eq 0 ] || { warn "failed: ${failed[*]}"; exit 1; }
