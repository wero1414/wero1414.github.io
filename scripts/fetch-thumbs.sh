#!/usr/bin/env bash
# Download the YouTube thumbnail for every talk with a `video:` YouTube link
# and set it as the card cover (static/covers/<slug>.jpg). Runs once per talk;
# existing .jpg covers are kept. Re-run after adding a talk with a video.
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.."
mkdir -p static/covers
for f in content/talks/*.md; do
  slug=$(basename "$f" .md)
  id=$(sed -n "s|^video: 'https://www.youtube.com/watch?v=\([A-Za-z0-9_-]*\).*|\1|p" "$f" | head -1)
  [ -z "$id" ] && continue
  out="static/covers/$slug.jpg"
  if [ ! -e "$out" ]; then
    # maxresdefault is not always present; fall back to hqdefault (480x360).
    curl -sfL "https://img.youtube.com/vi/$id/maxresdefault.jpg" -o "$out" \
      || curl -sfL "https://img.youtube.com/vi/$id/hqdefault.jpg" -o "$out"
    echo "wrote $out"
  fi
  grep -q "^cover:" "$f" || sed -i '' "s|^video: |cover: '/covers/$slug.jpg'\\
video: |" "$f"
  rm -f "static/covers/$slug.svg"
done
