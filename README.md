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

## Portrait and covers

The hero portrait is a single-line drawing made with PINTR
(https://github.com/javierbyte/pintr, BSD-3-Clause; core vendored in
`scripts/pintr/`) from a photo that is not committed:

```sh
python3 scripts/pintr.py Eduardo-Contreras.png static/images/portrait.svg \
  --crop 0.30 0.06 0.48 --invert --lines 6000 --definition 100 --contrast 75
```

`--crop LEFT TOP SIDE` are fractions of the input image; `--invert` is what you
want on the dark theme (lines land on the light parts of the photo). Needs
Pillow and Node >= 22.6.

Talk cards use `cover:` from front matter, or a generated `static/covers/<slug>.svg`.
After adding a talk run `./scripts/fetch-thumbs.sh` (YouTube thumbnail as cover, if
the talk has a `video:` link) and then `./scripts/gen-covers.sh` (SVG cover for the
rest). Neither overwrites existing files.
Post cards use `cover:` or the first image in the post folder.
