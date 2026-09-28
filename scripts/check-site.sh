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
need images/portrait.svg
has index.html 'class="?portrait"? [^>]*src="?/images/portrait.svg'
has index.html 'class="?cover"?[^>]*src="?/posts/hello-world/publish-flow.svg'
has talks/index.html 'class="?cover"?[^>]*src="?/covers/supercon-2024-cats-turned-plumbers.svg'
has index.html 'href="?/fonts/JetBrainsMono.woff2'
has posts/hello-world/index.html 'chroma-dark[^>]*media="?not all and \(prefers-color-scheme: ?light\)'
has posts/hello-world/index.html 'chroma-light[^>]*media="?\(prefers-color-scheme: ?light\)'
has talks/index.html 'class="?year"?>2024'
has talks/index.html 'href="?https://ekoparty.org/trainings2024-bombercat'
has talks/index.html 'blackhat|Black Hat'
has oss/index.html 'href="?https://github.com/adafruit/TinyLoRa/pull/15'
has index.xml 'https://wero1414.github.io/posts/hello-world/'
lacks index.xml '<link/>|<guid/>|0001'
lacks index.xml 'projects/this-site|/about/'
absent projects/index.xml

for f in $(find public -name '*.html' -o -name '*.css'); do
  lacks "${f#public/}" '&[lrmn](squo|dquo|dash);|&hellip;'
  lacks "${f#public/}" 'fonts\.googleapis\.com|fonts\.gstatic\.com'
  lacks "${f#public/}" '<img[^>]*src="?https?://'
  lacks "${f#public/}" "$(printf '\xe2\x80[\x93\x94\x98\x99\x9c\x9d\xa6]')"
done

# 3. Content rules: medium confidence must be draft; no author to-do notes on public cards.
for f in $(find content -name '*.md'); do
  if grep -q "^confidence: 'medium'" "$f" && ! grep -q '^draft: true' "$f"; then
    echo "FAIL $f has confidence medium but is not draft: true"; fail=1
  fi
  if grep -Eiq '^description:.*(to confirm|update after|placeholder|TODO)' "$f"; then
    echo "FAIL $f description carries an author note; move it to a YAML comment"; fail=1
  fi
done

# 4. Light-mode accent colours must reach WCAG AA (4.5:1) on the page background.
python3 - assets/css/main.css <<'PY' || fail=1
import re, sys
css = open(sys.argv[1]).read()
light = re.search(r'prefers-color-scheme: light\) \{(.*?)\n\}', css, re.S).group(1)
tok = dict(re.findall(r'--([a-z]+): (#[0-9a-fA-F]{6})', light))
def lum(h):
    c = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def ratio(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
ok = True
for name in ('talks', 'oss', 'projects', 'posts', 'muted', 'warn'):
    r = ratio(tok[name], tok['bg'])
    if r < 4.5:
        print(f"FAIL light --{name} {tok[name]} on --bg {tok['bg']} is {r:.2f}:1, need 4.5:1"); ok = False
sys.exit(0 if ok else 1)
PY

# 5. Local Hugo must match the version pinned in the deploy workflow.
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
