# Tasks

## 1. Workflow

- [x] 1.1 Write `.github/workflows/pages.yml` per design Decisions 2–4: triggers `push` to `main` and `workflow_dispatch`; top-level permissions `contents: read`, `pages: write`, `id-token: write`; concurrency group `pages` without cancelling in-progress runs; a `build` job (checkout → checksum-verified Zola install from `ZOLA_VERSION`/`ZOLA_SHA256` → `zola --version` → `scripts/check.sh` → `configure-pages` → `upload-pages-artifact` from `public`) and a `deploy` job (`needs: build`, `github-pages` environment, `deploy-pages`). Verify that the file parses as YAML (`python3 -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))' .github/workflows/pages.yml`) and that no action outside `actions/*` is used
- [x] 1.2 Run the workflow's Zola install commands locally in a scratch directory (download, `sha256sum -c`, extract, `zola --version`); verify that they print `zola 0.23.6` and that a deliberately wrong `ZOLA_SHA256` makes `sha256sum -c` fail

## 2. Documentation

- [x] 2.1 Replace the README's "Deploying" section: a push to `main` publishes via `.github/workflows/pages.yml`, and a failing check blocks the deploy; the one-time setup (Pages source "GitHub Actions", custom domain, Enforce HTTPS, DNS `CNAME blog.dennis.io → ds82.github.io.`, domain verification TXT); how to see a run (`gh run list --workflow pages.yml`, `gh run watch`); and that upgrading Zola means changing `ZOLA_VERSION`, `ZOLA_SHA256` and the README pin together. Verify that the commands in the section run as written

## 3. Rollout and verification on GitHub

Needs Dennis's one-time GitHub and DNS setup (proposal: "Done by Dennis by hand") to be in place.

- [x] 3.1 Commit and push the workflow and README to `main`; verify with `gh run watch` that the run succeeds, its log shows `zola 0.23.6` and "All checks passed." (and whether the `xmllint` Feed check ran; if `xmllint` was missing, add the `libxml2-utils` install step from design Decision 5 and push again), and that the "GITHUB_TOKEN Permissions" section lists only Contents read, Pages write and IdToken write
- [x] 3.2 Once DNS has propagated and "Enforce HTTPS" is on, verify the live site: `curl -sI https://blog.dennis.io/` returns 200; `curl -sI http://blog.dennis.io/` redirects to `https://`; `curl -s -o /dev/null -w '%{http_code}' https://blog.dennis.io/does-not-exist/` prints 404 and the body contains "Page not found"; `https://blog.dennis.io/css/tokens.css` and `/fonts/Outfit-Regular.ttf` return 200
- [x] 3.3 Check gating and branch rules without touching the live site: push a temporary branch where one Post has no Description, and confirm that no run starts (`gh run list`); then start the workflow by hand on that branch (`gh workflow run pages.yml --ref <branch>`) and confirm it fails at the check step and does not deploy (the live site is unchanged). Delete the branch afterwards
- [x] 3.4 Start the workflow twice in quick succession on `main` (`gh workflow run pages.yml` ×2); verify that the runs don't deploy at the same time (the second waits or the older pending one is cancelled) and that the last successful deploy is from the newest run
