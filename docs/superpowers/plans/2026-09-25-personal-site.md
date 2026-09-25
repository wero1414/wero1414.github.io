# Personal Site (wero1414.github.io) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Hugo site with posts, projects (local page or external link) and an about page, deployed to `https://wero1414.github.io/` by GitHub Actions.

**Architecture:** Plain Hugo 0.166.0 with a small in-repo theme (templates in `layouts/`, one CSS file plus generated Chroma styles, no JS). `scripts/check-site.sh` builds the site and asserts on `public/`; it is the test suite locally and the build step in CI. GitHub's official Pages Actions flow uploads `public/` and deploys it.

**Tech Stack:** Hugo 0.166.0 (Homebrew locally, `hugo_extended_0.166.0_linux-amd64.deb` in CI), bash, GitHub Actions (`actions/checkout@v7`, `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`; latest release tags checked 2026-09-25).

**Spec:** `docs/superpowers/specs/2026-09-25-personal-site-design.md`

All file contents below were built and checked in a throwaway prototype with Hugo 0.166.0 on 2026-09-25 (check script passed; each control test in Task 1 Step 8 failed as expected).

## Global Constraints

- Repo root is `/Users/wero1414/dasiswero` (already `git init`-ed, branch `main`).
- Remote repo: `wero1414/wero1414.github.io`, public. URL `https://wero1414.github.io/`.
- Hugo version `0.166.0` locally and in CI, exactly.
- Single language: `locale = 'en-US'`, `defaultContentLanguage = 'en'`, strings in `i18n/en.toml`.
- Template structure: Hugo >= 0.146 (`layouts/baseof.html`, `layouts/_partials/...`), not `layouts/_default/`.
- Plain ASCII everywhere: files, generated HTML, commit messages. No emojis, no em/en dashes, no smart quotes. Goldmark typographer stays disabled.
- Commit messages: no AI attribution, no Co-Authored-By trailers.
- No JavaScript in the theme. No git submodules.
- Never skip or weaken a check to make it pass.
- Creating the GitHub repo, pushing, and changing Pages settings each need the user's explicit approval at that moment.

## Review Focus

- A post dated later than build time (e.g. a timezone offset ahead of UTC) is silently omitted by Hugo; the check script proves future posts are excluded, and the README tells the author why a post may be missing.
- A `draft: true` post must never reach the live site; pinned by a temporary draft fixture in the check script.
- A project with `build.render: never` but no `external_url` would render an empty link; the build must fail with a clear message instead; pinned by a temporary broken-project fixture.
- Markdown quotes and `--` must not turn into smart quotes/dashes in the output; pinned by scanning every generated HTML file for `&rsquo;`, `&ldquo;`, `&ndash;`, `&mdash;`, `&hellip;` and similar.
- Local Hugo drifting from the CI-pinned version would make previews lie; pinned by a version comparison in the check script (Task 2).

---

### Task 1: Site, theme, sample content and check script

**Files:**
- Create: `scripts/check-site.sh`, `hugo.toml`, `i18n/en.toml`, `archetypes/posts.md`, `archetypes/projects.md`, `.gitignore`
- Create: `layouts/baseof.html`, `layouts/home.html`, `layouts/section.html`, `layouts/term.html`, `layouts/taxonomy.html`, `layouts/page.html`, `layouts/projects/section.html`
- Create: `layouts/_partials/head.html`, `layouts/_partials/header.html`, `layouts/_partials/footer.html`, `layouts/_partials/post-item.html`, `layouts/_partials/project-item.html`
- Create: `assets/css/main.css`, `assets/css/chroma-light.css`, `assets/css/chroma-dark.css` (generated)
- Create: `content/_index.md`, `content/posts/_index.md`, `content/projects/_index.md`, `content/about.md`, `content/posts/hello-world/index.md`, `content/posts/hello-world/publish-flow.svg`, `content/projects/this-site/index.md`, `content/projects/ear-training.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `scripts/check-site.sh` (run from anywhere, exits 0 and prints `check-site: OK` on success; builds into `public/`). Project front matter contract: `title`, `date`, `description`, `featured` (bool), optional `external_url` (string) together with `build.render: never`.

- [ ] **Step 1: Write the check script (the test)**

`scripts/check-site.sh`:

```bash
#!/usr/bin/env bash
# Build the site and check the generated output. Exit 0 only if every check passes.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
need()   { [ -f "public/$1" ] || { echo "FAIL missing: public/$1"; fail=1; }; }
absent() { [ ! -e "public/$1" ] || { echo "FAIL should not exist: public/$1"; fail=1; }; }
has()    { grep -Eq -- "$2" "public/$1" || { echo "FAIL public/$1 lacks: $2"; fail=1; }; }
lacks()  { ! grep -Eq -- "$2" "public/$1" || { echo "FAIL public/$1 contains: $2"; fail=1; }; }

build() { rm -rf public && hugo --gc --minify --panicOnWarning --quiet; }

# Temporary fixtures, always removed.
draft=content/posts/zz-check-draft.md
future=content/posts/zz-check-future.md
broken=content/projects/zz-check-broken.md
trap 'rm -f "$draft" "$future" "$broken"' EXIT

# 1. A project with no local page and no external_url must fail the build.
printf -- "---\ntitle: 'zz broken'\ndate: '2020-01-01'\nbuild:\n  render: never\n---\n" > "$broken"
if build >/dev/null 2>&1; then
  echo "FAIL build passed with a project that has nothing to link to"; fail=1
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
need projects/this-site/index.html
need about/index.html
need tags/index.html
need tags/meta/index.html

absent projects/ear-training/index.html
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
has index.xml 'https://wero1414.github.io/posts/hello-world/'

for f in $(find public -name '*.html'); do
  lacks "${f#public/}" '&[lrmn](squo|dquo|dash);|&hellip;'
done

if [ "$fail" -ne 0 ]; then echo "check-site: FAILED"; exit 1; fi
echo "check-site: OK"
```

Then: `chmod +x scripts/check-site.sh`

- [ ] **Step 2: Run it and verify it fails**

Run: `./scripts/check-site.sh`
Expected: exit 1 with `content/projects/zz-check-broken.md: No such file or directory` (there is no site yet). Observed exactly this in the prototype.

- [ ] **Step 3: Write config, strings, archetypes and .gitignore**

`hugo.toml`:

```toml
baseURL = 'https://wero1414.github.io/'
locale = 'en-US'
defaultContentLanguage = 'en'
title = 'wero1414'
enableRobotsTXT = true

[params]
  description = 'Personal projects, notes and experiments by wero1414.'
  github = 'https://github.com/wero1414'

[taxonomies]
  tag = 'tags'

[menus]
  [[menus.main]]
    name = 'Posts'
    pageRef = '/posts'
    weight = 10
  [[menus.main]]
    name = 'Projects'
    pageRef = '/projects'
    weight = 20
  [[menus.main]]
    name = 'About'
    pageRef = '/about'
    weight = 30

[markup.highlight]
  noClasses = false

[markup.goldmark.extensions.typographer]
  disable = true
```

`i18n/en.toml`:

```toml
[recent_posts]
other = 'Recent posts'
[all_posts]
other = 'All posts'
[projects]
other = 'Projects'
[all_projects]
other = 'All projects'
[external]
other = 'external'
[tags]
other = 'Tags'
[nothing_yet]
other = 'Nothing here yet.'
```

`archetypes/posts.md`:

```markdown
---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: '{{ .Date }}'
draft: true
tags: []
---
```

`archetypes/projects.md`:

```markdown
---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: '{{ .Date }}'
draft: true
description: ''
featured: false
# Project that lives on its own site (for example its own GitHub Pages site)?
# Uncomment these lines, set the URL, and delete the body below:
# external_url: 'https://wero1414.github.io/<repo>/'
# build:
#   render: never
---
```

`.gitignore`:

```
public/
resources/_gen/
.hugo_build.lock
```

- [ ] **Step 4: Write the templates**

`layouts/baseof.html`:

```go-html-template
<!DOCTYPE html>
<html lang="{{ site.Language.Locale }}">
<head>
  {{ partial "head.html" . }}
</head>
<body>
  <header class="site-header">
    {{ partial "header.html" . }}
  </header>
  <main>
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
<title>{{ if .IsHome }}{{ site.Title }}{{ else }}{{ .Title }} | {{ site.Title }}{{ end }}</title>
<meta name="description" content="{{ or .Description site.Params.description }}">
{{ with .OutputFormats.Get "rss" }}
<link rel="alternate" type="application/rss+xml" href="{{ .RelPermalink }}" title="{{ site.Title }}">
{{ end }}
{{ $css := slice (resources.Get "css/main.css") (resources.Get "css/chroma-light.css") | resources.Concat "css/site.css" | minify | fingerprint }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">
{{ $dark := resources.Get "css/chroma-dark.css" | minify | fingerprint }}
<link rel="stylesheet" href="{{ $dark.RelPermalink }}" integrity="{{ $dark.Data.Integrity }}" media="(prefers-color-scheme: dark)">
```

`layouts/_partials/header.html`:

```go-html-template
<nav class="nav">
  <a class="site-title" href="{{ site.Home.RelPermalink }}">{{ site.Title }}</a>
  <ul class="menu">
    {{ range site.Menus.main }}
    <li><a href="{{ .URL }}"{{ if or ($.IsMenuCurrent .Menu .) ($.HasMenuCurrent .Menu .) }} aria-current="page"{{ end }}>{{ .Name }}</a></li>
    {{ end }}
  </ul>
</nav>
```

`layouts/_partials/footer.html`:

```go-html-template
<p>&copy; {{ now.Year }} {{ site.Title }} - <a href="{{ site.Params.github }}">GitHub</a> - <a href="{{ "index.xml" | relLangURL }}">RSS</a></p>
```

`layouts/_partials/post-item.html`:

```go-html-template
<li>
  <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date | time.Format ":date_medium" }}</time>
  <a href="{{ .RelPermalink }}">{{ .Title }}</a>
</li>
```

`layouts/_partials/project-item.html`:

```go-html-template
{{- $url := .RelPermalink }}
{{- $external := false }}
{{- with .Params.external_url }}
  {{- $url = . }}
  {{- $external = true }}
{{- end }}
{{- if not $url }}
  {{- errorf "project %q has no page to link to: set external_url or remove build.render = never" .File.Path }}
{{- end }}
<li>
  <a href="{{ $url }}">{{ .Title }}</a>{{ if $external }} <span class="badge">{{ T "external" }}</span>{{ end }}
  {{ with .Description }}<p>{{ . }}</p>{{ end }}
</li>
```

`layouts/home.html`:

```go-html-template
{{ define "main" }}
<section class="intro">
  {{ .Content }}
</section>

<section>
  <h2>{{ T "recent_posts" }}</h2>
  {{ with first 5 (where site.RegularPages "Section" "posts") }}
  <ul class="list">
    {{ range . }}{{ partial "post-item.html" . }}{{ end }}
  </ul>
  {{ else }}
  <p>{{ T "nothing_yet" }}</p>
  {{ end }}
  <p><a href="{{ "posts/" | relLangURL }}">{{ T "all_posts" }}</a></p>
</section>

<section>
  <h2>{{ T "projects" }}</h2>
  {{ with where (where site.RegularPages "Section" "projects") "Params.featured" true }}
  <ul class="list projects">
    {{ range . }}{{ partial "project-item.html" . }}{{ end }}
  </ul>
  {{ else }}
  <p>{{ T "nothing_yet" }}</p>
  {{ end }}
  <p><a href="{{ "projects/" | relLangURL }}">{{ T "all_projects" }}</a></p>
</section>
{{ end }}
```

`layouts/section.html`:

```go-html-template
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ .Content }}
{{ with .Pages }}
<ul class="list">
  {{ range . }}{{ partial "post-item.html" . }}{{ end }}
</ul>
{{ else }}
<p>{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

`layouts/term.html`:

```go-html-template
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ .Content }}
{{ with .Pages }}
<ul class="list">
  {{ range . }}{{ partial "post-item.html" . }}{{ end }}
</ul>
{{ else }}
<p>{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

`layouts/taxonomy.html`:

```go-html-template
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ with .Data.Terms.ByCount }}
<ul class="list">
  {{ range . }}
  <li><a href="{{ .Page.RelPermalink }}">{{ .Page.LinkTitle }}</a> ({{ .Count }})</li>
  {{ end }}
</ul>
{{ else }}
<p>{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

`layouts/page.html`:

```go-html-template
{{ define "main" }}
<article>
  <h1>{{ .Title }}</h1>
  {{ if eq .Section "posts" }}
  <p class="meta">
    <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date | time.Format ":date_long" }}</time>
    {{ with .GetTerms "tags" }} - {{ range $i, $t := . }}{{ if $i }}, {{ end }}<a href="{{ $t.RelPermalink }}">{{ $t.LinkTitle }}</a>{{ end }}{{ end }}
  </p>
  {{ end }}
  {{ .Content }}
</article>
{{ end }}
```

`layouts/projects/section.html`:

```go-html-template
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ .Content }}
{{ with .Pages }}
<ul class="list projects">
  {{ range . }}{{ partial "project-item.html" . }}{{ end }}
</ul>
{{ else }}
<p>{{ T "nothing_yet" }}</p>
{{ end }}
{{ end }}
```

- [ ] **Step 5: Write the stylesheets**

`assets/css/main.css`:

```css
:root {
  --bg: #fdfdfc;
  --fg: #1d1d1f;
  --muted: #6b6b70;
  --accent: #0b62c4;
  --border: #e3e3e6;
  --code-bg: #f4f4f6;
  --max: 42rem;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #111214;
    --fg: #e6e6e9;
    --muted: #9a9aa2;
    --accent: #6cb0ff;
    --border: #2a2b30;
    --code-bg: #1a1b1f;
  }
}

*, *::before, *::after { box-sizing: border-box; }

html { -webkit-text-size-adjust: 100%; }

body {
  margin: 0;
  background: var(--bg);
  color: var(--fg);
  font: 17px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}

.site-header, main, .site-footer {
  max-width: var(--max);
  margin: 0 auto;
  padding: 0 1rem;
}

.nav {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: 0.5rem 1.5rem;
  padding: 1.5rem 0;
  border-bottom: 1px solid var(--border);
}

.site-title { font-weight: 700; color: var(--fg); text-decoration: none; }

.menu { display: flex; gap: 1rem; margin: 0; padding: 0; list-style: none; }
.menu a { color: var(--muted); text-decoration: none; }
.menu a:hover, .menu a[aria-current="page"] { color: var(--fg); }

a { color: var(--accent); }

h1, h2, h3 { line-height: 1.25; }
h1 { font-size: 1.9rem; margin-top: 2rem; }
h2 { font-size: 1.3rem; margin-top: 2.5rem; }

.list { margin: 0; padding: 0; list-style: none; }
.list li { padding: 0.4rem 0; }
.list time { display: inline-block; min-width: 7.5rem; color: var(--muted); font-variant-numeric: tabular-nums; }
.list.projects p { margin: 0.2rem 0 0; color: var(--muted); }

.badge {
  font-size: 0.75rem;
  padding: 0.05rem 0.4rem;
  border: 1px solid var(--border);
  border-radius: 0.3rem;
  color: var(--muted);
}

.meta { color: var(--muted); }

img { max-width: 100%; height: auto; }

code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.9em; }
:not(pre) > code { background: var(--code-bg); padding: 0.1em 0.3em; border-radius: 0.25rem; }
pre { padding: 1rem; overflow-x: auto; border-radius: 0.4rem; line-height: 1.45; }

.site-footer {
  margin-top: 4rem;
  padding-top: 1rem;
  padding-bottom: 2rem;
  border-top: 1px solid var(--border);
  color: var(--muted);
  font-size: 0.9rem;
}
```

Generate the highlighting styles (do not hand-edit them):

```bash
hugo gen chromastyles --style=github > assets/css/chroma-light.css
hugo gen chromastyles --style=github-dark > assets/css/chroma-dark.css
```

- [ ] **Step 6: Write the sample content**

Sample dates are `2026-09-24` on purpose: a date later than build time is not published (see Review Focus).

`content/_index.md`:

```markdown
---
title: 'Home'
---
Hi, I'm wero1414. This is where I put the things I build and write about
outside of my day job: hardware hacks, experiments, notes and side projects.
```

`content/posts/_index.md`:

```markdown
---
title: 'Posts'
---
```

`content/projects/_index.md`:

```markdown
---
title: 'Projects'
---
```

`content/about.md`:

```markdown
---
title: 'About'
---
I'm wero1414. I like hardware, radios and building small tools.

- GitHub: [wero1414](https://github.com/wero1414)
```

`content/posts/hello-world/index.md`:

````markdown
---
title: 'Hello World'
date: '2026-09-24'
tags: ['meta']
---
First post. This site is built with [Hugo](https://gohugo.io/) and published
with GitHub Pages.

Images live next to the post in the same folder:

![How this site gets published](publish-flow.svg)

Code blocks get syntax highlighting:

```sh
hugo new posts/my-post/index.md
hugo server -D
```
````

`content/posts/hello-world/publish-flow.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="480" height="80" viewBox="0 0 480 80" font-family="sans-serif" font-size="14">
  <rect x="1" y="20" width="130" height="40" rx="6" fill="none" stroke="#888"/>
  <text x="66" y="45" text-anchor="middle" fill="#888">write .md</text>
  <line x1="131" y1="40" x2="175" y2="40" stroke="#888"/>
  <rect x="175" y="20" width="130" height="40" rx="6" fill="none" stroke="#888"/>
  <text x="240" y="45" text-anchor="middle" fill="#888">git push</text>
  <line x1="305" y1="40" x2="349" y2="40" stroke="#888"/>
  <rect x="349" y="20" width="130" height="40" rx="6" fill="none" stroke="#888"/>
  <text x="414" y="45" text-anchor="middle" fill="#888">site updated</text>
</svg>
```

`content/projects/this-site/index.md`:

```markdown
---
title: 'This site'
date: '2026-09-24'
description: 'How this personal site is built: Hugo, a small custom theme and GitHub Pages.'
featured: false
---
Source: [github.com/wero1414/wero1414.github.io](https://github.com/wero1414/wero1414.github.io)

Plain Hugo with a hand-written theme, no JavaScript. Every push to `main`
is built and deployed by GitHub Actions.
```

`content/projects/ear-training.md`:

```markdown
---
title: 'Ear Training'
date: '2026-09-24'
description: 'Ear training web app.'
featured: true
external_url: 'https://github.com/wero1414/ear-training'
build:
  render: never
---
```

- [ ] **Step 7: Run the check and verify it passes**

Run: `./scripts/check-site.sh`
Expected: last line `check-site: OK`, exit 0. Afterwards `ls content/posts content/projects` shows no `zz-check-*` files.

- [ ] **Step 8: Control-test the checks**

Each change below must make the check print `check-site: FAILED`. Undo each change before the next one.

1. In `hugo.toml` set the typographer `disable = false` -> expect `FAIL public/... contains: &[lrmn](squo|dquo|dash);|&hellip;`.
2. Delete the `errorf` line from `layouts/_partials/project-item.html` -> expect `FAIL build passed with a project that has nothing to link to`.
3. Add `buildFuture = true` and `buildDrafts = true` at the top of `hugo.toml` -> expect `FAIL should not exist: public/posts/zz-check-draft/index.html` and the same for `zz-check-future`.
4. Delete the `build:` and `render: never` lines from `content/projects/ear-training.md` -> expect `FAIL should not exist: public/projects/ear-training/index.html`.

Then run `./scripts/check-site.sh` once more. Expected: `check-site: OK`, and `git status --short` shows only the new files from Steps 1-6.

- [ ] **Step 9: Preview by eye**

Run: `hugo server` and open `http://localhost:1313/`. Check home, Posts, Projects (Ear Training shows an `external` badge and links to GitHub), About, the `meta` tag page, light and dark system theme, and a phone-width window. Stop the server.

- [ ] **Step 10: Commit**

```bash
git add .gitignore hugo.toml i18n archetypes layouts assets content scripts
git commit -m "Add Hugo site, theme, sample content and check script"
```

### Task 2: Deploy workflow, version guard and README

**Files:**
- Modify: `scripts/check-site.sh` (add version guard above the final result line)
- Create: `.github/workflows/hugo.yml`, `README.md`

**Interfaces:**
- Consumes: `scripts/check-site.sh` from Task 1; it builds into `./public`.
- Produces: workflow `Deploy Hugo site to Pages`, triggered by push to `main` and `workflow_dispatch`, jobs `build` and `deploy`.

- [ ] **Step 1: Add the version guard (the test)**

In `scripts/check-site.sh`, insert directly above the line `if [ "$fail" -ne 0 ]; then echo "check-site: FAILED"; exit 1; fi`:

```bash
# 3. Local Hugo must match the version pinned in the deploy workflow.
wf=.github/workflows/hugo.yml
if [ -f "$wf" ]; then
  pinned=$(sed -n 's/^ *HUGO_VERSION: *//p' "$wf")
  local_v=$(hugo version | sed -E 's/^hugo v([0-9.]+).*/\1/')
  [ "$pinned" = "$local_v" ] || { echo "FAIL Hugo $local_v locally but $pinned in $wf"; fail=1; }
else
  echo "FAIL missing $wf"; fail=1
fi

```

- [ ] **Step 2: Run it and verify it fails**

Run: `./scripts/check-site.sh`
Expected: `FAIL missing .github/workflows/hugo.yml` then `check-site: FAILED`, exit 1.

- [ ] **Step 3: Write the workflow**

Based on GitHub's official `actions/starter-workflows` `pages/hugo.yml`, with action versions updated, the unused Dart Sass and Node steps removed, and the build step replaced by the check script (so CI deploys exactly what was checked).

`.github/workflows/hugo.yml`:

```yaml
name: Deploy Hugo site to Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

defaults:
  run:
    shell: bash

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.166.0
    steps:
      - name: Install Hugo CLI
        run: |
          wget -O ${{ runner.temp }}/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb \
          && sudo dpkg -i ${{ runner.temp }}/hugo.deb
      - name: Checkout
        uses: actions/checkout@v7
      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v6
      - name: Build and check
        env:
          HUGO_CACHEDIR: ${{ runner.temp }}/hugo_cache
          HUGO_ENVIRONMENT: production
        run: ./scripts/check-site.sh
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v5
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v5
```

- [ ] **Step 4: Run the checks and verify they pass**

Run: `ruby -ryaml -e 'YAML.load_file(".github/workflows/hugo.yml"); puts "yaml ok"'`
Expected: `yaml ok`

Run: `./scripts/check-site.sh`
Expected: `check-site: OK`

Control test: temporarily change `HUGO_VERSION: 0.166.0` to `0.165.0`, run the check, expect `FAIL Hugo 0.166.0 locally but 0.165.0 in .github/workflows/hugo.yml`; change it back and re-run to `check-site: OK`.

- [ ] **Step 5: Write the README**

`README.md`:

````markdown
# wero1414.github.io

Personal site: posts, projects and notes. Built with Hugo 0.166.0 and deployed
to https://wero1414.github.io/ by GitHub Actions on every push to `main`.

## Write

```sh
hugo new posts/my-post/index.md        # new post (put images in the same folder)
hugo new projects/my-project/index.md  # new project page
hugo server -D                         # preview at http://localhost:1313/ (drafts included)
```

Set `draft: false` when a post is ready. Drafts are never published.

A post dated in the future is not published until that time passes. If a post
is missing from the site, check its `date`, including the timezone offset.

## Projects with their own site

For a project that has its own GitHub Pages site, create `content/projects/<name>.md`:

```yaml
---
title: 'My Project'
date: '2026-09-24'
description: 'One line about it.'
featured: true
external_url: 'https://wero1414.github.io/<repo>/'
build:
  render: never
---
```

## Check

```sh
./scripts/check-site.sh
```

Builds the site and checks the output. CI runs the same script before deploying.
Keep local Hugo at the version in `.github/workflows/hugo.yml`; the script checks it.
````

- [ ] **Step 6: Commit**

```bash
git add scripts/check-site.sh .github/workflows/hugo.yml README.md
git commit -m "Add GitHub Pages deploy workflow, version guard and README"
```

### Task 3: Publish (outward-facing: ask the user before Steps 1, 2 and 3)

**Files:** none changed.

**Interfaces:**
- Consumes: the committed repo from Tasks 1-2.
- Produces: public repo `wero1414/wero1414.github.io` and the live site.

- [ ] **Step 1: Create the public repo (ask first)**

```bash
gh repo create wero1414/wero1414.github.io --public --description "Personal site" --source . --remote origin
```
Expected: repo URL printed, `git remote -v` shows `origin`. Nothing pushed yet.

- [ ] **Step 2: Set Pages source to GitHub Actions (ask first)**

```bash
gh api -X POST repos/wero1414/wero1414.github.io/pages -f build_type=workflow
gh api repos/wero1414/wero1414.github.io/pages --jq '.build_type,.html_url'
```
Expected: `workflow` and `https://wero1414.github.io/`. If the POST is refused on an empty repo, report the exact error and do this step after Step 3, then re-run the workflow with `gh workflow run hugo.yml -R wero1414/wero1414.github.io`.

- [ ] **Step 3: Push (ask first; this publishes the site)**

```bash
git push -u origin main
```

- [ ] **Step 4: Verify the deploy**

```bash
gh run list -R wero1414/wero1414.github.io --limit 1
gh run watch -R wero1414/wero1414.github.io --exit-status
```
Expected: the run concludes `success` for both `build` and `deploy`.

- [ ] **Step 5: Verify the live site**

```bash
curl -sI https://wero1414.github.io/ | head -1
curl -s https://wero1414.github.io/ | grep -o '<title>[^<]*</title>'
curl -s https://wero1414.github.io/projects/ | grep -Eo 'href="?https://github.com/wero1414/ear-training'
```
Expected: `HTTP/2 200`, `<title>wero1414</title>`, and the ear-training link. The first deploy can take a few minutes to become reachable; if not 200, wait and retry before reporting failure.
