# Proposal

## Why

The blog builds into a static `public/` folder (change `personal-blog-foundation`), but nothing serves it yet. The repo is now on GitHub (`ds82/blog`, public), so GitHub Pages can host it for free, custom domain and HTTPS certificate included. Publishing should happen automatically on every push to `main`, without manual build or upload steps.

## What Changes

- Add a GitHub Actions workflow that runs on every push to `main` (and on manual request). It installs the pinned Zola 0.23.6 (checksum-verified), builds the site, runs `scripts/check.sh`, and deploys `public/` to GitHub Pages.
- A failed build or check stops the deploy, so the previously published site stays live.
- Overlapping runs don't race each other: the newest push wins.
- The site is served at `https://blog.dennis.io`, with GitHub serving the theme's `404.html` for unknown paths.
- README: a "Deploying" section covering the workflow, the one-time GitHub and DNS setup, and how to tell whether a deploy went out.

Done by Dennis by hand, outside the repo, and only documented here:
- In the repo settings, set the Pages source to "GitHub Actions", the custom domain to `blog.dennis.io`, and turn on "Enforce HTTPS".
- In DNS, add `blog.dennis.io CNAME ds82.github.io.`, and the TXT record that verifies `dennis.io` in the GitHub account.

Out of scope:
- build checks on pull requests or other branches
- preview deployments
- a Content-Security-Policy (GitHub Pages can't set response headers; see design)
- other hosting providers

## Capabilities

### New Capabilities
- `site-deployment`: how the built site gets published: when it happens, what must pass first, which Zola version builds it, where it is served, and what happens when a build fails.

### Modified Capabilities
<!-- None. `blog-content` already requires absolute URLs on https://blog.dennis.io and a 404.html; this change serves them without changing those requirements. -->

## Impact

- New: `.github/workflows/pages.yml`.
- Changed: `README.md`, where the "Deploying" section replaces the generic static-server note.
- GitHub: uses Actions minutes (free for public repos) and the `github-pages` environment. The workflow token needs `pages: write` and `id-token: write`.
- DNS for `dennis.io`: one CNAME record and one TXT record, set by Dennis.
- No change to the site's content, theme or build output.
