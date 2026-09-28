#!/usr/bin/env bash
# Generate an SVG cover for every talk that has no cover image yet.
# Output: static/covers/<slug>.svg. Existing files are left alone, so a
# hand-made cover (any name matching the slug, e.g. a .jpg set via `cover:`)
# is never overwritten. Re-run after adding talks.
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.."
mkdir -p static/covers
for f in content/talks/*.md; do
  slug=$(basename "$f" .md)
  [ "$slug" = "_index" ] && continue
  out="static/covers/$slug.svg"
  [ -e "$out" ] && continue
  event=$(sed -n "s/^event: '\(.*\)'$/\1/p" "$f" | head -1)
  year=$(sed -n "s/^date: '\([0-9]\{4\}\).*'$/\1/p" "$f" | head -1)
  role=$(sed -n "s/^role: '\(.*\)'.*$/\1/p" "$f" | head -1)
  # A different bar pattern per talk, derived from the slug, so covers differ.
  seed=$(printf '%s' "$slug" | cksum | cut -d' ' -f1)
  bars=""
  for i in $(seq 0 23); do
    h=$(( (seed / (i + 1) + i * 37) % 70 + 10 ))
    x=$(( 24 + i * 25 ))
    bars="$bars<rect x=\"$x\" y=\"$((300 - h))\" width=\"14\" height=\"$h\" rx=\"2\"/>"
  done
  esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
  cat > "$out" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 360" width="640" height="360" role="img" aria-label="$(esc "$event")">
  <rect width="640" height="360" fill="#181a22"/>
  <g fill="#29d3ff" opacity="0.35">$bars</g>
  <text x="32" y="80" font-family="'JetBrains Mono', ui-monospace, Menlo, monospace" font-size="18" fill="#9aa0b5">// $year - $(esc "$role")</text>
  <text x="32" y="130" font-family="'JetBrains Mono', ui-monospace, Menlo, monospace" font-size="34" font-weight="700" fill="#e8e8ee">$(esc "$event")</text>
</svg>
SVG
  echo "wrote $out"
done
