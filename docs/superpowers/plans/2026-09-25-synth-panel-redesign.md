# Synth Panel Redesign and Public-Work Content Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the plain theme with the "synth panel" look, add Talks and Open source sections, and import the researched public work (talks, PRs, projects) so the user can prune it on a local preview and then publish.

**Architecture:** Same Hugo 0.166.0 site and CI. New templates: hero with inline SVG waveform, colour-coded `section-panel` on the home page, `card` partial shared by every list, `talks/section.html` grouped by year. Section accent colours are CSS custom properties switched by `data-section`. Fonts are self-hosted variable woff2 files in `static/fonts/`. `scripts/check-site.sh` gains assertions for the new sections, local fonts, draft exclusion of medium-confidence items, and literal curly punctuation.

**Tech Stack:** Hugo 0.166.0, CSS (no JS), JetBrains Mono + Inter (OFL, downloaded from Google Fonts CSS API on 2026-09-25), bash, GitHub Actions (unchanged).

**Spec:** `docs/superpowers/specs/2026-09-25-redesign-and-content-design.md`

Every file listing below was built in a throwaway prototype on Hugo 0.166.0 on 2026-09-25: `./scripts/check-site.sh` printed `check-site: OK`, and the control tests in Task 1 Step 7 failed as expected.

## Global Constraints

- Repo `/Users/wero1414/dasiswero`, branch `main`, remote `origin` = `wero1414/wero1414.github.io`. Do not push until Task 3 Step 3 with explicit user approval.
- Hugo 0.166.0 locally and in CI (the check script enforces it).
- Plain ASCII in every file, generated page and commit message. No emojis, no em/en dashes, no smart quotes. Typographer stays disabled.
- No AI attribution in commits.
- No JavaScript in the theme. No third-party requests at runtime (fonts are local).
- Never skip or weaken a check to make it pass.
- Medium-confidence items are `draft: true` and must never deploy until the user flips them.
- Every imported item carries `source:` with the URL the fact came from.

## Review Focus

- A card whose page has neither a local page nor `external_url` must fail the build with a clear message (existing errorf guard, now in `item-link.html`; pinned by the broken-project fixture).
- Medium-confidence talks (`draft: true`) must not appear in `talks/index.html` or anywhere in `public/`; pinned by `absent talks/blackhat-2025-arsenal-catsniffer/index.html` and `lacks talks/index.html 'blackhat|biobiochile'`.
- Fonts must load from `/fonts/` only; a Google Fonts URL anywhere in generated HTML/CSS fails the check; pinned by the `fonts.googleapis|fonts.gstatic` scan and `need fonts/*.woff2`.
- Pasted text with literal curly quotes or em dashes (UTF-8 bytes) must fail the check, not just HTML entities; pinned by the `LC_ALL=C` byte-class scan (control-tested).
- Talks page must group by year and list newest first; pinned by `has talks/index.html 'class="?year"?>2024'` and the Ekoparty 2024 link.

---

### Task 1: Theme, fonts, config and check-script additions

**Files:**
- Create: `static/fonts/Inter.woff2`, `static/fonts/JetBrainsMono.woff2` (downloaded)
- Create: `archetypes/talks.md`, `archetypes/oss.md`
- Create: `layouts/_partials/hero.html`, `layouts/_partials/waveform.html`, `layouts/_partials/knobs.html`, `layouts/_partials/badges.html`, `layouts/_partials/item-link.html`, `layouts/_partials/card.html`, `layouts/_partials/section-panel.html`, `layouts/talks/section.html`
- Modify: `hugo.toml`, `i18n/en.toml`, `layouts/baseof.html`, `layouts/_partials/head.html`, `layouts/_partials/header.html`, `layouts/_partials/footer.html`, `layouts/home.html`, `layouts/section.html`, `layouts/term.html`, `layouts/taxonomy.html`, `layouts/page.html`, `assets/css/main.css`, `scripts/check-site.sh`
- Delete: `layouts/_partials/post-item.html`, `layouts/_partials/project-item.html`, `layouts/projects/section.html`
- Create (minimal, so Task 1 builds on its own): `content/talks/_index.md`, `content/oss/_index.md`; Modify: `content/projects/_index.md`

**Interfaces:**
- Consumes: existing site from the first plan.
- Produces: `partial "card.html"` (takes a page; renders `<li class="card" data-section=...>`), `partial "item-link.html"` (returns the URL or errors), `site.Params.sections` (ordered list of `{name,title}`), front matter contract for talks/oss/projects as in the spec. Check script assertions that Task 2 must satisfy (they reference specific content files; until Task 2 they are expected to fail, see Step 6).

- [ ] **Step 1: Extend the check script (the test)**

Apply this diff to `scripts/check-site.sh` (context lines are from the current file):

```diff
--- scripts/check-site.sh	2026-09-25 01:00:07
+++ /private/tmp/claude-501/-Users-wero1414-dasiswero/1f357566-2c94-4a15-9a67-db6cf6d8fd6c/scratchpad/proto2/scripts/check-site.sh	2026-09-25 01:37:52
@@ -1,6 +1,7 @@
 #!/usr/bin/env bash
 # Build the site and check the generated output. Exit 0 only if every check passes.
 set -euo pipefail
+export LC_ALL=C
 cd "$(dirname "$0")/.."
 
 fail=0
@@ -38,12 +39,19 @@
 need posts/hello-world/index.html
 need posts/hello-world/publish-flow.svg
 need projects/index.html
+need talks/index.html
+need oss/index.html
+need fonts/Inter.woff2
+need fonts/JetBrainsMono.woff2
 need projects/this-site/index.html
 need about/index.html
 need tags/index.html
 need tags/meta/index.html
 
 absent projects/ear-training/index.html
+absent talks/index.xml
+absent oss/index.xml
+absent talks/blackhat-2025-arsenal-catsniffer/index.html
 absent posts/zz-check-draft/index.html
 absent posts/zz-check-future/index.html
 lacks index.xml 'zz (draft|future)'
@@ -55,13 +63,24 @@
 has projects/index.html 'href="?https://github.com/wero1414/ear-training'
 has projects/index.html 'href="?/projects/this-site/'
 has posts/hello-world/index.html 'src="?publish-flow.svg'
+has index.html 'data-section="?talks'
+has index.html 'data-section="?oss'
+has index.html 'data-section="?projects'
+has index.html 'data-section="?posts'
+has index.html 'href="?/fonts/JetBrainsMono.woff2'
+has talks/index.html 'class="?year"?>2024'
+has talks/index.html 'href="?https://ekoparty.org/trainings2024-bombercat'
+lacks talks/index.html 'blackhat|biobiochile'
+has oss/index.html 'href="?https://github.com/adafruit/TinyLoRa/pull/15'
 has index.xml 'https://wero1414.github.io/posts/hello-world/'
 lacks index.xml '<link/>|<guid/>|0001'
 lacks index.xml 'projects/this-site|/about/'
 absent projects/index.xml
 
-for f in $(find public -name '*.html'); do
+for f in $(find public -name '*.html' -o -name '*.css'); do
   lacks "${f#public/}" '&[lrmn](squo|dquo|dash);|&hellip;'
+  lacks "${f#public/}" 'fonts\.googleapis\.com|fonts\.gstatic\.com'
+  lacks "${f#public/}" "$(printf '\xe2\x80[\x93\x94\x98\x99\x9c\x9d\xa6]')"
 done
 
 # 3. Local Hugo must match the version pinned in the deploy workflow.
```

- [ ] **Step 2: Run it and verify it fails**

Run: `./scripts/check-site.sh`
Expected: `FAIL missing: public/talks/index.html`, `FAIL missing: public/oss/index.html`, `FAIL missing: public/fonts/Inter.woff2`, ... then `check-site: FAILED`, exit 1.

- [ ] **Step 3: Download the fonts**

Google serves the same variable-font file for every requested weight, so one file per family is enough. Run from the repo root:

```bash
mkdir -p static/fonts
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
curl -sA "$UA" 'https://fonts.googleapis.com/css2?family=Inter:wght@400;600&family=JetBrains+Mono:wght@400;700&display=swap' -o /tmp/fonts.css
python3 - <<'EOF'
import re, urllib.request
css = open('/tmp/fonts.css').read()
seen = set()
for subset, body in re.findall(r'/\* (\w+) \*/\s*@font-face \{(.*?)\}', css, re.S):
    if subset != 'latin':
        continue
    fam = re.search(r"font-family: '([^']+)'", body).group(1).replace(' ', '')
    if fam in seen:
        continue
    seen.add(fam)
    url = re.search(r'url\((\S+?)\)', body).group(1)
    urllib.request.urlretrieve(url, f'static/fonts/{fam}.woff2')
    print(fam)
EOF
rm /tmp/fonts.css
file static/fonts/*.woff2
```
Expected: two lines `Inter` and `JetBrainsMono`, and `file` reports `Web Open Font Format (Version 2)` for both. Sizes on 2026-09-25 were 48432 and 31340 bytes; different sizes are fine (Google updates fonts), a size under 10 KB is not.

- [ ] **Step 4: Write config, strings, archetypes and section indexes**

`hugo.toml`:

```toml
baseURL = 'https://wero1414.github.io/'
locale = 'en-US'
defaultContentLanguage = 'en'
title = 'wero1414'
enableRobotsTXT = true

[params]
  name = 'Eduardo "wero" Contreras'
  description = 'Eduardo "wero" Contreras: hardware, radios, badges and pedals. Talks, open source and projects outside Electronic Cats.'
  bio = 'Hardware hacker from Aguascalientes, MX. Firmware, RF, badges and the occasional noise box.'
  github = 'https://github.com/wero1414'
  hackster = 'https://www.hackster.io/wero1414'
  electroniccats = 'https://electroniccats.com/'

  # Section order on the home page and in lists. Colours live in main.css.
  [[params.sections]]
    name = 'talks'
    title = 'Talks'
  [[params.sections]]
    name = 'oss'
    title = 'Open source'
  [[params.sections]]
    name = 'projects'
    title = 'Projects'
  [[params.sections]]
    name = 'posts'
    title = 'Posts'

[taxonomies]
  tag = 'tags'

[menus]
  [[menus.main]]
    name = 'Talks'
    pageRef = '/talks'
    weight = 10
  [[menus.main]]
    name = 'Open source'
    pageRef = '/oss'
    weight = 20
  [[menus.main]]
    name = 'Projects'
    pageRef = '/projects'
    weight = 30
  [[menus.main]]
    name = 'Posts'
    pageRef = '/posts'
    weight = 40
  [[menus.main]]
    name = 'About'
    pageRef = '/about'
    weight = 50

[markup.highlight]
  noClasses = false

[markup.goldmark.extensions.typographer]
  disable = true
```

`i18n/en.toml`:

```toml
[all_in]
other = 'all {{ .Count }}'
[external]
other = 'external'
[tags]
other = 'Tags'
[nothing_yet]
other = 'Nothing here yet.'
[with]
other = 'with'
[video]
other = 'video'
[slides]
other = 'slides'
[source]
other = 'source'
[unconfirmed]
other = 'unconfirmed'
```

`archetypes/talks.md`:

```markdown
---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: '{{ .Date }}'
draft: true
description: ''
event: ''
location: ''
role: 'speaker'   # speaker | trainer | host | guest | judge | instructor | press
with: []
lang: 'en'
video: ''
slides: ''
source: ''
confidence: 'high'
# Talks are usually links out. Keep these unless you write a local page:
external_url: ''
build:
  render: never
---
```

`archetypes/oss.md`:

```markdown
---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: '{{ .Date }}'
draft: true
description: ''
repo: 'owner/name'
ref: ''            # e.g. 'PR #125'
status: 'merged'   # merged | open | closed
role: 'author'     # author | co-maintainer | contributor
source: ''
confidence: 'high'
external_url: ''
build:
  render: never
---
```

`content/talks/_index.md`:

```markdown
---
title: 'Talks'
outputs: ['html']
---
Talks, trainings, livestreams and other public appearances. Newest first.
```

`content/oss/_index.md`:

```markdown
---
title: 'Open source'
outputs: ['html']
---
Contributions to other people's projects, and libraries I help maintain.
```

`content/projects/_index.md`:

```markdown
---
title: 'Projects'
outputs: ['html']
---
```

Delete the three superseded templates:

```bash
git rm -q layouts/_partials/post-item.html layouts/_partials/project-item.html layouts/projects/section.html
```

- [ ] **Step 5: Write the templates and stylesheet**

`layouts/baseof.html`:

```go-html-template
<!DOCTYPE html>
<html lang="{{ site.Language.Locale }}">
<head>
  {{ partial "head.html" . }}
</head>
<body>
  <a class="skip" href="#main">Skip to content</a>
  <header class="site-header">
    {{ partial "header.html" . }}
  </header>
  <main id="main">
    {{ block "main" . }}{{ end }}
  </main>
  <footer class="site-footer">
    {{ partial "footer.html" . }}
  </footer>
</body>
</html>
```

`layouts/_partials/head.html`:

```go-html-template
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ if .IsHome }}{{ site.Params.name }} | {{ site.Title }}{{ else }}{{ .Title }} | {{ site.Title }}{{ end }}</title>
<meta name="description" content="{{ or .Description site.Params.description }}">
<meta name="color-scheme" content="dark light">
{{ with .OutputFormats.Get "rss" }}
<link rel="alternate" type="application/rss+xml" href="{{ .RelPermalink }}" title="{{ site.Title }}">
{{ end }}
<link rel="preload" href="/fonts/JetBrainsMono.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/fonts/Inter.woff2" as="font" type="font/woff2" crossorigin>
{{ $css := slice (resources.Get "css/main.css") (resources.Get "css/chroma-dark.css") | resources.Concat "css/site.css" | minify | fingerprint }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">
{{ $light := resources.Get "css/chroma-light.css" | minify | fingerprint }}
<link rel="stylesheet" href="{{ $light.RelPermalink }}" integrity="{{ $light.Data.Integrity }}" media="(prefers-color-scheme: light)">
```

`layouts/_partials/header.html`:

```go-html-template
<nav class="nav" aria-label="Main">
  <a class="site-title" href="{{ site.Home.RelPermalink }}">{{ site.Title }}<span class="cursor" aria-hidden="true">_</span></a>
  <ul class="menu">
    {{ range site.Menus.main }}
    <li><a href="{{ .URL }}"{{ if $.IsMenuCurrent .Menu . }} aria-current="page"{{ else if $.HasMenuCurrent .Menu . }} aria-current="true"{{ end }}>{{ .Name }}</a></li>
    {{ end }}
  </ul>
</nav>
```

`layouts/_partials/footer.html`:

```go-html-template
<p>&copy; {{ now.Year }} {{ site.Params.name }} - <a href="{{ site.Params.github }}">GitHub</a> - <a href="{{ site.Params.hackster }}">Hackster</a> - <a href="{{ "index.xml" | relLangURL }}">RSS</a></p>
<p class="muted">Built with Hugo. No trackers, no scripts.</p>
```

`layouts/_partials/hero.html`:

```go-html-template
<section class="hero">
  <p class="eyebrow">// {{ site.Title }}</p>
  <h1>{{ replace site.Params.name `"wero"` `<span class="nick">"wero"</span>` | safeHTML }}</h1>
  <p class="bio">{{ site.Params.bio }}</p>
  <p class="links">
    <a href="{{ site.Params.github }}">GitHub</a>
    <a href="{{ site.Params.hackster }}">Hackster</a>
    <a href="{{ site.Params.electroniccats }}">Electronic Cats</a>
    <a href="{{ "index.xml" | relLangURL }}">RSS</a>
  </p>
  {{ partial "waveform.html" . }}
</section>
```

`layouts/_partials/waveform.html`:

```go-html-template
<svg class="wave" viewBox="0 0 640 48" preserveAspectRatio="none" aria-hidden="true" focusable="false">
  <path class="wave-a" d="M0 24 C 20 4, 40 4, 60 24 S 100 44, 120 24 S 160 4, 180 24 S 220 44, 240 24 S 280 4, 300 24 S 340 44, 360 24 S 400 4, 420 24 S 460 44, 480 24 S 520 4, 540 24 S 580 44, 600 24 S 630 8, 640 24" fill="none" stroke-width="2"/>
  <path class="wave-b" d="M0 24 L 12 24 12 8 24 8 24 40 36 40 36 24 60 24 60 12 84 12 84 36 108 36 108 24 132 24 132 6 156 6 156 42 180 42 180 24 216 24 216 14 240 14 240 34 264 34 264 24 300 24 300 10 324 10 324 38 348 38 348 24 384 24 384 16 408 16 408 32 432 32 432 24 468 24 468 8 492 8 492 40 516 40 516 24 552 24 552 12 576 12 576 36 600 36 600 24 640 24" fill="none" stroke-width="1.5"/>
</svg>
```

`layouts/_partials/knobs.html`:

```go-html-template
<span class="knobs" aria-hidden="true"><i></i><i></i><i></i></span>
```

`layouts/_partials/badges.html`:

```go-html-template
{{- /* Small labels shown on cards and list items. */ -}}
{{- with .Params.role }}<span class="badge">{{ . }}</span>{{ end }}
{{- with .Params.status }}<span class="badge">{{ . }}</span>{{ end }}
{{- with .Params.lang }}{{ if eq . "es" }}<span class="badge">es</span>{{ end }}{{ end }}
{{- if .Params.external_url }}<span class="badge">{{ T "external" }}</span>{{ end }}
{{- if eq .Params.confidence "medium" }}<span class="badge warn">{{ T "unconfirmed" }}</span>{{ end }}
```

`layouts/_partials/item-link.html`:

```go-html-template
{{- /* Returns the URL an item should link to; errors if there is none. */ -}}
{{- $url := .RelPermalink }}
{{- with .Params.external_url }}{{ $url = . }}{{ end }}
{{- if not $url }}
  {{- errorf "%s has no page to link to: set external_url or remove build.render = never" .File.Path }}
{{- end }}
{{- return $url }}
```

`layouts/_partials/card.html`:

```go-html-template
{{- $url := partial "item-link.html" . }}
<li class="card" data-section="{{ .Section }}">
  <a class="card-title" href="{{ $url }}">{{ .Title }}</a>
  <p class="meta">
    {{- with .Params.event }}{{ . }}{{ with $.Params.location }}, {{ . }}{{ end }} - {{ end }}
    {{- with .Params.repo }}{{ . }}{{ with $.Params.ref }} {{ . }}{{ end }} - {{ end }}
    <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date | time.Format ":date_medium" }}</time>
  </p>
  {{ with .Description }}<p class="desc">{{ . }}</p>{{ end }}
  <p class="badges">{{ partial "badges.html" . }}</p>
</li>
```

`layouts/_partials/section-panel.html`:

```go-html-template
{{- /* Context: dict "page" $ "section" (map with name, title) */ -}}
{{- $sec := .section }}
{{- $pages := where site.RegularPages "Section" $sec.name }}
{{- $secPage := site.GetPage $sec.name }}
<section class="panel" data-section="{{ $sec.name }}">
  <h2>{{ partial "knobs.html" . }}<a href="{{ $secPage.RelPermalink }}">{{ $sec.title }}</a>
    <a class="all" href="{{ $secPage.RelPermalink }}">{{ T "all_in" (dict "Count" (len $pages)) }}</a></h2>
  {{ with first 4 $pages }}
  <ul class="cards">
    {{ range . }}{{ partial "card.html" . }}{{ end }}
  </ul>
  {{ else }}
  <p class="muted">{{ T "nothing_yet" }}</p>
  {{ end }}
</section>
```

`layouts/home.html`:

```go-html-template
{{ define "main" }}
{{ partial "hero.html" . }}
{{ range site.Params.sections }}
  {{ partial "section-panel.html" (dict "page" $ "section" .) }}
{{ end }}
{{ end }}
```

`layouts/section.html`:

```go-html-template
{{ define "main" }}
<h1 class="section-title" data-section="{{ .Section }}">{{ partial "knobs.html" . }}{{ .Title }}</h1>
{{ .Content }}
{{ with .Pages }}
<ul class="cards">
  {{ range . }}{{ partial "card.html" . }}{{ end }}
</ul>
{{ else }}
<p class="muted">{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

`layouts/talks/section.html`:

```go-html-template
{{ define "main" }}
<h1 class="section-title" data-section="{{ .Section }}">{{ partial "knobs.html" . }}{{ .Title }}</h1>
{{ .Content }}
{{ with .Pages }}
{{ range .GroupByDate "2006" }}
<h2 class="year">{{ .Key }}</h2>
<ul class="cards">
  {{ range .Pages }}{{ partial "card.html" . }}{{ end }}
</ul>
{{ end }}
{{ else }}
<p class="muted">{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

`layouts/term.html`:

```go-html-template
{{ define "main" }}
<h1 class="section-title">{{ partial "knobs.html" . }}{{ .Title }}</h1>
{{ with .Pages }}
<ul class="cards">
  {{ range . }}{{ partial "card.html" . }}{{ end }}
</ul>
{{ else }}
<p class="muted">{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

`layouts/taxonomy.html`:

```go-html-template
{{ define "main" }}
<h1 class="section-title">{{ partial "knobs.html" . }}{{ .Title }}</h1>
{{ with .Data.Terms.ByCount }}
<ul class="plain">
  {{ range . }}
  <li><a href="{{ .Page.RelPermalink }}">{{ .Page.LinkTitle }}</a> ({{ .Count }})</li>
  {{ end }}
</ul>
{{ else }}
<p class="muted">{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

`layouts/page.html`:

```go-html-template
{{ define "main" }}
<article data-section="{{ .Section }}">
  <h1>{{ .Title }}</h1>
  {{ if ne .Kind "page" }}{{ else if .Section }}
  <p class="meta">
    <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date | time.Format ":date_long" }}</time>
    {{ with .Params.event }} - {{ . }}{{ end }}
    {{ with .Params.with }} - {{ T "with" }} {{ delimit . ", " }}{{ end }}
    {{ with .GetTerms "tags" }} - {{ range $i, $t := . }}{{ if $i }}, {{ end }}<a href="{{ $t.RelPermalink }}">{{ $t.LinkTitle }}</a>{{ end }}{{ end }}
  </p>
  <p class="badges">{{ partial "badges.html" . }}
    {{ with .Params.video }}<a class="badge link" href="{{ . }}">{{ T "video" }}</a>{{ end }}
    {{ with .Params.slides }}<a class="badge link" href="{{ . }}">{{ T "slides" }}</a>{{ end }}
    {{ with .Params.source }}<a class="badge link" href="{{ . }}">{{ T "source" }}</a>{{ end }}
  </p>
  {{ end }}
  {{ .Content }}
</article>
{{ end }}
```

`assets/css/main.css`:

```css
/* Synth panel theme. Dark by default, light follows the system setting. */

@font-face {
  font-family: "JetBrains Mono";
  src: url("/fonts/JetBrainsMono.woff2") format("woff2");
  font-weight: 100 800;
  font-display: swap;
}
@font-face {
  font-family: "Inter";
  src: url("/fonts/Inter.woff2") format("woff2");
  font-weight: 100 900;
  font-display: swap;
}

:root {
  --bg: #0e0f14;
  --surface: #181a22;
  --line: #2a2c38;
  --fg: #e8e8ee;
  --muted: #9aa0b5;
  --talks: #29d3ff;
  --oss: #ff3fa4;
  --projects: #ffd166;
  --posts: #7cff6b;
  --warn: #ffd166;
  --accent: var(--talks);
  --mono: "JetBrains Mono", ui-monospace, Menlo, monospace;
  --sans: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --max: 56rem;
  color-scheme: dark;
}

@media (prefers-color-scheme: light) {
  :root {
    --bg: #f4f5f9;
    --surface: #ffffff;
    --line: #d9dbe6;
    --fg: #14151b;
    --muted: #5b6072;
    --talks: #0b7fa8;
    --oss: #c4157a;
    --projects: #9a6b00;
    --posts: #2f8f2a;
    --warn: #9a6b00;
    color-scheme: light;
  }
}

/* Section accent, set by data-section on panels, cards, titles and articles. */
[data-section="talks"] { --accent: var(--talks); }
[data-section="oss"] { --accent: var(--oss); }
[data-section="projects"] { --accent: var(--projects); }
[data-section="posts"] { --accent: var(--posts); }

*, *::before, *::after { box-sizing: border-box; }

html { -webkit-text-size-adjust: 100%; }

body {
  margin: 0;
  background: var(--bg);
  color: var(--fg);
  font: 17px/1.6 var(--sans);
}

.site-header, main, .site-footer {
  max-width: var(--max);
  margin: 0 auto;
  padding: 0 1rem;
}

a { color: var(--accent); }
a:hover { text-decoration-thickness: 2px; }

.skip {
  position: absolute;
  left: -999px;
  top: 0;
  background: var(--accent);
  color: var(--bg);
  padding: 0.5rem 1rem;
  font-family: var(--mono);
}
.skip:focus { left: 1rem; z-index: 10; }

/* Header */
.nav {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: 0.5rem 1.5rem;
  padding: 1.25rem 0;
  border-bottom: 1px solid var(--line);
  font-family: var(--mono);
}
.site-title { font-weight: 700; color: var(--fg); text-decoration: none; }
.cursor { color: var(--oss); animation: blink 1.2s steps(1) infinite; }
@keyframes blink { 50% { opacity: 0; } }
@media (prefers-reduced-motion: reduce) { .cursor { animation: none; } }

.menu { display: flex; flex-wrap: wrap; gap: 0.25rem 1rem; margin: 0; padding: 0; list-style: none; font-size: 0.9rem; }
.menu a { color: var(--muted); text-decoration: none; padding: 0.15rem 0; border-bottom: 2px solid transparent; }
.menu a:hover, .menu a[aria-current] { color: var(--fg); border-bottom-color: var(--oss); }

/* Hero */
.hero { padding: 2.5rem 0 1rem; }
.eyebrow { margin: 0; font-family: var(--mono); color: var(--muted); font-size: 0.85rem; }
.hero h1 {
  margin: 0.25rem 0 0.5rem;
  font-family: var(--mono);
  font-size: clamp(1.8rem, 5vw, 2.8rem);
  line-height: 1.1;
  letter-spacing: -0.02em;
}
.nick { color: var(--oss); }
.bio { margin: 0 0 0.75rem; font-size: 1.1rem; max-width: 36rem; }
.links { margin: 0; font-family: var(--mono); font-size: 0.9rem; display: flex; flex-wrap: wrap; gap: 0.25rem 1.25rem; }
.links a { color: var(--fg); }
.links a::before { content: "> "; color: var(--muted); }

.wave { display: block; width: 100%; height: 3rem; margin: 1.5rem 0 0; }
.wave-a { stroke: var(--talks); }
.wave-b { stroke: var(--oss); opacity: 0.8; }

/* Panels and section pages */
.panel { margin-top: 2.5rem; }
.panel h2, .section-title {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin: 0 0 1rem;
  font-family: var(--mono);
  font-size: 1.1rem;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: var(--accent);
}
.section-title { font-size: 1.6rem; margin-top: 2rem; }
.panel h2 a { color: inherit; text-decoration: none; }
.panel h2 .all {
  margin-left: auto;
  font-size: 0.8rem;
  text-transform: none;
  letter-spacing: 0;
  color: var(--muted);
  text-decoration: underline;
}
.year { font-family: var(--mono); color: var(--muted); font-size: 1rem; margin: 1.5rem 0 0.5rem; border-bottom: 1px solid var(--line); }

.knobs { display: inline-flex; gap: 0.3rem; }
.knobs i {
  width: 0.8rem;
  height: 0.8rem;
  border-radius: 50%;
  border: 2px solid var(--line);
  background: var(--surface);
  position: relative;
}
.knobs i::after {
  content: "";
  position: absolute;
  left: 50%;
  top: 0.05rem;
  width: 2px;
  height: 0.3rem;
  margin-left: -1px;
  background: var(--accent);
}
.knobs i:nth-child(2)::after { transform: rotate(60deg); transform-origin: 50% 0.35rem; }
.knobs i:nth-child(3)::after { transform: rotate(-70deg); transform-origin: 50% 0.35rem; }

/* Cards */
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(17rem, 1fr));
  gap: 0.75rem;
  margin: 0;
  padding: 0;
  list-style: none;
}
.card {
  background: var(--surface);
  border: 1px solid var(--line);
  border-top: 3px solid var(--accent);
  border-radius: 0.4rem;
  padding: 0.85rem 1rem;
}
.card-title { font-family: var(--mono); font-weight: 700; color: var(--fg); text-decoration: none; }
.card-title:hover { color: var(--accent); }
.card .meta, .card .desc { margin: 0.3rem 0 0; font-size: 0.9rem; }
.card .desc { color: var(--fg); }
.meta, .muted { color: var(--muted); }
.badges { margin: 0.5rem 0 0; display: flex; flex-wrap: wrap; gap: 0.3rem; }
.badge {
  font-family: var(--mono);
  font-size: 0.7rem;
  padding: 0.05rem 0.45rem;
  border: 1px solid var(--line);
  border-radius: 0.3rem;
  color: var(--muted);
  text-decoration: none;
}
.badge.link { color: var(--accent); border-color: var(--accent); }
.badge.warn { color: var(--warn); border-color: var(--warn); }

.plain { padding-left: 1.2rem; }

/* Article */
article h1 { font-family: var(--mono); font-size: 1.9rem; line-height: 1.2; margin: 2rem 0 0.5rem; }
article h2 { font-family: var(--mono); font-size: 1.2rem; margin-top: 2rem; color: var(--accent); }
article img { max-width: 100%; height: auto; border-radius: 0.4rem; }

code { font-family: var(--mono); font-size: 0.9em; }
:not(pre) > code { background: var(--surface); padding: 0.1em 0.3em; border-radius: 0.25rem; border: 1px solid var(--line); }
pre { padding: 1rem; overflow-x: auto; border-radius: 0.4rem; line-height: 1.45; border: 1px solid var(--line); }

/* Footer */
.site-footer {
  margin-top: 4rem;
  padding-top: 1rem;
  padding-bottom: 2rem;
  border-top: 1px solid var(--line);
  color: var(--muted);
  font-size: 0.9rem;
  font-family: var(--mono);
}
.site-footer p { margin: 0.25rem 0; }
```

- [ ] **Step 6: Run the check**

Run: `./scripts/check-site.sh`
Expected: the build succeeds and only content-dependent assertions fail, exactly these four: `FAIL public/talks/index.html lacks: class="?year"?>2024`, `FAIL public/talks/index.html lacks: href="?https://ekoparty.org/trainings2024-bombercat`, `FAIL public/oss/index.html lacks: href="?https://github.com/adafruit/TinyLoRa/pull/15`, and `FAIL public/index.html lacks: href="?/fonts/JetBrainsMono.woff2` must NOT appear (fonts are in). If anything else fails, fix the template, not the check.

Note: the two `has index.html 'data-section=...'` lines for talks and oss pass even with empty sections because the panel element itself carries the attribute.

- [ ] **Step 7: Control-test the new checks**

Each must print `check-site: FAILED` with the named FAIL line; undo each before the next:

1. In `assets/css/main.css` replace `/fonts/Inter.woff2` with `https://fonts.gstatic.com/x.woff2` -> `FAIL public/css/site.min.<hash>.css contains: fonts\.googleapis\.com|fonts\.gstatic\.com`.
2. Create `content/posts/zz-em.md` with front matter `title: 'zz em'`, `date: '2020-01-02'` and a body containing a literal em dash (bytes `e2 80 94`, e.g. `printf 'x \xe2\x80\x94 y'`) -> `FAIL public/posts/zz-em/index.html contains: <bytes>`. Delete the file.

- [ ] **Step 8: Commit**

```bash
git add static/fonts archetypes i18n hugo.toml layouts assets content/talks/_index.md content/oss/_index.md content/projects/_index.md scripts/check-site.sh
git commit -m "Synth panel theme: hero, section panels, cards, local fonts, talks and oss sections"
```
(The check is still red on the three content assertions; Task 2 turns it green. This is intentional so the theme commit is reviewable on its own.)

### Task 2: Import the researched content

**Files:**
- Create: 16 files in `content/talks/`, 13 in `content/oss/`, 9 in `content/projects/`
- Modify: `content/about.md`, `content/projects/ear-training.md`

**Interfaces:**
- Consumes: front matter contract and partials from Task 1.
- Produces: the content the check script's Task 1 assertions expect.

- [ ] **Step 1: Confirm the red assertions (the test already exists)**

Run: `./scripts/check-site.sh`
Expected: exactly the three content FAIL lines from Task 1 Step 6.

- [ ] **Step 2: Write the talks**

Dates that are only known to the year use the last day of the year and say so in `description`. Medium-confidence items have `draft: true`.

`content/talks/biobiochile-2026-quote.md`:

```markdown
---
title: 'Quoted on wireless security research (BioBioChile)'
date: '2026-09-23'
description: 'Press quote as Electronic Cats CTO on Bluetooth, LoRaWAN and LTE research. Article body not verified.'
event: 'BioBioChile'
location: 'Chile'
role: 'press'
with: []
lang: 'es'
video: ''
source: 'https://www.biobiochile.cl/noticias/ciencia-y-tecnologia/ciencia/2026/09/23/hackers-sinteticos-fraudes-con-ia-y-mas-los-nuevos-riesgos-que-ponen-a-prueba-la-ciberseguridad.shtml'
confidence: 'medium'
external_url: 'https://www.biobiochile.cl/noticias/ciencia-y-tecnologia/ciencia/2026/09/23/hackers-sinteticos-fraudes-con-ia-y-mas-los-nuevos-riesgos-que-ponen-a-prueba-la-ciberseguridad.shtml'
build:
  render: never
draft: true
---
```

`content/talks/blackhat-2025-arsenal-catsniffer.md`:

```markdown
---
title: 'Explore Wireless Hacking with CatSniffer and Minino'
date: '2025-08-06'
description: 'Electronic Cats Arsenal lab. Presenter not confirmed from public pages.'
event: 'Black Hat USA 2025 Arsenal'
location: 'Las Vegas'
role: 'speaker'
with: []
lang: 'en'
video: ''
source: 'https://x.com/electronicats/status/1945618866245115938'
confidence: 'medium'
external_url: 'https://x.com/electronicats/status/1945618866245115938'
build:
  render: never
draft: true
---
```

`content/talks/bugcon-2025-hackea-tu-badge.md`:

```markdown
---
title: 'Hackea tu Badge de BugCon 2025'
date: '2025-12-01'
description: 'Two-part livestream on hacking the Linux-based BugCon 2025 badge.'
event: 'Electronic Cats livestream'
location: 'Online'
role: 'host'
with: []
lang: 'es'
video: 'https://x.com/electronicats/status/1996354491785109722'
source: 'https://x.com/electronicats/status/1996354491785109722'
confidence: 'high'
external_url: 'https://x.com/electronicats/status/1996354491785109722'
build:
  render: never
draft: false
---
```

`content/talks/ccoss-2020-circuitpython.md`:

```markdown
---
title: 'Taller de contribucion a CircuitPython'
date: '2020-10-22'
description: 'Workshop: CircuitPython basics and how to contribute to the project.'
event: 'CCOSS 2020'
location: 'Online'
role: 'instructor'
with: ['Andres Sabas']
lang: 'es'
video: ''
source: 'https://ccoss.org/sessions/w-circuitpython/'
confidence: 'high'
external_url: 'https://ccoss.org/sessions/w-circuitpython/'
build:
  render: never
draft: false
---
```

`content/talks/dragonjar-2022-bombercat.md`:

```markdown
---
title: 'Bombercat: herramienta de auditoria para pagos NFC y MST'
date: '2022-09-09'
description: 'BomberCat as an audit tool for NFC and magstripe payments.'
event: 'DragonJAR Security Conference 2022'
location: 'Online'
role: 'speaker'
with: ['Andres Sabas']
lang: 'es'
video: 'https://www.youtube.com/watch?v=yrIi0JzlUNY'
source: 'https://x.com/dragonjar/status/1567976625974943745'
confidence: 'high'
external_url: 'https://www.youtube.com/watch?v=yrIi0JzlUNY'
build:
  render: never
draft: false
---
```

`content/talks/ekoparty-2022-bombercat.md`:

```markdown
---
title: 'BomberCat: hardware abierto para pruebas a terminales bancarias'
date: '2022-11-03'
description: 'Open hardware for testing magstripe and NFC payment terminals: emulation, relay and live data changes.'
event: 'Ekoparty 2022'
location: 'Buenos Aires'
role: 'speaker'
with: ['Andres Sabas']
lang: 'es'
video: 'https://www.youtube.com/watch?v=rrdAU4BHipM'
source: 'https://www.youtube.com/watch?v=rrdAU4BHipM'
confidence: 'high'
external_url: 'https://www.youtube.com/watch?v=rrdAU4BHipM'
build:
  render: never
draft: false
---
```

`content/talks/ekoparty-2023-bombercat-training.md`:

```markdown
---
title: 'Bombercat: Explotando el Hardware (training)'
date: '2023-10-30'
description: 'First edition of the two-day BomberCat hardware exploitation training.'
event: 'Ekoparty Trainings 2023'
location: 'Buenos Aires'
role: 'trainer'
with: []
lang: 'es'
video: ''
source: 'https://www.linkedin.com/posts/ekoparty_ekoparty-trainings-2023-bombercat-activity-7094788263948738561-xQuK'
confidence: 'high'
external_url: 'https://www.linkedin.com/posts/ekoparty_ekoparty-trainings-2023-bombercat-activity-7094788263948738561-xQuK'
build:
  render: never
draft: false
---
```

`content/talks/ekoparty-2024-bombercat-training.md`:

```markdown
---
title: 'Bombercat: Explotando el Hardware (training)'
date: '2024-11-11'
description: 'Two-day hands-on training: embedded analysis, magstripe, EMV, NFC relay attacks with BomberCat.'
event: 'Ekoparty Trainings 2024'
location: 'Buenos Aires'
role: 'trainer'
with: []
lang: 'es'
video: ''
source: 'https://ekoparty.org/trainings2024-bombercat-explotando-el-hardware-eduardo-contreras-flores/'
confidence: 'high'
external_url: 'https://ekoparty.org/trainings2024-bombercat-explotando-el-hardware-eduardo-contreras-flores/'
build:
  render: never
draft: false
---
```

`content/talks/ekoparty-2024-entendiendo-el-badge.md`:

```markdown
---
title: 'Entendiendo el Badge de Ekoparty'
date: '2024-11-14'
description: 'How the Ekoparty electronic badge works, from the people who built it.'
event: 'Ekoparty 2024'
location: 'Buenos Aires'
role: 'speaker'
with: ['Andres Sabas']
lang: 'es'
video: 'https://www.youtube.com/watch?v=bRo-Cc6bkKE'
source: 'https://www.youtube.com/watch?v=bRo-Cc6bkKE'
confidence: 'high'
external_url: 'https://www.youtube.com/watch?v=bRo-Cc6bkKE'
build:
  render: never
draft: false
---
```

`content/talks/hackaday-prize-2022-judge.md`:

```markdown
---
title: 'Hackaday Prize 2022 judge'
date: '2022-06-01'
description: 'Served on the judging panel of the 2022 Hackaday Prize.'
event: 'Hackaday Prize 2022'
location: 'Online'
role: 'judge'
with: []
lang: 'en'
video: ''
source: 'https://prize.supplyframe.com/'
confidence: 'high'
external_url: 'https://prize.supplyframe.com/'
build:
  render: never
draft: false
---
```

`content/talks/livecats-fpgas-1.md`:

```markdown
---
title: 'LiveCats: FPGAs (part 1)'
date: '2021-12-31'
description: 'What FPGAs are and what they are good for. Date unconfirmed (filed as 2021).'
event: 'Electronic Cats LiveCats'
location: 'Online'
role: 'host'
with: ['Luis Vela']
lang: 'es'
video: 'https://www.youtube.com/watch?v=n2qUuZXfcus'
source: 'https://www.youtube.com/watch?v=n2qUuZXfcus'
confidence: 'high'
external_url: 'https://www.youtube.com/watch?v=n2qUuZXfcus'
build:
  render: never
draft: false
---
```

`content/talks/livecats-fpgas-2.md`:

```markdown
---
title: 'LiveCats: FPGAs (part 2)'
date: '2021-12-31'
description: 'FPGAs, second session. Date unconfirmed (filed as 2021).'
event: 'Electronic Cats LiveCats'
location: 'Online'
role: 'host'
with: ['Luis Vela']
lang: 'es'
video: 'https://www.youtube.com/watch?v=e1Hq3HQa8jY'
source: 'https://www.youtube.com/watch?v=e1Hq3HQa8jY'
confidence: 'high'
external_url: 'https://www.youtube.com/watch?v=e1Hq3HQa8jY'
build:
  render: never
draft: false
---
```

`content/talks/livecats-kicad-6.md`:

```markdown
---
title: 'LiveCats: KiCad 6'
date: '2022-01-31'
description: 'What is new in KiCad 6, first hand. Exact date to confirm.'
event: 'Electronic Cats LiveCats'
location: 'Online'
role: 'host'
with: []
lang: 'es'
video: 'https://www.youtube.com/watch?v=2e7N5Ch6ZcY'
source: 'https://www.youtube.com/watch?v=2e7N5Ch6ZcY'
confidence: 'high'
external_url: 'https://www.youtube.com/watch?v=2e7N5Ch6ZcY'
build:
  render: never
draft: false
---
```

`content/talks/platzi-curso-iot.md`:

```markdown
---
title: 'Curso de IoT: Protocolos de Comunicacion'
date: '2019-12-31'
description: 'Online course: ESP32, HTTP, LoRa and Raspberry Pi. Year approximate.'
event: 'Platzi'
location: 'Online'
role: 'instructor'
with: []
lang: 'es'
video: ''
source: 'https://platzi.com/cursos/iot-protocolos/'
confidence: 'high'
external_url: 'https://platzi.com/cursos/iot-protocolos/'
build:
  render: never
draft: false
---
```

`content/talks/rakstars-2.md`:

```markdown
---
title: 'Hands-on with RAKStars #2'
date: '2020-10-30'
description: 'Interview: founding Electronic Cats, building hardware in Latin America, starting with LoRa.'
event: 'RAKwireless RAKStars'
location: 'Online'
role: 'guest'
with: []
lang: 'en'
video: ''
source: 'https://news.rakwireless.com/hands-on-with-rakstars-episode-2-with-eduardo-contreras/'
confidence: 'high'
external_url: 'https://news.rakwireless.com/hands-on-with-rakstars-episode-2-with-eduardo-contreras/'
build:
  render: never
draft: false
---
```

`content/talks/supercon-2024-cats-turned-plumbers.md`:

```markdown
---
title: 'Cats Turned Plumbers: Embedded Linux Adventures'
date: '2024-11-02'
description: 'From hardware to kernel: deploying embedded Linux and getting drivers into mainline.'
event: 'Hackaday Supercon 2024'
location: 'Pasadena, CA'
role: 'speaker'
with: []
lang: 'en'
video: 'https://www.youtube.com/playlist?list=PL_tws4AXg7auPrOUdmFqkt2fVRyUwzGvE'
source: 'https://hackaday.com/2024/09/25/2024-hackaday-superconference-speakers-round-two/'
confidence: 'high'
external_url: 'https://hackaday.com/2024/09/25/2024-hackaday-superconference-speakers-round-two/'
build:
  render: never
draft: false
---
```

- [ ] **Step 3: Write the open-source items**

`content/oss/adafruit-tinylora.md`:

```markdown
---
title: 'RFM_Read and chip check for TinyLoRa'
date: '2018-11-14'
description: 'Register read helper and chip-version check in init.'
repo: 'adafruit/TinyLoRa'
ref: 'PR #15'
status: 'merged'
role: 'author'
source: 'https://github.com/adafruit/TinyLoRa/pull/15'
confidence: 'high'
external_url: 'https://github.com/adafruit/TinyLoRa/pull/15'
build:
  render: never
---
```

`content/oss/beelan-lorawan.md`:

```markdown
---
title: 'Beelan-LoRaWAN Arduino library'
date: '2021-01-01'
description: 'LoRaWAN 1.0 library for Arduino; about half the commits. Date is a placeholder.'
repo: 'ElectronicCats/Beelan-LoRaWAN'
ref: ''
status: 'merged'
role: 'co-maintainer'
source: 'https://github.com/ElectronicCats/Beelan-LoRaWAN'
confidence: 'high'
external_url: 'https://github.com/ElectronicCats/Beelan-LoRaWAN'
build:
  render: never
---
```

`content/oss/catsniffer-firmware.md`:

```markdown
---
title: 'CatSniffer firmware and tools'
date: '2023-01-01'
description: 'Main committer on the CatSniffer firmware and host tools. Date is a placeholder.'
repo: 'ElectronicCats/CatSniffer-Firmware'
ref: ''
status: 'merged'
role: 'author'
source: 'https://github.com/ElectronicCats/CatSniffer-Firmware'
confidence: 'high'
external_url: 'https://github.com/ElectronicCats/CatSniffer-Firmware'
build:
  render: never
---
```

`content/oss/ctf-iot-lab-badge.md`:

```markdown
---
title: 'CTF Router Badge PCB layout'
date: '2026-06-01'
description: 'Updated the CTF router badge PCB layout.'
repo: 'p33p33/ctf-iot-lab'
ref: 'PR #1'
status: 'merged'
role: 'contributor'
source: 'https://github.com/p33p33/ctf-iot-lab/pull/1'
confidence: 'high'
external_url: 'https://github.com/p33p33/ctf-iot-lab/pull/1'
build:
  render: never
---
```

`content/oss/elasa-site.md`:

```markdown
---
title: 'Extras para los curiosos'
date: '2024-10-01'
description: 'Additions to the ELASA site.'
repo: 'elasa-do/elasa-do.github.io'
ref: 'PR #3'
status: 'merged'
role: 'contributor'
source: 'https://github.com/elasa-do/elasa-do.github.io/pull/3'
confidence: 'high'
external_url: 'https://github.com/elasa-do/elasa-do.github.io/pull/3'
build:
  render: never
---
```

`content/oss/fit-guatemala-2019.md`:

```markdown
---
title: 'Smart home workshop examples, FIT Guatemala 2019'
date: '2019-10-01'
description: 'Python and Arduino examples for the workshop board.'
repo: 'FunPythonEC/FIT_Guatemala_2019-SMART_HOME'
ref: 'PR #1'
status: 'merged'
role: 'contributor'
source: 'https://github.com/FunPythonEC/FIT_Guatemala_2019-SMART_HOME/pull/1'
confidence: 'high'
external_url: 'https://github.com/FunPythonEC/FIT_Guatemala_2019-SMART_HOME/pull/1'
build:
  render: never
---
```

`content/oss/meshtastic-catwan.md`:

```markdown
---
title: 'CatWAN USB Stick variant for Meshtastic'
date: '2026-04-01'
description: 'RP2040 + RFM95W board variant.'
repo: 'meshtastic/firmware'
ref: 'PR #10130'
status: 'closed'
role: 'author'
source: 'https://github.com/meshtastic/firmware/pull/10130'
confidence: 'high'
external_url: 'https://github.com/meshtastic/firmware/pull/10130'
build:
  render: never
---
```

`content/oss/pidcodes-catwan.md`:

```markdown
---
title: 'USB PID for an open source LoRa USB stick'
date: '2018-11-12'
description: 'The PID that became the CatWAN USB Stick.'
repo: 'pidcodes/pidcodes.github.com'
ref: 'PR #372'
status: 'merged'
role: 'author'
source: 'https://github.com/pidcodes/pidcodes.github.com/pull/372'
confidence: 'high'
external_url: 'https://github.com/pidcodes/pidcodes.github.com/pull/372'
build:
  render: never
---
```

`content/oss/sniffle-bluecat.md`:

```markdown
---
title: 'bluecat BLE toolkit and connection hijacking for Sniffle'
date: '2026-07-01'
description: 'Offensive BLE toolkit, connection hijacking firmware and CatSniffer V3 fixes.'
repo: 'nccgroup/Sniffle'
ref: 'PR #125'
status: 'open'
role: 'author'
source: 'https://github.com/nccgroup/Sniffle/pull/125'
confidence: 'high'
external_url: 'https://github.com/nccgroup/Sniffle/pull/125'
build:
  render: never
---
```

`content/oss/threatpatrol-nuclei.md`:

```markdown
---
title: 'Bake nuclei templates into the worker image'
date: '2026-05-01'
description: 'Build change for the ThreatPatrol free-tier worker.'
repo: 'pwnlabmx/threatpatrol-freetier-worker'
ref: 'PR #23'
status: 'merged'
role: 'contributor'
source: 'https://github.com/pwnlabmx/threatpatrol-freetier-worker/pull/23'
confidence: 'high'
external_url: 'https://github.com/pwnlabmx/threatpatrol-freetier-worker/pull/23'
build:
  render: never
---
```

`content/oss/tinytapeout-contribution.md`:

```markdown
---
title: 'Electronic Cats contribution page'
date: '2023-02-23'
description: 'Added the Electronic Cats contribution to the Tiny Tapeout site.'
repo: 'TinyTapeout/tinytapeout_www'
ref: 'PR #28'
status: 'merged'
role: 'author'
source: 'https://github.com/TinyTapeout/tinytapeout_www/pull/28'
confidence: 'high'
external_url: 'https://github.com/TinyTapeout/tinytapeout_www/pull/28'
build:
  render: never
---
```

`content/oss/tinytapeout-spanish.md`:

```markdown
---
title: 'Spanish translation of the Tiny Tapeout site'
date: '2023-01-25'
description: 'Full Spanish translation, credited on the Tiny Tapeout credits page.'
repo: 'TinyTapeout/tinytapeout_www'
ref: 'PR #26'
status: 'merged'
role: 'author'
source: 'https://github.com/TinyTapeout/tinytapeout_www/pull/26'
confidence: 'high'
external_url: 'https://github.com/TinyTapeout/tinytapeout_www/pull/26'
build:
  render: never
---
```

`content/oss/zephyr-sx126x-fsk.md`:

```markdown
---
title: 'sx126x driver: (G)FSK support'
date: '2026-02-01'
description: 'FSK modulation for the Semtech sx126x LoRa driver. Reviewed, closed by the stale bot.'
repo: 'zephyrproject-rtos/zephyr'
ref: 'PR #104614'
status: 'closed'
role: 'author'
source: 'https://github.com/zephyrproject-rtos/zephyr/pull/104614'
confidence: 'high'
external_url: 'https://github.com/zephyrproject-rtos/zephyr/pull/104614'
build:
  render: never
---
```

- [ ] **Step 4: Write the projects and about page**

`content/projects/climate-resilient-communities.md`:

```markdown
---
title: 'climateResilientCommunities'
date: '2022-12-31'
description: 'Sensing for climate resilient communities. Date approximate.'
featured: false
source: 'https://github.com/wero1414/climateResilientCommunities'
confidence: 'high'
external_url: 'https://github.com/wero1414/climateResilientCommunities'
build:
  render: never
---
```

`content/projects/esp-weather-station.md`:

```markdown
---
title: 'ESPWeatherStation'
date: '2018-12-31'
description: 'ESP-based weather station. Date approximate.'
featured: false
source: 'https://github.com/wero1414/ESPWeatherStation'
confidence: 'high'
external_url: 'https://github.com/wero1414/ESPWeatherStation'
build:
  render: never
---
```

`content/projects/guitar-pedals.md`:

```markdown
---
title: 'GuitarPedals'
date: '2023-06-30'
description: 'DIY guitar effects. Date approximate.'
featured: true
source: 'https://github.com/wero1414/GuitarPedals'
confidence: 'high'
external_url: 'https://github.com/wero1414/GuitarPedals'
build:
  render: never
---
```

`content/projects/hackster-bastwan.md`:

```markdown
---
title: 'Getting started: BastWAN'
date: '2019-06-01'
description: 'Hackster, code examples with Ivan Moreno.'
featured: false
source: 'https://www.hackster.io/electronic-cats/getting-started-bastwan-79c717'
confidence: 'high'
external_url: 'https://www.hackster.io/electronic-cats/getting-started-bastwan-79c717'
build:
  render: never
---
```

`content/projects/hackster-catsniffer-v3-wireshark.md`:

```markdown
---
title: 'Getting started: CatSniffer V3 with Wireshark'
date: '2024-12-31'
description: 'Hackster, Electronic Cats team. Date approximate.'
featured: false
source: 'https://www.hackster.io/electronic-cats/getting-started-catsniffer-v3-with-wireshark-77f0e3'
confidence: 'high'
external_url: 'https://www.hackster.io/electronic-cats/getting-started-catsniffer-v3-with-wireshark-77f0e3'
build:
  render: never
---
```

`content/projects/hackster-embedded-sniffle.md`:

```markdown
---
title: 'Embedded Sniffle: Sniffle without a host computer'
date: '2025-02-01'
description: 'Hackster, Electronic Cats team.'
featured: false
source: 'https://www.hackster.io/electronic-cats/embeded-sniffle-using-sniffle-without-a-host-computer-0fe982'
confidence: 'high'
external_url: 'https://www.hackster.io/electronic-cats/embeded-sniffle-using-sniffle-without-a-host-computer-0fe982'
build:
  render: never
---
```

`content/projects/hackster-rak4260-arduino.md`:

```markdown
---
title: 'RAK4260 with the Arduino IDE'
date: '2019-12-31'
description: 'Hackster guide. Date approximate.'
featured: false
source: 'https://www.hackster.io/wero1414'
confidence: 'high'
external_url: 'https://www.hackster.io/wero1414'
build:
  render: never
---
```

`content/projects/hackster-stm-lora-google-home.md`:

```markdown
---
title: 'Control an STM LoRa node with Google Home'
date: '2019-12-31'
description: 'Hackster project with Andres Sabas and The Inventors House. Date approximate.'
featured: false
source: 'https://www.hackster.io/wero1414'
confidence: 'high'
external_url: 'https://www.hackster.io/wero1414'
build:
  render: never
---
```

`content/projects/otaa-node.md`:

```markdown
---
title: 'OTAA_Node'
date: '2018-12-31'
description: 'LMIC OTAA LoRaWAN node example. Date approximate.'
featured: false
source: 'https://github.com/wero1414/OTAA_Node'
confidence: 'high'
external_url: 'https://github.com/wero1414/OTAA_Node'
build:
  render: never
---
```

`content/projects/ear-training.md`:

```markdown
---
title: 'Ear Training'
date: '2026-09-24'
description: 'Ear training web app.'
featured: true
source: 'https://github.com/wero1414/ear-training'
confidence: 'high'
external_url: 'https://github.com/wero1414/ear-training'
build:
  render: never
---
```

`content/about.md`:

```markdown
---
title: 'About'
---
I'm Eduardo Contreras, "wero" to most people. I co-founded [Electronic Cats](https://electroniccats.com/)
in Aguascalientes, Mexico, where I work on open hardware: badges, RF sniffers, LoRa boards and
payment-security tools.

This site is for the things outside of that: talks I've given, contributions to other people's
projects, side projects, and the occasional post. Music shows up too; I build pedals and I'm
learning to hear intervals.

- GitHub: [wero1414](https://github.com/wero1414)
- Hackster: [wero1414](https://www.hackster.io/wero1414)
- X: [@ForeverWero](https://x.com/ForeverWero)
```

- [ ] **Step 5: Run the check and verify it passes**

Run: `./scripts/check-site.sh`
Expected: `check-site: OK`. Also: `hugo list drafts | cut -d, -f1` lists exactly `content/talks/biobiochile-2026-quote.md` and `content/talks/blackhat-2025-arsenal-catsniffer.md`.

- [ ] **Step 6: Commit**

```bash
git add content
git commit -m "Import talks, open-source contributions and projects with sources"
```

### Task 3: Prune with the user, review, publish (outward-facing: ask before Step 3)

**Files:** whatever the user asks to remove or edit.

- [ ] **Step 1: Local preview for pruning**

Run `hugo server -D` (drafts visible, medium items show an `unconfirmed` badge). Ask the user to open `http://localhost:1313/`, look at Talks, Open source, Projects, Home, About, and reply with what to drop, rename, or flip from draft to published. Apply their edits (delete files or change front matter), re-run `./scripts/check-site.sh`, expect `check-site: OK`. If the user drops a file the check references (Ekoparty 2024 training, TinyLoRa PR, hello-world post), update that assertion to another item the user keeps; do not delete the assertion class. Commit: `git commit -am "Prune imported content after review"`.

- [ ] **Step 2: Fresh-context review of the branch**

Review range: from the commit before Task 1 to HEAD. Fix Critical/Important findings with a failing check first. Commit.

- [ ] **Step 3: Push (ask first; publishes)**

```bash
git push origin main
gh run watch -R wero1414/wero1414.github.io --exit-status
```
Expected: run `success`.

- [ ] **Step 4: Verify live**

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://wero1414.github.io/
curl -s https://wero1414.github.io/ | grep -o '<title>[^<]*</title>'
curl -s -o /dev/null -w '%{http_code}\n' https://wero1414.github.io/fonts/JetBrainsMono.woff2
curl -s https://wero1414.github.io/talks/ | grep -c 'class=card'
```
Expected: `200`, `<title>Eduardo "wero" Contreras | wero1414</title>`, `200`, `1` (one line; the page is minified) with a non-empty talks list visible in the browser.
