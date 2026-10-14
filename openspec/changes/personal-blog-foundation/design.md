# Design

## Context

- `~/code/blog` holds only OpenSpec scaffolding, `CONTEXT.md` (the glossary; this design uses its terms) and ADR 0001 (Post URLs). It was not a git repo yet when this change started.
- Zola **0.23.6** is installed at `~/.local/bin/zola`, and the site is pinned to this version. Behaviour of this version that the design relies on (checked against the v0.23.6 docs and a throwaway build):
  - The config file is `zola.toml`; `config.toml` is only a fallback.
  - Code highlighting uses **Giallo**. With `style = "class"` it writes a generated `giallo.css` and puts *numbered* classes (`z-1`, `z-2`, …) on spans. The numbers come from sorting the color theme's colors. There is no class-only mode without a theme.
  - With an elasticlunr index format, Zola writes `elasticlunr.min.js` itself.
  - The built-in `atom.xml` template takes the author from front matter `authors`, falling back to the config's `author`.
  - Templates use **Tera v2**. Macros are gone: shared markup is defined as globally registered components (`{% component ak.post_card(page) %}`, called as `{{ <ak.post_card page={p} /> }}`). `default` only covers *missing* values, not `none`, so fallbacks use `or` (`page.description or config.description`). Tests take named arguments (`is starting_with(pat="/tags/")`). `get_url` drops trailing slashes unless `trailing_slash=true` is passed, so page links set it.
- The design system (`~/code/design-system`) provides:
  - `dist/css/theme.css`: tokens as `:root` (light) and `.dark` custom properties, plus a Tailwind-only `@theme inline` block that browsers ignore.
  - `assets/fonts/`: Outfit 400/500/600 and Fira Code 400 as TTF files, with their OFL licences.
  - `docs/native-components.md`: component specs.
  - Its `AGENTS.md` says: copy files instead of symlinking them, and default to dark mode with `<html class="dark">`.
- Tools on this machine: ImageMagick 6 (`convert`, internal SVG renderer only, no rsvg); no Node build is used. The shell aliases `rm`/`cp` to their `-i` forms, so scripts call `command rm`.

## Goals / Non-Goals

**Goals:**
- `zola build` alone produces the complete site. No other build tools are involved.
- The theme `astro-kip` is a real Zola theme in `themes/astro-kip/`, separate from the content, so it could later style another of Dennis's sites.
- Re-syncing the design tokens means copying one file, and that file is the only place colors are defined, code highlighting included.

**Non-Goals:**
- Publishing the theme for other people. Templates may assume this blog's sections.
- Image processing or responsive images. Social images are never shown on the site.
- A strict Content-Security-Policy. It belongs to the hosting change; see Risks.

## Decisions

### 1. Repo layout: site at the root, theme in `themes/astro-kip/`
```
zola.toml                 # base_url, title, author, taxonomies, feeds, search, highlighting, [extra]
content/
  _index.md               # home: sort_by date, paginate_by 10, Introduction in the body
  posts/_index.md         # transparent = true, sort_by = "date"
  posts/<slug>/index.md   # one folder per Post (keeps a per-Post Social image next to it)
  pages/_index.md         # render = false, in_search_index = false, holds fixed Pages
  pages/about.md          # path = "about"
  pages/search.md         # path = "search", template = "search.html"
themes/astro-kip/
  theme.toml
  highlight/astro-kip.json   # placeholder-color color theme (Decision 6)
  templates/              # base, index, page, section, taxonomy_list, taxonomy_single, 404, search, components, anchor-link
  static/css/tokens.css   # verbatim copy of design-system dist/css/theme.css
  static/fonts/           # Outfit + Fira Code TTFs + OFL licences
  static/js/              # theme-toggle.js, search.js
  static/icons/           # favicon.svg + PNG renders, social-default.png
  static/favicon.ico      # served at the site root
  sass/site.scss (+ partials)  # compiled by Zola's built-in Sass
scripts/check.sh          # build + assertions on public/
scripts/render-images.sh  # ImageMagick renders of favicons and Social images (Decision 12)
```
Post URLs are `/posts/<slug>/` (ADR 0001). `transparent = true` passes the posts up to the root section, so the home page can use Zola's own pagination. Fixed Pages live in a `render = false` section, which keeps them out of the listing, Feeds and search index. `zola.toml` lists the highlighting theme with a path into the theme folder, because `extra_themes` paths are resolved from the site root.

*Alternative considered:* posts directly in the root section. Rejected because About and Search would then appear in the listing and the Feed.

### 2. Tokens: copy them verbatim and link them as their own stylesheet
`tokens.css` is an unmodified copy of `theme.css`, served as a static file and linked before `site.css`. `site.css` only uses `var(--…)` and never hard-codes colors. Keeping the file byte-identical means a token update is a `cp`, and `check.sh` can `cmp` it against the design system when that repo is present. Browsers drop the Tailwind `@theme inline` block as an unknown at-rule.

*Alternatives considered:* importing it into Sass (the copy would no longer be verbatim), or extracting only the variables with a script (adds a build step).

### 3. Styles: Zola's built-in Sass, used as plain CSS with partials
Sass is used only to split the stylesheet into partials (`_fonts`, `_base`, `_layout`, `_prose`, `_components`, `_code`, `_search`). Component styles come from `docs/native-components.md`:
- **Post preview card:** `card` fill, a 1 px ring in `foreground` at 10 % via `color-mix()`, radius `xl` (`calc(var(--radius) + 4px)`), 16 px padding.
- **Tag badge:** outline variant, 20 px high, fully rounded, `xs` medium text, `border`.
- **Buttons** (toggle, pagination, previous/next): outline variant, 32 px high, radius `lg`.
- **Focus:** `ring` border plus a 3 px outer ring in `ring` at 50 %.

Overlays such as `input/30` are written as `color-mix(in srgb, var(--input) 30%, transparent)`.

### 4. Fonts: self-hosted TTFs
`@font-face` for Outfit 400/500/600 and Fira Code 400 from `/fonts/`, with `font-display: swap`. The OFL files are copied next to them. Headings use Outfit 600 and the UI uses 500. WOFF2 conversion is deferred (see Risks).

### 5. Dark Mode: `class="dark"` in the HTML and a blocking snippet in `<head>`
- `base.html` writes `<html lang="en" class="dark">`. Without JavaScript, every page is dark.
- A tiny inline script runs first in `<head>`. Inside `try/catch`, it reads `localStorage["theme"]` and removes `dark` when the value is `"light"`. This happens before first paint, so there's no flash.
- `theme-toggle.js` (deferred) flips the class, writes the choice to `localStorage` (inside try/catch), and updates the button's `aria-label` ("Switch to light mode" / "Switch to dark mode"). It does not use `aria-pressed` as well, because a changing label plus a pressed state is an a11y anti-pattern. `color-scheme` is set in CSS (`:root` light, `.dark` dark), so form controls and scrollbars follow without a meta tag. `prefers-color-scheme` is deliberately ignored.
- The toggle button is in the HTML with `hidden`, and the script shows it, so readers without JavaScript don't see a control that does nothing.

### 6. Code highlighting: a placeholder-color theme mapped to tokens
Giallo's class mode needs a real color theme and outputs numbered classes, ordered by sorted color. `themes/astro-kip/highlight/astro-kip.json` is a minimal TextMate/VS Code theme in which each **role** gets a placeholder color whose sort order is its role number:

| Class | Placeholder | Role (TextMate scopes) | Dark token | Light token |
|---|---|---|---|---|
| `z-1` | `#000002` | comment | `--subtle` | `--subtle` |
| `z-2` | `#000003` | keyword, storage, storage.type (e.g. `let`), word operators | `primary` | `secondary`, weight 600 |
| `z-3` | `#000004` | string | `success` | `success` 50 % mixed with `foreground`* |
| `z-4` | `#000005` | constant, number | `chart-4` | `primary` 60 % mixed with `foreground`* |
| `z-5` | `#000006` | function names | `chart-1` | `accent-foreground` |
| `z-6` | `#000007` | types (incl. primitive types) | `accent-foreground` | `chart-5` |

Symbolic operators and punctuation are mapped to the editor foreground (`#000001`), so Giallo gives them no class and they render in the text color.

(*Several light-mode tokens are too pale on the light code surface, so those roles mix their token towards `foreground`. The colors were computed to reach AA; task 6.4 confirms them in a browser. `--subtle` is defined in Decision 9.)

`zola.toml` sets `style = "class"`, `theme = "astro-kip"` and `extra_themes = ["themes/astro-kip/highlight/astro-kip.json"]`. The generated `giallo.css` is **never linked**; `_code.scss` maps `.z-N` → `var(--token)` per Mode (`.dark .z-N` / `:root:not(.dark) .z-N`) and styles `pre.giallo` as a surface (`muted` in light, `background` in dark, where `primary` keeps AA contrast; `border`; radius `lg`; Fira Code; `overflow-x: auto`), plus Giallo's required `.giallo-l` line rule. Because the colors are token variables, code follows the toggle with no stylesheet swap.

**Guard:** the class numbering depends on Giallo's sort order. `check.sh` asserts that `public/giallo.css` contains `.z-N { color: #00000(N+1); }` for N = 1…6, so any upstream change shows up as a failed check instead of wrong colors.

*Alternatives considered:*
- Two real color themes with token hex values copied in, swapped by JS. That duplicates the colors, needs JS for a correct dark default, and breaks token propagation.
- Inline style mode. It uses `light-dark()`, which follows the OS setting and ignores the toggle.

### 7. Search: Zola's elasticlunr JSON index and a small vanilla JS UI
`build_search_index = true`, `[search] index_format = "elasticlunr_json"`, `include_description = true`. Zola writes `search_index.en.json` and `elasticlunr.min.js`. `search.js` lazy-loads both when the search page opens, queries title (boosted), Description and body, and shows up to 10 result cards with an excerpt. It reads `?q=` on load and keeps it in sync with `history.replaceState`; a `<noscript>` block links to `/tags/`. Zola also indexes the home and posts *section* entries. Setting `in_search_index = false` on those sections would drop their Posts too, so `search.js` shows only results whose path is `/posts/<slug>/`. German Posts are indexed by the same English pipeline, so exact words match even though German isn't stemmed. That's acceptable for occasional German Posts.

### 8. Feeds, metadata and 404
- `generate_feeds = true`, `feed_filenames = ["atom.xml"]`, `author = "Dennis Sänger"`, `taxonomies = [{ name = "tags", feed = true }]`.
- The built-in Atom template is used as-is: it already has the full content, the author from `author`, and `<updated>` (checked in task 3.6, and asserted by `check.sh`). There's no `atom.xml` override.
- `base.html` writes the canonical link, the meta description (page Description, falling back to `config.description`), Open Graph title/description/URL/image, and the `<title>` as "<page title> · blog.dennis.io" (just "blog.dennis.io" on the home page).
- `taxonomy_single.html` overrides the feed autodiscovery link to point at that Tag's Feed.
- `generate_sitemap` stays on. `404.html` is a template written to `public/404.html`.

### 9. Link color and contrast in light mode
`primary` (`#df6035`) on light `background` (`#e8ebed`) is about 3:1, which fails AA. So:
- In light mode, prose links use `secondary` (`#2f4b79`) with an underline. `primary` stays for accents.
- In light mode, the reading area (post body, cards) sits on `card` (`#ffffff`).
- In dark mode, `primary` works for links (about 5:1 on `#1a1a1a`).

- Secondary text (dates, reading time, counts, comments in code) uses a derived `--subtle` color: `color-mix(in srgb, var(--muted-foreground) 55%, var(--foreground))`. `muted-foreground` alone misses AA on the page background in *both* Modes (dark ≈ 4.4:1 on `#1a1a1a`).

This picks different tokens per Mode, or mixes of tokens, without hard-coding colors.

### 10. Identity and config values
`zola.toml`:
- `title = "blog.dennis.io"`, `description` = a one-line site description (Dennis can edit it later), `author = "Dennis Sänger"` (UTF-8 ä)
- `[extra] github = "https://github.com/ds82"` and `social_image_default = "icons/social-default.png"`

The footer renders "© {{ now() | date(format="%Y") }} Dennis Sänger" and the GitHub link with `rel="me"`. More profile links later are just additions to `[extra]` and the footer.

### 11. Post front matter and reading aids
- Required: `title`, `date`, `description`. Optional: `updated`, `draft`, `[taxonomies] tags = [...]`, `[extra] lang = "de"`, `[extra] toc = true`, `[extra] social_image = "<file next to index.md>"`.
- **Dates:** `date(format="%Y-%m-%d")` inside `<time datetime>`; "Updated …" when `page.updated` is set.
- **Language:** the article gets `lang="{{ page.extra.lang }}"` only when set (the page default is `en`); its date/reading-time line carries `lang="en"` so interface text stays English.
- **Reading time:** `page.reading_time` ("N min read").
- **Anchors:** `insert_anchor_links = "right"` with a custom `anchor-link.html` (an accessible "#" link, visible on hover or focus).
- **Table of contents:** rendered from `page.toc` only when `page.extra.toc`.
- **Previous/next:** from the date-sorted posts section. `page.higher` is the *older* Post and `page.lower` the *newer* one (a comment in `page.html` says so).
- **Description check:** `check.sh` greps each `content/posts/*/index.md` front matter for a non-empty `description`. Zola itself doesn't enforce custom required fields.
- **Introduction:** body of `content/_index.md`, rendered in `index.html` only when `paginator.current_index == 1`.

### 12. Favicon and Social image
- **Sources:** `static/icons/favicon.svg` (a geometric lowercase "d" drawn from a circle and a stroke, no text, in `primary` on a rounded `background` square) and `scripts/render-images.sh`. There is no SVG source for the Social images: ImageMagick 6 here has only its internal SVG renderer, and the Outfit font isn't installed system-wide, so SVG text would render in a fallback font. The script draws the Social images with ImageMagick primitives and the bundled Outfit TTFs (`-font …/Outfit-SemiBold.ttf`).
- **Renders:** `scripts/render-images.sh` writes and the repo commits `icons/apple-touch-icon.png` (180×180), `icons/favicon-32.png`, `favicon.ico` (16/32/48, at the theme's static root so `/favicon.ico` resolves), `icons/social-default.png` (1200×630: the "d" mark, "blog.dennis.io", "Dennis Sänger", a `primary` bar) and the example Post's own `content/posts/hello-world/social.png`. The script holds copies of the dark token hex values at the top. Re-rendering after a token change is manual, like copying the tokens; this is accepted because the outputs are images.
- **`og:image`:** the Post's `extra.social_image` (absolute URL of the colocated file) or the default.

## Risks / Trade-offs

- [Giallo class numbering changes in a future Zola] → the placeholder-color guard in `check.sh` fails loudly; the Zola version is pinned in the README.
- [Light-mode highlight tokens may not all reach AA] → contrast check task; fallback is `foreground` plus weight (Decision 6).
- [Token hex values are copied into `render-images.sh`] → re-render by hand after a dark-token change; the README says so.
- [All URLs are absolute on `base_url`] → a local preview must be built or served with `--base-url` set to the exact address the browser uses (e.g. `http://127.0.0.1:1111` through an SSH tunnel); otherwise CSS and links point to a host the browser can't reach. The README documents the local build command.
- [TTF fonts are about 3× larger than WOFF2] → only four files, cached, `font-display: swap`; WOFF2 is an optional follow-up.
- [Copied `tokens.css` drifts from the design system] → `README.md` documents the re-copy, and `check.sh` compares the copy when the design-system checkout exists.
- [Inline anti-flash script conflicts with a strict CSP later] → the hosting change can add a script hash to its CSP.
- [German Posts aren't stemmed in search] → exact-word matches still work; acceptable for occasional German Posts.

## Migration Plan

There's nothing to migrate, since this is a greenfield site. The result is `public/` from `zola build`. Serving it (and setting up `404.html` as the error page) belongs to the later hosting change. To roll back, delete the files.

## Open Questions

- The About page text and the site description line: placeholders until Dennis writes them.
- Follow-up for the design-system repo: add a darker link/`primary` variant for light mode so consuming projects don't each need Decision 9's workaround.
