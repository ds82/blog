#!/usr/bin/env bash
# Renders the favicon rasters and Social images with ImageMagick 6 (`convert`).
# Not part of the build: run it by hand after changing the favicon, the Social
# image layout, or the design tokens below, and commit the results.
#
# Usage: scripts/render-images.sh
set -euo pipefail

cd "$(dirname "$0")/.."
ICONS=themes/astro-kip/static/icons
FONTS=themes/astro-kip/static/fonts
STATIC=themes/astro-kip/static

# Dark-mode design tokens (copied from themes/astro-kip/static/css/tokens.css).
BACKGROUND="#1a1a1a"
FOREGROUND="#e5e5e5"
MUTED_FOREGROUND="#808080"
PRIMARY="#df6035"

tmp=$(mktemp -d)
trap 'command rm -rf "$tmp"' EXIT

# --- Favicon ------------------------------------------------------------------
convert -background none -density 576 "$ICONS/favicon.svg" -resize 180x180 "$ICONS/apple-touch-icon.png"
convert -background none -density 576 "$ICONS/favicon.svg" -resize 32x32 "$ICONS/favicon-32.png"
for size in 16 32 48; do
  convert -background none -density 576 "$ICONS/favicon.svg" -resize "${size}x${size}" "$tmp/fav-$size.png"
done
mkdir -p "$STATIC"
convert "$tmp/fav-16.png" "$tmp/fav-32.png" "$tmp/fav-48.png" "$STATIC/favicon.ico"

# --- Social images (1200x630) -------------------------------------------------
convert -background none -density 576 "$ICONS/favicon.svg" -resize 112x112 "$tmp/mark.png"

# social_image <output> <headline> <subline>
social_image() {
  convert -size 1200x630 "xc:$BACKGROUND" \
    "$tmp/mark.png" -geometry +96+88 -composite \
    -fill "$PRIMARY" -draw "rectangle 0,618 1200,630" \
    -font "$FONTS/Outfit-SemiBold.ttf" -pointsize 92 -fill "$FOREGROUND" \
    -annotate +92+392 "$2" \
    -font "$FONTS/Outfit-Regular.ttf" -pointsize 44 -fill "$MUTED_FOREGROUND" \
    -annotate +96+474 "$3" \
    -strip "$1"
}

social_image "$ICONS/social-default.png" "blog.dennis.io" "Dennis Sänger"
social_image content/posts/hello-world/social.png "Hello, world" "blog.dennis.io · Dennis Sänger"

echo "Rendered favicons and Social images."
