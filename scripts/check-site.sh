#!/usr/bin/env bash
# Build the site and check the generated output. Exit 0 only if every check passes.
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.."

fail=0
need()   { [ -f "public/$1" ] || { echo "FAIL missing: public/$1"; fail=1; }; }
absent() { [ ! -e "public/$1" ] || { echo "FAIL should not exist: public/$1"; fail=1; }; }
has()    { grep -Eq -- "$2" "public/$1" || { echo "FAIL public/$1 lacks: $2"; fail=1; }; }
lacks()  { ! grep -Eq -- "$2" "public/$1" || { echo "FAIL public/$1 contains: $2"; fail=1; }; }

build() { rm -rf public && hugo --gc --minify --panicOnWarning >/dev/null; }

# Temporary fixtures, always removed.
draft=content/posts/zz-check-draft.md
future=content/posts/zz-check-future.md
broken=content/projects/zz-check-broken.md
trap 'rm -f "$draft" "$future" "$broken"' EXIT

# 1. A project with no local page and no external_url must fail the build.
printf -- "---\ntitle: 'zz broken'\ndate: '2020-01-01'\nbuild:\n  render: never\n---\n" > "$broken"
if out=$(build 2>&1); then
  echo "FAIL build passed with a project that has nothing to link to"; fail=1
elif ! grep -q 'has no page to link to' <<<"$out"; then
  echo "FAIL build failed without the expected message; output was:"; echo "$out"; fail=1
fi
rm -f "$broken"

# 2. Normal build, with a draft and a future-dated post that must not be published.
printf -- "---\ntitle: 'zz draft'\ndate: '2020-01-01'\ndraft: true\n---\nx\n" > "$draft"
printf -- "---\ntitle: 'zz future'\ndate: '2999-01-01'\n---\nx\n" > "$future"
build

need index.html
need index.xml
need posts/index.html
need posts/index.xml
need posts/hello-world/index.html
need posts/hello-world/publish-flow.svg
need projects/index.html
need talks/index.html
need oss/index.html
need fonts/Inter.woff2
need fonts/JetBrainsMono.woff2
need projects/this-site/index.html
need about/index.html
need tags/index.html
need tags/meta/index.html

absent projects/ear-training/index.html
absent talks/index.xml
absent oss/index.xml
absent talks/blackhat-2025-arsenal-catsniffer/index.html
absent posts/zz-check-draft/index.html
absent posts/zz-check-future/index.html
lacks index.xml 'zz (draft|future)'

has index.html '<html lang="?en'
has index.html 'name="?viewport'
has index.html 'href="?/posts/hello-world/'
has index.html 'href="?https://github.com/wero1414/ear-training'
has projects/index.html 'href="?https://github.com/wero1414/ear-training'
has projects/index.html 'href="?/projects/this-site/'
has posts/hello-world/index.html 'src="?publish-flow.svg'
has index.html 'data-section="?talks'
has index.html 'data-section="?oss'
has index.html 'data-section="?projects'
has index.html 'data-section="?posts'
has index.html 'href="?/fonts/JetBrainsMono.woff2'
has talks/index.html 'class="?year"?>2024'
has talks/index.html 'href="?https://ekoparty.org/trainings2024-bombercat'
lacks talks/index.html 'blackhat|biobiochile'
has oss/index.html 'href="?https://github.com/adafruit/TinyLoRa/pull/15'
has index.xml 'https://wero1414.github.io/posts/hello-world/'
lacks index.xml '<link/>|<guid/>|0001'
lacks index.xml 'projects/this-site|/about/'
absent projects/index.xml

for f in $(find public -name '*.html' -o -name '*.css'); do
  lacks "${f#public/}" '&[lrmn](squo|dquo|dash);|&hellip;'
  lacks "${f#public/}" 'fonts\.googleapis\.com|fonts\.gstatic\.com'
  lacks "${f#public/}" "$(printf '\xe2\x80[\x93\x94\x98\x99\x9c\x9d\xa6]')"
done

# 3. Local Hugo must match the version pinned in the deploy workflow.
wf=.github/workflows/hugo.yml
if [ -f "$wf" ]; then
  pinned=$(sed -n 's/^ *HUGO_VERSION: *//p' "$wf")
  local_v=$(hugo version | sed -E 's/^hugo v([0-9.]+).*/\1/')
  [ "$pinned" = "$local_v" ] || { echo "FAIL Hugo $local_v locally but $pinned in $wf"; fail=1; }
else
  echo "FAIL missing $wf"; fail=1
fi

if [ "$fail" -ne 0 ]; then echo "check-site: FAILED"; exit 1; fi
echo "check-site: OK"
