#!/usr/bin/env bash
# Builds the site and asserts on the output in public/ and on the sources in content/.
# Usage: scripts/check.sh   (exits non-zero and lists every failed assertion)
set -uo pipefail

cd "$(dirname "$0")/.."
PUBLIC=public
failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

# assert_file <path>
assert_file() {
  [[ -f "$1" ]] || fail "missing file $1"
}

# assert_no_file <path>
assert_no_file() {
  [[ ! -e "$1" ]] || fail "unexpected file $1"
}

# assert_contains <file> <fixed string> [description]
assert_contains() {
  [[ -f "$1" ]] || { fail "missing file $1"; return; }
  grep -qF -- "$2" "$1" || fail "${3:-$1 does not contain: $2}"
}

# assert_not_contains <file> <fixed string> [description]
assert_not_contains() {
  [[ -f "$1" ]] || { fail "missing file $1"; return; }
  ! grep -qF -- "$2" "$1" || fail "${3:-$1 unexpectedly contains: $2}"
}

# assert_matches <file> <extended regex> [description]
assert_matches() {
  [[ -f "$1" ]] || { fail "missing file $1"; return; }
  grep -qE -- "$2" "$1" || fail "${3:-$1 does not match: $2}"
}

echo "Building site..."
if ! build_log=$(zola build 2>&1); then
  echo "$build_log" >&2
  echo "FAIL: zola build failed" >&2
  exit 1
fi

# --- Build output -----------------------------------------------------------
BASE="https://blog.dennis.io"
HOME_HTML="$PUBLIC/index.html"
EN_POST="$PUBLIC/posts/hello-world/index.html"
DE_POST="$PUBLIC/posts/steuererklaerung-automatisieren/index.html"
ABOUT="$PUBLIC/about/index.html"
SITE_DESCRIPTION=$(sed -n 's/^description = "\(.*\)"$/\1/p' zola.toml | head -1)

assert_file "$HOME_HTML"
assert_file "$PUBLIC/404.html"

# --- Description required on every Post (content/) -----------------------------
for post in content/posts/*/index.md content/posts/*.md; do
  [[ -f "$post" ]] || continue
  [[ "$(basename "$post")" == "_index.md" ]] && continue
  front=$(awk '/^\+\+\+$/ { n++; next } n == 1' "$post")
  grep -qE '^description[[:space:]]*=[[:space:]]*"[^"[:space:]][^"]*"' <<<"$front" \
    || fail "$post has no Description (front matter 'description' is required on Posts)"
done

# --- Design-system tokens and fonts -------------------------------------------
TOKENS=themes/astro-kip/static/css/tokens.css
DS_TOKENS="$HOME/code/design-system/dist/css/theme.css"
if [[ -f "$DS_TOKENS" ]]; then
  cmp -s "$TOKENS" "$DS_TOKENS" || fail "$TOKENS differs from $DS_TOKENS; re-copy it (see README)"
fi
assert_file "$PUBLIC/css/tokens.css"
for font in Outfit-Regular.ttf Outfit-Medium.ttf Outfit-SemiBold.ttf FiraCode-Regular.ttf Outfit-OFL.txt FiraCode-OFL.txt; do
  assert_file "$PUBLIC/fonts/$font"
done
if grep -rnE '#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\(' themes/astro-kip/sass >/dev/null; then
  fail "color literal in themes/astro-kip/sass (colors must come from tokens)"
fi

# --- Layout, identity and same-origin assets ----------------------------------
for f in "$HOME_HTML" "$EN_POST" "$ABOUT" "$PUBLIC/404.html"; do
  assert_contains "$f" '<html lang="en" class="dark">'
  assert_contains "$f" 'class="skip-link" href="#main"'
  assert_contains "$f" 'Dennis Sänger'
  assert_contains "$f" '<a href="https://github.com/ds82" rel="me">'
  assert_contains "$f" 'id="theme-toggle"'
  assert_contains "$f" 'rel="icon" href="'"$BASE"'/icons/favicon.svg"'
  assert_contains "$f" 'rel="apple-touch-icon"'
  assert_not_contains "$f" 'giallo.css' "$f links giallo.css (code colors must come from tokens)"
done
foreign=$(grep -rhoE '<(link|script|img|source|iframe)[^>]*(href|src)="(https?:)?//[^"]+"' "$PUBLIC" --include='*.html' \
  | grep -vE '(href|src)="https?://blog\.dennis\.io/' \
  | grep -vE 'rel="(me|external)"' || true)
[[ -z "$foreign" ]] || fail "assets loaded from other hosts: $foreign"
if grep -oE 'url\([^)]*\)' "$PUBLIC/site.css" | grep -qE 'url\("?(https?:)?//'; then
  fail "site.css loads assets from another host"
fi

# --- Home page listing and Introduction ---------------------------------------
assert_contains "$HOME_HTML" 'class="intro"' "home page has no Introduction"
de_line=$(grep -n 'posts/steuererklaerung-automatisieren/' "$HOME_HTML" | head -1 | cut -d: -f1)
en_line=$(grep -n 'posts/hello-world/' "$HOME_HTML" | head -1 | cut -d: -f1)
if [[ -z "$de_line" || -z "$en_line" ]] || ((de_line > en_line)); then
  fail "home page does not list Posts newest first"
fi
assert_contains "$HOME_HTML" '<p class="card-description">A tour of the pieces behind blog.dennis.io' "listing card does not show the Description"
assert_contains "$HOME_HTML" 'min read' "listing card has no reading time"

# --- Post page ------------------------------------------------------------------
assert_contains "$EN_POST" '<time datetime="2026-10-01">2026-10-01</time>' "post date is not an ISO <time>"
assert_contains "$EN_POST" 'Updated <time datetime="2026-10-12">2026-10-12</time>' "Updated date not shown"
assert_contains "$EN_POST" 'min read'
assert_contains "$EN_POST" 'class="toc"' "opt-in table of contents missing"
assert_contains "$EN_POST" 'class="heading-anchor" href="#code"' "headings have no anchor links"
assert_contains "$EN_POST" 'href="'"$BASE"'/tags/rust/"' "post tags do not link to tag pages"
assert_contains "$EN_POST" 'href="'"$BASE"'/posts/steuererklaerung-automatisieren/" rel="next"' "no link to the newer Post"
assert_contains "$DE_POST" 'href="'"$BASE"'/posts/hello-world/" rel="prev"' "no link to the older Post"
assert_contains "$DE_POST" '<article class="card surface post" lang="de">' "German Post is not marked lang=\"de\""
assert_contains "$DE_POST" '<p class="meta" lang="en">' "German Post's interface text is not English"
assert_not_contains "$DE_POST" 'class="toc"' "table of contents shown although the Post did not ask for one"

# --- Drafts ---------------------------------------------------------------------
assert_no_file "$PUBLIC/posts/unfinished-thoughts/index.html"
for f in "$HOME_HTML" "$PUBLIC/atom.xml" "$PUBLIC/search_index.en.json" "$PUBLIC/sitemap.xml"; do
  assert_not_contains "$f" 'unfinished-thoughts' "Draft leaked into $f"
done
assert_no_file "$PUBLIC/tags/drafts/index.html"

# --- Tags -----------------------------------------------------------------------
assert_matches "$PUBLIC/tags/index.html" 'href="'"$BASE"'/tags/rust/">rust</a>' "tags index does not link the rust tag"
assert_matches "$PUBLIC/tags/index.html" 'class="tag-count">1 post<' "tags index has no post counts"
assert_contains "$PUBLIC/tags/rust/index.html" 'posts/hello-world/'
assert_not_contains "$PUBLIC/tags/rust/index.html" 'posts/steuererklaerung-automatisieren/' "rust tag page lists an untagged Post"
assert_contains "$PUBLIC/tags/rust/index.html" 'href="'"$BASE"'/tags/rust/atom.xml"' "tag page does not advertise its Feed"
assert_contains "$PUBLIC/tags/rust/atom.xml" 'posts/hello-world/'
assert_not_contains "$PUBLIC/tags/rust/atom.xml" 'posts/steuererklaerung-automatisieren/' "rust tag Feed contains an untagged Post"

# --- Feed -----------------------------------------------------------------------
FEED="$PUBLIC/atom.xml"
assert_file "$FEED"
if command -v xmllint >/dev/null; then
  xmllint --noout "$FEED" 2>/dev/null || fail "$FEED is not well-formed XML"
fi
assert_contains "$HOME_HTML" '<link rel="alternate" type="application/atom+xml" title="blog.dennis.io" href="'"$BASE"'/atom.xml">' "no Feed autodiscovery link"
assert_contains "$FEED" '<name>Dennis Sänger</name>' "Feed author is not Dennis Sänger"
assert_contains "$FEED" 'it for now.&lt;/p&gt;' "Feed does not carry the full Post content"
assert_contains "$FEED" '<updated>2026-10-12T00:00:00+00:00</updated>' "Feed does not carry the Updated date"
if grep -oE '<link rel="alternate" type="text/html" href="[^"]+"' "$FEED" | grep -v "href=\"$BASE" | grep -q .; then
  fail "Feed links do not use $BASE"
fi
assert_not_contains "$FEED" "<id>$BASE/about/</id>" "About Page is in the Feed"

# --- About, 404 and metadata ------------------------------------------------------
assert_contains "$ABOUT" '<h1>About</h1>'
assert_contains "$ABOUT" '<meta name="description" content="'"$SITE_DESCRIPTION"'">' "About does not fall back to the site description"
assert_not_contains "$HOME_HTML" 'href="'"$BASE"'/about/"><' "About is listed like a Post"
assert_contains "$PUBLIC/404.html" 'Page not found'
assert_contains "$PUBLIC/404.html" 'href="'"$BASE"'/"' "404 page does not link home"
assert_contains "$EN_POST" '<title>Hello, world: how this blog is built · blog.dennis.io</title>'
assert_contains "$HOME_HTML" '<title>blog.dennis.io</title>'
assert_contains "$EN_POST" '<meta name="description" content="A tour of the pieces behind blog.dennis.io'
assert_contains "$EN_POST" '<meta property="og:description" content="A tour of the pieces behind blog.dennis.io'
assert_contains "$EN_POST" '<link rel="canonical" href="'"$BASE"'/posts/hello-world/">'
assert_contains "$EN_POST" '<meta property="og:url" content="'"$BASE"'/posts/hello-world/">'

# --- Social image and favicon ---------------------------------------------------------
assert_contains "$EN_POST" '<meta property="og:image" content="'"$BASE"'/posts/hello-world/social.png">' "Post's own Social image not used"
assert_contains "$DE_POST" '<meta property="og:image" content="'"$BASE"'/icons/social-default.png">' "default Social image not used"
assert_contains "$ABOUT" '<meta property="og:image" content="'"$BASE"'/icons/social-default.png">'
assert_file "$PUBLIC/posts/hello-world/social.png"
assert_file "$PUBLIC/icons/social-default.png"
assert_not_contains "$EN_POST" '<img' "Social image shown in the page body"
for icon in icons/favicon.svg icons/favicon-32.png icons/apple-touch-icon.png favicon.ico; do
  assert_file "$PUBLIC/$icon"
done

# --- Code highlighting -------------------------------------------------------------
# Giallo numbers classes by sorting theme colors; highlight/astro-kip.json gives
# role N the placeholder #00000(N+1). If this fails, _code.scss maps wrong roles.
for n in 1 2 3 4 5 6; do
  assert_contains "$PUBLIC/giallo.css" ".z-$n { color: #00000$((n + 1)); }" "Giallo class z-$n no longer maps to placeholder #00000$((n + 1)) (see design §6)"
done
assert_contains "$EN_POST" '<span class="z-2">fn</span>' "Rust keywords are not highlighted as role 2"
assert_contains "$EN_POST" '<span class="z-1 z-i">/// Counts' "comments are not highlighted as role 1"

# --- Search --------------------------------------------------------------------------
INDEX="$PUBLIC/search_index.en.json"
assert_file "$INDEX"
assert_file "$PUBLIC/elasticlunr.min.js"
assert_file "$PUBLIC/js/search.js"
assert_contains "$INDEX" "$BASE/posts/hello-world/"
assert_contains "$INDEX" "$BASE/posts/steuererklaerung-automatisieren/"
assert_contains "$INDEX" 'Steuererklärung'
assert_not_contains "$INDEX" "$BASE/about/" "About Page is in the search index"
assert_not_contains "$INDEX" "$BASE/search/" "Search Page is in the search index"
assert_contains "$PUBLIC/search/index.html" '<noscript>'
assert_contains "$PUBLIC/search/index.html" 'href="'"$BASE"'/tags/">tags page</a>' "search noscript message does not link to tags"
assert_contains "$PUBLIC/search/index.html" '<label for="search-input">'

# --- Summary ----------------------------------------------------------------
if ((failures > 0)); then
  echo "$failures check(s) failed." >&2
  exit 1
fi
echo "All checks passed."
