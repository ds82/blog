# blog.dennis.io

Dennis Sänger's personal blog: a static site built with [Zola](https://www.getzola.org) and the
custom theme `astro-kip` (in `themes/astro-kip/`), which uses the look of the personal design
system in `~/code/design-system`.

`CONTEXT.md` defines the vocabulary (Post, Page, Draft, Description, Feed, Social image, Mode …), and
`docs/adr/` records decisions that are hard to reverse.

## Requirements

- **Zola 0.23.6**. The site is pinned to this version: code highlighting and templates rely on
  0.23 behaviour (Giallo, Tera v2). Get the release binary from
  <https://github.com/getzola/zola/releases/tag/v0.23.6> and put it on your `PATH`, e.g.
  `~/.local/bin/zola`. Check with `zola --version`.
- **ImageMagick 6** (`convert`), only to re-render the favicon and Social images (see below).
  It is not needed to build the site.

Nothing else: no Node, npm or Tailwind.

## Build and preview

```sh
zola serve            # live preview at http://127.0.0.1:1111
zola build            # writes the site to public/
scripts/check.sh      # builds and checks the output; exits non-zero on any problem
```

Run `scripts/check.sh` before publishing. It checks, among other things:
- every Post has a Description
- Drafts don't leak
- the Feed, tags, metadata and Social images are right
- no asset loads from another host
- the code-highlighting class numbering hasn't shifted

The feature checks (ordering, prev/next, German marking, Feed content, Social images …) run
against a second build of the fixture site in `tests/site/`. It uses the same `zola.toml` and
theme (through symlinks) but has its own fixed example content, so the real Posts in `content/` can
be edited, drafted or deleted without breaking the checks. The real build in `public/` gets
only checks that hold for any content. Change `tests/site/content/` only together with the
assertions in `scripts/check.sh`.

## Deploying

Every push to `main` publishes the site to GitHub Pages at <https://blog.dennis.io>, through
`.github/workflows/pages.yml`. The workflow:

1. installs the pinned Zola (the download is checked against `ZOLA_SHA256`)
2. runs `scripts/check.sh`, which builds the site and checks it
3. deploys `public/`

If the build or any check fails, nothing is deployed and the previous version stays live. You can
also start a run by hand, from the Actions tab or with `gh workflow run pages.yml`. Pushes to other
branches never publish.

To follow the runs:

```sh
gh run list --workflow pages.yml   # recent runs and their status
gh run watch                       # follow the run that is in progress
```

**Upgrading Zola** means changing `ZOLA_VERSION` and `ZOLA_SHA256` in the workflow (the sha256
is listed with each asset on the GitHub release page) and the pin under *Requirements*,
all in the same commit.

### One-time setup

- GitHub repo → Settings → Pages: Source **GitHub Actions**, custom domain `blog.dennis.io`,
  **Enforce HTTPS** on.
- DNS for `dennis.io`: `blog.dennis.io  CNAME  ds82.github.io.`, plus the TXT record from
  GitHub account settings → Pages → *Verified domains*, so no other account can claim the
  subdomain.

GitHub serves `404.html` for unknown paths and redirects HTTP to HTTPS on its own.

### Testing the built folder locally

All URLs are absolute on `base_url`. To serve `public/` locally, build it for the address
your browser uses, e.g. `127.0.0.1` through an SSH tunnel:

```sh
zola build --base-url http://127.0.0.1:8000 && python3 -m http.server --directory public --bind 127.0.0.1 8000
```

## Writing a Post

Each Post is a folder `content/posts/<slug>/` with an `index.md`. The folder name is the
slug, and the Post is published at `/posts/<slug>/`, permanently (ADR 0001).

```toml
+++
title = "Hello, world: how this blog is built"
date = 2026-10-01
description = "One line shown on the listing card and in link previews."   # required
# updated = 2026-10-12      # optional: shown as "Updated …", sent in the Feed
# draft = true              # optional: never appears on the built site

[taxonomies]
tags = ["zola", "home-lab"] # lowercase, kebab-case

[extra]
# lang = "de"               # optional: mark the Post as German (interface stays English)
# toc = true                # optional: show a table of contents
# social_image = "social.png" # optional: a file next to index.md, used only for link previews
+++

Post body in Markdown…
```

- Dates are always shown as `YYYY-MM-DD`.
- Fenced code blocks need a language (`rust`, `sh`, …). Unknown languages fail the build.
- Drafts are left out of `zola build`. Use `zola serve --drafts` to preview them.

Fixed Pages (About, Search) live in `content/pages/`. The home page Introduction is the body of
`content/_index.md`.

## Updating from the design system

The theme copies the design system instead of linking to it. After a token or font change there:

```sh
cp ~/code/design-system/dist/css/theme.css themes/astro-kip/static/css/tokens.css
cp ~/code/design-system/assets/fonts/{Outfit-Regular,Outfit-Medium,Outfit-SemiBold,FiraCode-Regular}.ttf \
   ~/code/design-system/assets/fonts/{Outfit,FiraCode}-OFL.txt themes/astro-kip/static/fonts/
scripts/check.sh   # also fails if tokens.css differs from the design-system checkout
```

`tokens.css` must stay a verbatim copy. All theme styles (`themes/astro-kip/sass/`) use its CSS
variables and contain no color values of their own. Code highlighting is mapped to tokens in
`sass/_code.scss`, through the placeholder color theme `themes/astro-kip/highlight/astro-kip.json`.

If the dark-mode colors changed, also update the hex values at the top of
`scripts/render-images.sh` and re-render the images (next section).

## Favicon and Social images

The sources are `themes/astro-kip/static/icons/favicon.svg` and `scripts/render-images.sh`.
The script uses ImageMagick 6 to render:

- `icons/favicon-32.png`, `icons/apple-touch-icon.png` and the root `favicon.ico`
- `icons/social-default.png`: the default Social image (1200×630)
- `content/posts/hello-world/social.png`: the example Post's own Social image

```sh
scripts/render-images.sh
```

Check the PNGs by eye afterwards and commit them. For a new Post's own Social image, add a
`social_image …` line to the script (or drop any 1200×630 PNG next to the Post's `index.md`)
and set `social_image` in its front matter.
