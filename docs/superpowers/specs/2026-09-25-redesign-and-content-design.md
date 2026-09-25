# Redesign "synth panel" and public-work content - design

Date: 2026-09-25. Builds on `2026-09-25-personal-site-design.md` (Hugo site live at
https://wero1414.github.io/).

## Purpose

The first version worked but looked plain. The user wants a site that is
technical with electronics and music flavour and more colour, and wants their
public work (talks, open-source contributions, projects, press) gathered on it.

## Decisions (agreed in brainstorming)

| Topic | Decision |
|---|---|
| Look | "Synth panel" (mockup B): dark by default, neon accents, waveform strip in hero, knob ornaments |
| Home layout | Panels per section (mockup A): hero, then one colour-coded panel per section with latest items and an "all N" link |
| Name | Eduardo "wero" Contreras in hero and titles; site title stays `wero1414` in nav |
| Research content | Import everything found, user prunes on a local preview before publishing; medium-confidence items start as `draft: true` |
| Stack | Unchanged: Hugo 0.166.0, in-repo theme, `scripts/check-site.sh`, GitHub Actions |

## Sections and content model

Sections: `talks`, `oss`, `projects`, `posts`, and the `about` page. Menu order:
Talks, Open source, Projects, Posts, About.

Every item is one Markdown file. It is either a local page or an external link
(`external_url` + `build.render: never`), the same mechanism as today.

Common front matter: `title`, `date`, `description`, `featured`, optional
`external_url`, `source` (URL the fact was taken from), `confidence`
(`high` | `medium`), `draft`.

Section-specific front matter:

- talks: `event`, `location`, `role` (speaker | trainer | host | guest | judge |
  instructor | press), `with` (list of names), `lang` (`en` | `es`), `video`, `slides`.
- oss: `repo` (owner/name), `status` (merged | open | closed), `role`
  (author | co-maintainer | contributor), `ref` (PR/issue number or short label).
- projects: `featured`, optional `repo`.

Archetypes exist for talks and oss so new entries are `hugo new talks/<slug>.md`.

Lists: newest first. Talks section page groups by year. Home panels show the 4
latest items per section; each item shows its badges (role/status, language,
external).

## Content to import (from the 2026-09-25 research, all with `source:`)

Talks (high): Supercon 2024 "Cats Turned Plumbers"; Ekoparty 2024 "Entendiendo el
Badge de Ekoparty"; Ekoparty trainings 2024 and 2023 "Bombercat: Explotando el
Hardware"; Ekoparty 2022 and DragonJAR 2022 BomberCat talks; LiveCats KiCad 6
(2022); LiveCats FPGAs pt 1 and 2 (date unconfirmed, use 2021-12-31 with a note);
BugCon 2025 "Hackea tu Badge" streams; RAKStars #2 (2020); CCOSS 2020 CircuitPython
workshop; Hackaday Prize 2022 judge; Platzi IoT course (instructor).
Talks (medium, draft): Black Hat USA 2025 Arsenal CatSniffer/Minino workshop;
BioBioChile 2026-09-23 press quote (under talks with `role: press`; user prunes).

OSS (high): nccgroup/Sniffle #125; meshtastic/firmware #10130; zephyr #104614;
TinyTapeout/tinytapeout_www #26 and #28; adafruit/TinyLoRa #15; pidcodes #372;
p33p33/ctf-iot-lab #1; pwnlabmx/threatpatrol-freetier-worker #23;
FunPythonEC/FIT_Guatemala_2019-SMART_HOME #1; ElectronicCats/Beelan-LoRaWAN
(co-maintainer); ElectronicCats/CatSniffer-Firmware and CatSniffer-Tools
(author, main firmware/tools committer).

Projects (high): GuitarPedals, ESPWeatherStation, OTAA_Node, climateResilientCommunities
(own repos); Hackster: RAK4260 with Arduino IDE, STM LoRa + Google Home,
Embedded Sniffle, CatSniffer V3 with Wireshark, Getting started BastWAN.
Existing: ear-training, This site.

Dates unknown beyond year use the last day of that year and a description note.
Nothing is published without the user's prune pass.

## Visual design

Tokens (CSS custom properties on `:root`, dark default, light under
`prefers-color-scheme: light`):

- bg `#0e0f14`, surface `#181a22`, line `#2a2c38`, fg `#e8e8ee`, muted `#9aa0b5`
- accents: talks cyan `#29d3ff`, oss magenta `#ff3fa4`, projects yellow `#ffd166`,
  posts green `#7cff6b`
- light: bg `#f4f5f9`, surface `#ffffff`, line `#d9dbe6`, fg `#14151b`, muted
  `#5b6072`; accents darkened for contrast (cyan `#0b7fa8`, magenta `#c4157a`,
  yellow `#9a6b00`, green `#2f8f2a`)

Type: JetBrains Mono for headings, nav, labels, badges; Inter for body. Both
self-hosted as woff2 in `static/fonts/` (downloaded from Google Fonts at build
time of the plan, licensed OFL). No third-party requests at runtime.

Hero: name with "wero" in magenta, one-line bio, links row (GitHub, Hackster,
Electronic Cats, RSS), inline SVG waveform strip (static, no JS).

Section header: three small CSS "knobs" then the section name in its accent
colour, "all N" link at the right.

Cards: surface background, 3px top border in the section accent, title, meta
line (event/date or repo/status), badges. Grid of 2 columns on desktop, 1 on
phones.

No JavaScript. Chroma styles: keep github-dark for dark, github for light.

## Check script additions

- `need` for `talks/index.html`, `oss/index.html`, and one known item per section.
- Fonts referenced from `/fonts/` exist in `public/fonts/` and no
  `fonts.googleapis.com` / `fonts.gstatic.com` string appears in generated HTML/CSS.
- Home contains all four section panels (`data-section="talks"` etc.).
- Medium-confidence fixture stays out of the build (reuse the draft fixture).
- Existing assertions stay.

## Out of scope

Comments, search, analytics, custom domain, automated translation, tabs/JS
interactions, image thumbnails for talks.

## Outward-facing actions

Push to `main` publishes. Only after the user's prune pass and explicit OK.
