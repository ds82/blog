# Proposal

## Why

Dennis wants a personal blog at `https://blog.dennis.io` that looks like the rest of his projects. The look is defined in his personal design system (`~/code/design-system`: shadcn-shaped tokens seeded from the AstroVista theme, Outfit + Fira Code, dark by default). Zola fits a personal blog well: it is a single binary, writes plain static HTML, and needs no runtime. The blog repo is empty apart from OpenSpec scaffolding, so this change sets up the whole site.

The vocabulary used below (Post, Page, Draft, Tag, Description, Feed, Social image, Mode, …) is defined in `CONTEXT.md`.

## What Changes

- Create a Zola site in this repo with `base_url = "https://blog.dennis.io"` and the title **blog.dennis.io**. `zola build` turns it into a self-contained `public/` folder any static web server can serve.
- Add a custom Zola theme, **`astro-kip`**, in `themes/astro-kip/`, built on the design system:
  - a copy of the design system's `dist/css/theme.css` (copied, not symlinked, as its `AGENTS.md` asks), with hand-written plain CSS on top of its variables. There is no Tailwind or Node build step.
  - self-hosted Outfit and Fira Code fonts copied from the design system's `assets/fonts/`, with their OFL licences.
  - shadcn-style cards, badges and buttons translated from `docs/native-components.md`.
- Dark Mode by default (`<html class="dark">`, ignoring the OS setting) and a light/dark toggle that remembers the reader's choice and doesn't flash the wrong Mode on page load.
- Content structure:
  - Posts at `/posts/<slug>/` (ADR 0001). Each has a required Description, an optional Updated date and an optional German marking.
  - A home page with a short Introduction above a paginated list of Posts.
  - A `tags` taxonomy with tag pages.
  - An Atom Feed with full post content, plus one Feed per Tag.
  - A static About page and a 404 page.
- Reading aids on Posts: reading time, heading anchor links, previous/next links, and a table of contents when a Post asks for one.
- Dates shown as ISO `YYYY-MM-DD` everywhere.
- Identity: author **Dennis Sänger** in the Feed and footer, plus a GitHub link (`https://github.com/ds82`, `rel="me"`).
- A favicon, and Social images for link previews: one default for the site, which a Post can override.
- Code highlighting colored with the design tokens, in both Modes.
- Client-side search using Zola's built-in search index (elasticlunr), on its own search page.
- Two example Posts (one English, one German) that exercise the features, so the theme can be checked.

Out of scope:
- hosting and deployment (CI, containers, DNS, TLS)
- comments, analytics and newsletter features
- a translated interface or translated copies of Posts (a single Post can still be marked German)
- images shown on the site itself (covers, thumbnails)

Deployment gets its own change later; this change ends at a `public/` folder that is ready to serve.

## Capabilities

### New Capabilities
- `blog-content`: the site's content model and generated output: Posts, listing and pagination, Introduction, Tags, Feeds, About and 404 pages, reading aids, identity, favicon and Social images, canonical URLs on `blog.dennis.io`, and a self-contained static build.
- `blog-theme`: the visual theme: design-system tokens and fonts, page layouts, the dark default and toggle, token-based code highlighting, and the responsive and accessibility baseline.
- `site-search`: client-side full-text search over Posts, built from Zola's search index.

### Modified Capabilities
<!-- None: no specs exist yet. -->

## Impact

- New files in this repo:
  - `zola.toml`, `content/`, `themes/astro-kip/` (templates, `sass/`, fonts, JS, icons, the highlighting theme), `scripts/check.sh`
  - a `README.md` explaining how to build
  - `CONTEXT.md` (glossary) and `docs/adr/0001-post-urls-under-posts-prefix.md`
- New tool dependency: the Zola CLI, pinned to 0.23.6 (installed at `~/.local/bin/zola`) and documented in the README. No Node, npm or Tailwind is needed.
- ImageMagick (`convert`) is used once, by hand, to render the favicon and Social image PNGs from SVG sources. It is not part of the build.
- Depends on the design system's generated `dist/css/theme.css` and `assets/fonts/` by copying them. Token changes later are re-copied by hand, as the design system's AGENTS.md says.
- No existing code or specs are affected.
