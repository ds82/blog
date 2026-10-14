# Design

## Context

- The repo is `ds82/blog` on GitHub, public, default branch `main`. Pages was not enabled when this change was written; Dennis is turning it on (source: "GitHub Actions"), setting the custom domain and "Enforce HTTPS", and creating the DNS records himself.
- The site is built by `zola build`, pinned to **Zola 0.23.6**. `scripts/check.sh` runs the build itself and then asserts on `public/`. Inside it:
  - the `xmllint` check is skipped when the tool is missing
  - the `tokens.css` comparison is skipped when `~/code/design-system` isn't checked out, as in CI
- All site URLs are absolute on `https://blog.dennis.io` (`base_url`), so the CI build is the production build. There is no separate CI configuration.
- Facts checked when this change was written:
  - The Zola v0.23.6 release has `zola-v0.23.6-x86_64-unknown-linux-gnu.tar.gz` with a GitHub-published sha256 of `8f5132b3522412d04e395e0b25f6d68613ad272a873e54a2b3ebf664873024a4`.
  - Current major versions of the official actions: `actions/checkout` v7, `actions/configure-pages` v6, `actions/upload-pages-artifact` v5, `actions/deploy-pages` v5.

## Goals / Non-Goals

**Goals:**
- A push to `main` is the only step needed to publish.
- CI builds with exactly the toolchain used locally, and the same checks gate every deploy.
- Nothing in the workflow depends on third-party (non-GitHub) actions.

**Non-Goals:**
- PR or branch builds, and preview environments. A one-person blog pushes to `main`, and `check.sh` can be run locally before pushing.
- A Content-Security-Policy. GitHub Pages can't send response headers. A `<meta http-equiv>` CSP would work but needs a hash for the inline anti-flash script; it's left as a follow-up change.
- Caching the Zola binary between runs. It's a 16 MB download, which takes seconds.

## Decisions

### 1. Deploy with GitHub's Actions-based Pages, not a `gh-pages` branch
The workflow uploads `public/` as a Pages artifact (`upload-pages-artifact`) and publishes it with `deploy-pages` into the `github-pages` environment.
- No build output gets committed to the repo.
- The deploy is atomic.
- GitHub's default environment rule only accepts deployments from the default branch, which adds a second guard behind the `main`-only trigger.

The custom domain is stored in the repo's Pages settings. A `CNAME` file is not needed for Actions deployments.

*Alternative considered:* a `gh-pages` branch pushed by the workflow. Rejected because it needs `contents: write` (against the least-privilege requirement) and fills the history with build commits.

### 2. Install Zola from the official release tarball, checking its checksum
```yaml
env:
  ZOLA_VERSION: 0.23.6
  ZOLA_SHA256: 8f5132b3522412d04e395e0b25f6d68613ad272a873e54a2b3ebf664873024a4
```
One step downloads `zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz` from the GitHub release, verifies it with `sha256sum -c`, extracts `zola` into `$RUNNER_TEMP/bin` and adds that to `GITHUB_PATH`, then prints `zola --version`. Upgrading Zola means changing both values together, and the README pin at the same time.

*Alternatives considered:* community Zola actions (e.g. `shalzz/zola-deploy-action`). Rejected because they bring third-party code with Pages write access, and the Zola version they use isn't pinned by checksum. The musl build was also considered, but there's no reason to prefer it on `ubuntu-latest`.

### 3. Workflow shape: one file, two jobs
`.github/workflows/pages.yml`:
- `on: push: branches: [main]` and `workflow_dispatch`.
- `permissions: contents: read, pages: write, id-token: write` (top level, nothing else).
- `concurrency: { group: pages, cancel-in-progress: false }`. A run that is already deploying finishes, and only the **newest** pending run is kept in the queue (GitHub drops intermediate pending runs in a concurrency group). The last run to deploy is therefore always the newest push, which is what "latest push wins" requires. Cancelling in-progress runs could interrupt a half-finished deploy instead.
- **Job `build`** (`ubuntu-latest`): checkout → install Zola (Decision 2) → `scripts/check.sh` (builds and asserts) → `configure-pages` → `upload-pages-artifact` with `path: public`.
- **Job `deploy`**: `needs: build`, `environment: { name: github-pages, url: ${{ steps.deployment.outputs.page_url }} }`, `deploy-pages`.

Because `check.sh` already runs `zola build`, there's no separate build step, so CI can't publish output the checks didn't see.

### 4. Pin the GitHub-owned actions by major version
`actions/checkout@v7`, `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`. All four are maintained by GitHub, the same party that runs the platform. Major-tag pins get security fixes without anyone having to maintain them.

*Alternative considered:* full commit-SHA pins. These are stronger against a moved tag, but they go stale unless automated (Dependabot), which is more process than a personal blog needs. The decision can be revisited if a third-party action is ever added.

### 5. `xmllint` in CI
The Feed check in `check.sh` uses `xmllint` when it's available. The implementation checks whether the `ubuntu-latest` image has it (the run log of the first deploy shows whether the check ran). If it doesn't, the workflow installs `libxml2-utils` with `apt-get` before the checks. That runs on the GitHub runner, not on Dennis's machines.

### 6. HTTPS, redirect and 404 come from GitHub Pages
- With the custom domain set and "Enforce HTTPS" on, GitHub provisions a Let's Encrypt certificate and redirects `http://` to `https://`.
- GitHub Pages serves `/404.html` with status 404 for unknown paths. The theme already builds that file.

The workflow doesn't configure any of this. The rollout tasks check it.

## Risks / Trade-offs

- [Certificate provisioning lags behind the DNS change (up to about an hour); "Enforce HTTPS" can't be ticked until it's done] → the rollout tasks wait for it. The first deploy can happen before DNS is ready, and the site is then reachable at the `ds82.github.io/blog` fallback.
- [Domain takeover if Pages is ever switched off while the CNAME stays] → Dennis verifies `dennis.io` in his GitHub account (TXT record), so no other account can claim `blog.dennis.io`.
- [Zola release asset renamed or removed upstream] → the run fails loudly at the checksum step. The version and checksum live in one place in the workflow.
- [Major-tag action pins could move] → accepted for GitHub-owned actions (Decision 4).
- [GitHub Pages caches pages for about 10 minutes (`max-age=600`)] → a fresh deploy can take a few minutes to show. That's acceptable for a blog.

## Migration Plan

1. Dennis enables Pages (source: GitHub Actions), sets the custom domain and DNS records, and verifies the domain.
2. Push the workflow to `main`. The first run deploys.
3. Once the certificate is issued, turn on "Enforce HTTPS" and run the checks in the rollout tasks.

Rollback: disable the workflow, or set the Pages source to "None". DNS can stay in place or be removed.

## Open Questions

- Whether to add a `<meta http-equiv>` Content-Security-Policy, including a hash for the anti-flash script, in a later change.
