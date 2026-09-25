# Personal site (wero1414.github.io) - design

Date: 2026-09-25

## Purpose

A personal place online for work that is not from Electronic Cats: blog posts,
project write-ups, and links out to other web projects. Priority is "something
online" with minimal upkeep; adding a post must be as simple as adding one
Markdown file and pushing.

## Decisions (agreed in brainstorming)

| Topic | Decision |
|---|---|
| URL | `https://wero1414.github.io/` (user site) |
| Repo | `wero1414/wero1414.github.io`, branch `main`, created from local folder `~/dasiswero` |
| Generator | Hugo, installed via Homebrew (stable 0.166.0 at time of writing) |
| Deploy | GitHub Actions, official Pages flow (`actions/configure-pages`, `actions/upload-pages-artifact`, `actions/deploy-pages`), Pages source = "GitHub Actions" |
| Hugo version | Pinned in the workflow to the same version installed locally |
| Theme | Small custom theme inside the repo (`layouts/` + one CSS file), no JS, no submodules |
| Language | Single language, English (`languageCode = "en"`). Readers use browser translation. Config and `i18n/en.toml` in place so generated translations (`post.es.md`) can be added later without restructuring |

Language note: user did not explicitly pick English vs Spanish. Default is
English; switching is a one-line change to `languageCode` / `defaultContentLanguage`
plus the i18n file.

## Site structure

- `/` - home: short intro, 5 most recent posts, featured projects (`featured: true`).
- `/posts/` - all posts, newest first. Front matter: `title`, `date`, optional `tags`, `draft`.
- `/projects/` - project list. Each project is either:
  - a local page (body with write-up, images, repo link), or
  - an external link: front matter `external_url: https://...`; the list entry
    links directly there and no local page is rendered for it
    (`build.render = "never"`, `build.list = "always"`).
- `/about/` - single page: who, contact, links (GitHub `wero1414`).
- `/tags/` - Hugo default taxonomy pages.
- `/index.xml` and `/posts/index.xml` - RSS (Hugo default).

## Relation to other project sites

Model: one main site (this repo) plus one GitHub Pages site per project repo.
Each project repo (e.g. `wero1414/ear-training`) publishes its own Pages site,
served by GitHub at `https://wero1414.github.io/<repo>/`. The main site links to
them through `external_url`. Building each project's site is out of scope for
this spec; each is its own project.

Initial entry: `ear-training`. Its repo is currently empty with Pages not
enabled, so its `external_url` points to `https://github.com/wero1414/ear-training`
until its Pages site is live, then changes to `https://wero1414.github.io/ear-training/`.
This replaces the generic external-link sample project.

## Content authoring

- New post: `hugo new posts/<slug>/index.md` (page bundle, images next to it).
- New project: `hugo new projects/<slug>/index.md`, write a body or set `external_url`.
- Archetypes provide front matter templates with `draft: true`.
- Preview: `hugo server -D`.

## Theme

Templates (under `layouts/`):
- `_default/baseof.html` - HTML shell, `<html lang="{{ site.Language.LanguageCode }}">`, header, footer.
- `index.html` - home.
- `_default/list.html` - generic section/taxonomy list.
- `_default/single.html` - post/page.
- `projects/list.html` - project list honoring `external_url`.
- `partials/header.html`, `partials/footer.html`, `partials/post-item.html`.

Styling: one `assets/css/main.css`, processed with Hugo Pipes (minify + fingerprint).
Light/dark via `prefers-color-scheme`, readable on phones, code highlighting via
Hugo's built-in Chroma with CSS classes.

Interface strings in `i18n/en.toml`.

## Sample content

- 1 sample post, 1 local sample project, the `ear-training` external-link
  project (see above), about page. User may delete samples.

## Verification

Local:
1. `hugo --gc --minify --panicOnWarning` exits 0.
2. `public/` contains `index.html`, `posts/index.html`, `projects/index.html`,
   `about/index.html`, `index.xml`, the sample post page.
3. `public/index.html` has `<html lang="en">`.
4. External project: its link in `public/projects/index.html` is the external URL,
   and no `public/projects/<external-slug>/index.html` exists.

Remote (after user approves creating the public repo and pushing):
5. Actions workflow run concludes `success`.
6. `curl -sI https://wero1414.github.io/` returns HTTP 200 and the body contains the site title.

## Out of scope

Comments, search, analytics, custom domain, automated translation pipeline
(possible later, see Language), Electronic Cats content.

## Outward-facing actions (require explicit user approval at the time)

- Creating the public GitHub repo `wero1414.github.io`.
- Pushing to it (publishes the site publicly).
- Changing the repo's Pages settings via `gh api`.
