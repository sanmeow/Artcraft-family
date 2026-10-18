#!/usr/bin/env bash
# Batch-convert a folder of images (PSD, PNG, JPG, WebP, TIFF…) to a paper size with photocraft-cli.
#
#   scripts/to-a4.sh <in-dir> <out-dir> [options]
#
# Options:
#   --paper  A4|A3|A5|B5|LETTER|LEGAL|<W>x<H>mm   paper size            (default A4)
#   --dpi    N                                     print resolution      (default 300)
#   --orient portrait|landscape|auto               auto = follow each image's shape (default portrait)
#   --mode   fit|fill                              fit = whole image, pad the rest;
#                                                  fill = cover the page, crop the overflow (default fit)
#   --bg     white|black|transparent|#rrggbb       padding colour for fit (default white)
#   --no-enlarge                                   never upscale small images (fit only)
#   --format jpg|png|tif|pdf|psd|…                 output format (default: same as the input)
#   --quality N                                    JPEG/WebP quality (default 92)
#
# Output files keep their names (extension changes with --format). The input folder is never modified.
set -euo pipefail

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
[ $# -ge 2 ] || usage 2
IN="$1"; OUT="$2"; shift 2
PAPER=A4 DPI=300 ORIENT=portrait MODE=fit BG=white ENLARGE=1 FORMAT="" QUALITY=92
while [ $# -gt 0 ]; do
  case "$1" in
    --paper) PAPER="$2"; shift 2 ;;
    --dpi) DPI="$2"; shift 2 ;;
    --orient) ORIENT="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --bg) BG="$2"; shift 2 ;;
    --no-enlarge) ENLARGE=0; shift ;;
    --format) FORMAT="${2#.}"; shift 2 ;;
    --quality) QUALITY="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option $1" >&2; usage 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/setup/env.sh"
command -v photocraft-cli >/dev/null || { echo "photocraft-cli missing: run ./setup/install.sh" >&2; exit 1; }
[ -d "$IN" ] || { echo "no such folder: $IN" >&2; exit 1; }
[ "$(cd "$IN" && pwd)" != "$(mkdir -p "$OUT" && cd "$OUT" && pwd)" ] || { echo "out-dir must differ from in-dir" >&2; exit 1; }

# Paper size in mm (portrait).
case "${PAPER^^}" in
  A3) MM="297x420" ;; A4) MM="210x297" ;; A5) MM="148x210" ;; B5) MM="176x250" ;;
  LETTER) MM="215.9x279.4" ;; LEGAL) MM="215.9x355.6" ;;
  *MM) MM="${PAPER%[mM][mM]}" ;;
  *) echo "unknown paper $PAPER" >&2; exit 2 ;;
esac
read -r PW PH < <(python3 -c "w,h=map(float,'$MM'.split('x'));d=$DPI/25.4;print(round(w*d),round(h*d))")
echo "paper $PAPER = ${PW}x${PH}px @ ${DPI}dpi, mode=$MODE, orient=$ORIENT" >&2

ok=0; fail=0; failed=()
shopt -s nullglob nocaseglob
for f in "$IN"/*.{psd,psb,png,jpg,jpeg,webp,tif,tiff,bmp,gif,tga,heic,pcraft,ora,kra}; do
  name="$(basename "$f")"; stem="${name%.*}"; ext="${FORMAT:-${name##*.}}"
  out="$OUT/$stem.$ext"
  size="$(photocraft-cli info "$f" --compact 2>/dev/null | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d["width"],d["height"])')" \
    || { echo "FAIL  $name (cannot open)" >&2; fail=$((fail+1)); failed+=("$name"); continue; }
  read -r w h <<<"$size"
  tw=$PW th=$PH
  if [ "$ORIENT" = landscape ] || { [ "$ORIENT" = auto ] && [ "$w" -gt "$h" ]; }; then tw=$PH th=$PW; fi

  args=()
  if [ "$MODE" = fill ]; then
    read -r sw sh < <(python3 -c "import math;s=max($tw/$w,$th/$h);print(max($tw,math.ceil($w*s)),max($th,math.ceil($h*s)))")
    args+=(--cmd image.imageSize --params "{\"width\":$sw,\"height\":$sh,\"resample\":\"bicubic\"}")
    args+=(--cmd image.canvasSize --params "{\"width\":$tw,\"height\":$th,\"anchor\":\"center\"}")
  else
    dont=false; [ $ENLARGE = 0 ] && dont=true
    args+=(--cmd file.automate.fitImage --params "{\"width\":$tw,\"height\":$th,\"dontEnlarge\":$dont,\"resample\":\"bicubic\"}")
    args+=(--cmd image.canvasSize --params "{\"width\":$tw,\"height\":$th,\"anchor\":\"center\",\"extensionColor\":\"$BG\"}")
  fi
  args+=(--cmd image.imageSize --params "{\"resolution\":$DPI,\"resample\":\"none\"}")
  # Flat formats need one layer; keep layers when writing PSD/PSB/TIFF/pcraft.
  case "${ext,,}" in psd|psb|pcraft|tif|tiff) ;; *) args+=(--cmd layer.flattenImage) ;; esac

  if log="$(photocraft-cli run "$f" "${args[@]}" --out "$out" --quality "$QUALITY" 2>&1 >/dev/null)"; then
    echo "ok    $name -> $(basename "$out") (${w}x${h} -> ${tw}x${th})" >&2; ok=$((ok+1))
    grep -iv -e 'lossy compression' -e '^[[:space:]]*$' <<<"$log" | sed 's/^/      /' >&2 || true
  else
    echo "FAIL  $name: $log" >&2; fail=$((fail+1)); failed+=("$name")
  fi
done
echo "$ok succeeded, $fail failed${failed:+: ${failed[*]}}" >&2
[ $fail = 0 ]
