# CLAUDE.md — Project source of truth

> **Standing instruction for any AI assistant (and humans) working on this repo:**
> This file is the project's source of truth. **Always keep it current.** Record the active plan,
> outstanding tasks, completed tasks, key decisions, and a dated changelog here. **Read this file at
> the start of every session** to understand the history and what to do next, and **update it
> whenever plans or status change** — not just at the end of a task. Write in whatever form is
> clearest; the goal is that a future session can be pointed at this file and immediately know where
> things stand.
>
> The detailed implementation spec lives in the plan file at
> `C:\Users\Simon\.claude\plans\this-is-a-very-precious-zephyr.md`. This CLAUDE.md is the durable
> summary + task ledger.

---

## Project overview

**GWO "Designer"** — an old (~2014) scientific web app, the "Gravitational Wave Observatory Designer"
(originally hosted at `spacegravity.org`). Recovered as three loose backup folders pulled off a
server. **Goal:** package it into a single Docker image run via docker-compose — testable locally on
Windows (Docker Desktop), then deployable to a Linux Apache server.

Four components:
- **Frontend** — Polymer **0.3.4** web components (HTML Imports + 2014 `platform.js` polyfill),
  dependencies vendored in `bower_components/`. Static files; calls the backend via `core-ajax` to
  clean URLs rewritten by `.htaccess`. *(Biggest unknown: does the old polyfill still render in a 2026
  browser?)*
- **Backend** — 17 plain **CGI Perl** scripts (mod_cgi + mod_rewrite, no database; all state is files
  on disk). They shell out to external tools.
- **LaTeX** — `report.tex` + custom `SelfArx.cls`, compiled by `pdflatex` + `bibtex` → PDF report.
- **Gnuplot** — interactive **SVG** (gnuplot `svg ... mouse jsdir` terminal; JS in `gnuplot.js/`),
  plus PNGs, plus SVG→PDF (`rsvg-convert`) for the report.

External binaries the Perl calls: `gnuplot`, `rsvg-convert` (librsvg), `convert` (ImageMagick), `zip`,
`pdflatex`/`bibtex`. Notable CPAN deps: **PDL**, **Math::Cephes**, **Imager::QRCode**, Data::UUID,
JSON::Parse, SVG, Math::Trig.

## Key decisions
- **Configurable paths.** The literal `/var/www/virtual/spacegravity.org` is hardcoded ~300× (identical
  string) across the `.pl` scripts and `report.tex`. Codemod it to `$ENV{APP_ROOT}` (default `/app`).
  Rationale: decouple from the old domain/path; trivial because the string is uniform.
- **Restructure the repo** into a clean Docker-native layout (`app/{web,cgi-bin,latex,presets}` +
  `docker/`), dropping backup/junk. Rationale: the three folders are just a backup dump.
- **Container root `/app`**, preserving the meaningful sub-paths (`htdocs/designer/`,
  `designer/latexelements/`, `cgi-bin/`) so the codemod is a pure root-swap with no extra risk.
- **TeX Live = `texlive-full`, deferred to a separate `full` Docker build stage.** Rationale: ~5GB
  download; user is on slow/airplane wifi, so everything else builds first in a `base` stage.
- **Frontend served as-is**, verified in a browser; fix only blockers (e.g. add an HTML-Imports
  polyfill). No Polymer rewrite — that's a separate future project.
- **Deploy** behind the server's existing Apache as a **reverse proxy** (ProxyPass → container),
  terminating HTTPS at the host. Isolates the old stack. The target is an **Ubuntu server that already
  runs another dockerized app via Apache mod_proxy → a container on host port 8080**. So Designer must
  publish on a **different host port** (e.g. 8081) — compose port is now `${HOST_PORT:-8080}:80`
  (8080 local, set `HOST_PORT=8081` on the server). A new Apache vhost for `spacegravity.org` will
  `ProxyPass / http://127.0.0.1:8081/`. Publish bound to 127.0.0.1 on the server.
- **Root landing page bundled in the container.** `https://spacegravity.org/` is a static landing page
  (`app/root/`: index.html + spacegravity.svg + icons) that links to the app at `/designer/`. It's
  COPYed to the container web root (`/app/htdocs`), so the container serves both `/` (landing) and
  `/designer/` (app). Host Apache therefore needs only ONE proxy rule (`ProxyPass / → container`). Chosen
  over letting the host serve `/` separately, to keep the whole site self-contained/portable.
- **Dockerfile layered so texlive never depends on app code.** Stages: `system` (apt+cpan+apache, no
  app) → `texlive` (system+texlive-full, no app) → `base` (system+app) / `full` (texlive+app). The app
  COPY block is duplicated in `base`/`full` (KEEP IN SYNC) so editing code never busts the 5GB texlive
  layer. `docker-compose` default target is `base`; `TARGET=full` for PDFs.
- **License = MIT** (user's choice; "as open as possible"). Paper is CC BY 3.0 (attribution only, NOT
  non-commercial). Bundled libs keep own licenses (jQuery MIT, Polymer BSD, gnuplot, LaTeX LPPL).
- **URLs preserved for backward-compat.** The site is being rehosted at **spacegravity.org** (now with
  HTTPS). All `http://spacegravity.org` URLs in the LaTeX report (`report.tex` `\href`s) and the
  recovery/permalink URLs (`designer-save.pl`, incl. the QR `#rc=<session>` link) are **left as-is** so
  papers/QR codes created on the old install still resolve. The **only** URL changed is the gnuplot
  `jsdir` (interactive-SVG JS), made **root-relative** `/designer/gnuplot.js/` — required so it loads
  both locally and under HTTPS (mixed-content), and harmless to old papers. No `PUBLIC_URL` env var
  (dropped — not needed).

## Plan / phases (condensed; full detail in the plan file)
- **Phase A — offline (no downloads):** A0 init CLAUDE.md · A1 restructure repo · A2 path codemod ·
  A3 author Docker assets (Dockerfile/compose/vhost/entrypoint/.dockerignore).
- **Phase B — light build:** build `base` target (Apache+Perl+gnuplot+rsvg+ImageMagick, no LaTeX);
  smoke-test frontend, gnuplot interactive SVG, QR code, zip/data export.
- **Phase C — heavy build (defer to good internet):** add `texlive-full` (`full` target); test the
  PDF report pipeline.
- **Phase D — deploy:** run on the Linux server behind Apache reverse proxy; persist data volumes.

## Outstanding tasks
- [ ] **REBUILD full before deploy** — the local `designer:full` image is STALE (predates the
      landing page + the verbatimbox fix; the fixes are in source + were `docker cp`'d into the running
      container only for testing). The Phase-D server build (`docker build --target full`) bakes
      everything fresh, so this happens naturally on deploy. A local `full` rebuild re-pulls texlive
      ONCE (Dockerfile restructure means app edits won't re-pull after that).
- [ ] **D** Deploy to the Ubuntu server: build there (`--target full`), run with `HOST_PORT=8081`, add
      an Apache vhost for spacegravity.org with `ProxyPass / http://127.0.0.1:8081/` (+ ProxyPassReverse,
      HTTPS). See `docker/DEPLOY.md`.

## Completed tasks
- [x] **C (DONE)** PDF report pipeline verified end-to-end on `designer:full`: drove a real
      `download.report/<uuid>.pdf` (real `parameters.json` from the backup + a fresh displacement
      calc) → a **21-page, ~2MB valid PDF**. Found & fixed the one real environment bug: TeX Live 2022
      has a `verbatimbox`/`readarray` version skew — `\addvbuffer` calls undefined `\getargsC` (~100
      errors/report). Fixed by redefining `\addvbuffer` as a passthrough in `app/latex/report.tex` and
      `app/cgi-bin/report.full.pl` (drops only ~8pt cosmetic spacing). Remaining log errors were pure
      test-data artifacts (an unrelated old `parameters.json` with an array value → `\num{ARRAY(..)}`;
      missing plots because only 1 of ~5 calcs was run) — NOT container/toolchain issues.
- [x] **GIT** Repo initialized on `main`, 2 commits (containerize + verbatimbox fix). No remote (user
      publishes via GitHub Desktop → name `gwo-designer`, owner `gulbrillo`). `_pdftest/` gitignored.
- [x] **A0** Initialized CLAUDE.md (this file) as the living tracker.
- [x] **A1** Restructured repo into `app/{web,cgi-bin,latex,presets}` + `docker/`. Dropped backups
      (`*.bak*`, index variants, `bower_components.old`, `designer.zip`, etc.) and cleared stale
      runtime data. The three `*.tar.gz` are kept on disk as the only backup (no git). Aux files the
      scripts read by relative/abs path were kept in `app/cgi-bin`: `head.htm`, `SelfArx.cls`,
      `spectrum.pdf`, `spacegravity.bib`. Preset JSONs kept in `app/web/templates`.
- [x] **A2** Path codemod via `docker/codemod.sh` (idempotent, committed): filesystem root →
      `$ENV{APP_ROOT}` in all `*.pl` (~300 hits); `report.tex` root → `<approot>` token + a one-line
      `s|<approot>|$ENV{APP_ROOT}|g` added to `designer-report.pl`'s substitution loop; gnuplot
      `jsdir` → root-relative `/designer/gnuplot.js/` (12 hits). All other `spacegravity.org` URLs
      preserved per backward-compat decision. `perl -c` validation deferred to the Docker build.
- [x] **B (DONE incl. browser)** Polymer 0.3.4 UI **renders fine** in a current browser — the big
      unknown is resolved; no HTML-Imports polyfill needed. Console was clean except: a real
      `$.browser.msie` error from `jquery.ba-hashchange` (jQuery ≥1.9 removed `$.browser`) — this drives
      nav AND the `#rc=` recovery permalinks, so **fixed** with a one-line `jQuery.browser ||= {}` shim
      in `app/web/index.html` before the plugin loads. The rest were harmless: ad-blocker-blocked
      external trackers (freegeoip, YouTube embed telemetry), a benign first-load `sessions//qr.svg`
      404 (empty session id before any save), and a debug `console.log` in the plot component. NOTE:
      the dev override bind-mounts `app/web` live, so HTML/JS edits show on refresh without a rebuild.
- [x] **B (server-side)** Built `designer:base` and ran it as compose project **`gwo-designer`**
      (port 8080). All 17 scripts pass the build-time `perl -c` gate. Verified live via curl/exec:
      static frontend (index 97KB, jquery-latest, platform.js all 200, `/`→`/designer/` redirect);
      **a full `calculate.displacement`** using the LISA preset produced interactive gnuplot **SVGs**
      (served 200 `image/svg+xml`, embedding the root-relative `xlink:href="/designer/gnuplot.js/
      gnuplot_svg.js"`), a watermarked **PNG** (gnuplot pngcairo + ImageMagick `convert`), and
      **rsvg-convert PDFs** under `plots/`; `save.recovery` produced a QR `qr.svg` (Data::UUID +
      Imager::QRCode); `zip` verified on real data. So the whole base toolchain works end-to-end.
- [x] **A3** Authored `docker/`: `Dockerfile` (multi-stage `base`/`full`), `000-designer.conf` (vhost
      template), `entrypoint.sh` (envsubst conf + chown volumes + run Apache), `docker-compose.yml`
      (port `${HOST_PORT:-8080}:80`, named volumes), `docker-compose.override.yml` (dev bind-mount of
      web only), `.dockerignore`. Verified: `report.tex` documentclass/bib are ABSOLUTE (`<approot>`-
      expanded) so designer-report needs no TEXINPUTS; `report.full.pl` uses relative
      `\documentclass{SelfArx}` → covered by `TEXINPUTS` incl. `cgi-bin//`. pdflatex sets a writable
      `HOME` for the TeX font cache. Shell scripts pass `bash -n`.

## Changelog
- **2026-06-05** — Analyzed the app (Perl CGI backend, Polymer 0.3.4 frontend, LaTeX report,
  interactive gnuplot SVG). Wrote and got approval for the containerization plan. Created this
  CLAUDE.md tracker.
- **2026-06-05** — **A1 done.** Restructured into `app/` + `docker/`. Near-miss caught: deleted
  `jquery-latest.min.js` then restored it from `designer-html.tar.gz` (index.html line 96 needs it;
  it's jQuery 1.x — do NOT swap for the bundled 3.2.0). Identification dir is not shipped (9075 old
  `.id` files dropped); the Dockerfile will `mkdir` it as a writable volume at
  `/app/designer/identification`.
- **2026-06-05** — **A2 done.** Ran the path codemod. Course-corrected on URLs after user clarified
  the site stays at spacegravity.org and old papers/QR recovery URLs must keep working: reverted the
  recovery-URL change, kept all `\href`/recovery URLs literal, changed ONLY the gnuplot `jsdir` to
  root-relative, and dropped the `PUBLIC_URL` env var. `codemod.sh` rewritten to this final intent.
- **2026-06-05** — **A3 done → Phase A (all offline work) COMPLETE.** Wrote all `docker/` assets.
  Clarified deploy topology with user: host Apache is just a reverse proxy (needs only mod_proxy);
  Perl/LaTeX/gnuplot all live in the container. Server already runs another container on host :8080,
  so Designer uses `HOST_PORT=8081` there. **Next: Phase B build — needs internet (user was on
  airplane wifi), so do NOT auto-build; wait for the user to have bandwidth.**
- **2026-06-06** — **Phase B server-side smoke test PASSED.** Built `designer:base`, ran as compose
  project `gwo-designer`. Two fixes during bring-up: (1) `mod_cgid` couldn't start — entrypoint now
  `mkdir -p`s `${APACHE_RUN_DIR}/socks` (Debian's init normally makes it); (2) set compose project
  `name: gwo-designer` (was defaulting to `docker`). Drove a real LISA-preset displacement calc end to
  end — gnuplot SVG/PNG, rsvg-convert PDFs, ImageMagick watermark, Imager::QRCode, zip all confirmed
  working. The `download.data` 500 seen during testing was MY malformed synthetic `parameters.json`
  (passed `con=tri` instead of the JSON-fragment values the real UI sends), not a container bug — the
  real browser flow writes valid JSON. **Remaining for B: the human must eyeball the Polymer UI in a
  browser (can't be done via curl).** Container left running on :8080.
  Gotcha learned: Git-Bash MSYS rewrites `/app/...` args to `C:\...` in `docker exec` — wrap paths in
  `bash -c '...'` to avoid it.
- **2026-06-06** — **Phase C build done + landing page + repo packaging.** (1) `texlive-full` built
  (`designer:full`, 7.6GB) — exit 0; end-to-end PDF run deferred (see Outstanding C). (2) Confirmed the
  2015 CQG paper is **CC BY 3.0** (attribution only). (3) User added `designer.htdocs` = the
  spacegravity.org root landing page; decided to BUNDLE it in the container → moved to `app/root/`,
  COPYed to web root, dropped the old `/`→`/designer/` redirect. (4) Restructured the Dockerfile into
  system/texlive/base/full stages so app edits never re-pull texlive. (5) Authored `README.md`, MIT
  `LICENSE`, `CITATION.cff`, `.gitignore`, `.gitattributes` (force LF — prevents the CRLF/CGI gotcha),
  `docker/DEPLOY.md`. (6) `git init` done (branch `main`, identity gulbrillo/simon.barke@gmail.com).
  Rebuilt+verified `base`: `/` serves the landing page, assets resolve, `/designer/` still works.
- **2026-06-06** — **Phase C VERIFIED (PDF works).** Drove `download.report` end-to-end → 21-page 2MB
  PDF. Fixed the verbatimbox/readarray `\addvbuffer`/`\getargsC` skew (passthrough redefinition) in
  report.tex + report.full.pl; committed. Confirmed remaining log errors are test-data artifacts, not
  bugs. All major phases (containerize, frontend, gnuplot, QR, zip, PDF, landing page, packaging) done
  — only deployment (D) remains. Reminder: `designer:full` must be rebuilt to bake the fixes (the
  server deploy build does this; one texlive re-pull).
- **2026-06-06** — **New feature: Overview Document.** Wired up the previously-disabled "Overview
  Document" download (per-session, route `download.overview/<session>.pdf`). New `app/latex/summary.tex`
  (trimmed SelfArx template: intro + paper ref, recovery QR/link, the 4 main plots with captions, full
  parameter table) + new `app/cgi-bin/designer-summary.pl` (finds the session's first run, rsvg-converts
  pm/sa/fl/af SVGs to PDF, builds a Unicode-sanitised parameter table from parameters.json, fills tokens,
  compiles twice for the longtable). Tested on session fc6d → 200 application/pdf, 50 param rows, 4
  plots, 0 LaTeX errors. Sample at `_pdftest/overview-sample.pdf`. 7 commits total. Files cp'd into the
  running container; the `full` image rebuild (on deploy) bakes them.
- **2026-06-06** — **Overview made per-run** (was per-session). The detailed report offers one download
  per calculation run; the overview now matches — keyed by run uuid (reads `results/<uuid>/details.json`,
  derives the session, writes to `results/<uuid>/overview/`). Frontend: `overviewDL.data = rDataArray`
  (same titled per-run array as the reports). ZIP stays one-per-session. So: N runs → N reports + N
  overviews + 1 ZIP. Tested per-run uuid → 200 application/pdf, 0 errors. 8 commits total.
- **2026-06-06** — **Friendly download filenames.** report/overview/data CGIs now STREAM the file
  through the CGI with `Content-Disposition` (supersedes the relative-redirect approach) named
  `<recoverycode>_<identifier>_<shortuuid>.<ext>` (e.g. `fc6d-1852-3728_report_D430DFC6.pdf`,
  `..._overview_...`, `fc6d-1852-3728_data.zip`). The long Data::UUID run id is shortened to its first
  8 chars for the label only (the full uuid stays the folder name / URL key). Subtitle shows the same
  name (`d.fname`); report/data size labels corrected to ~2 MB. PDFs use `inline`, the zip
  `attachment`. 11 commits total.
- **2026-06-06** — **Deploy (Phase D) in progress on the Ubuntu server.** Hit two snags: (1) disk was
  100% full — the host's COSMOS `cosmos-project_openc3-tsdb-v` volume was 445 GB (no retention cap);
  freed by deleting it. (2) Container wouldn't start: `read-only file system` creating the volume
  mountpoints — the host Docker uses the **containerd image store** (path `…/rootfs/overlayfs/…`),
  which drops EMPTY dirs from a layer, so the mkdir'd `results/sessions/templates-sessions/
  identification` mount targets were missing at runtime. Fixed by `touch …/.keep` in each (commit).
  Also note: `docker compose up` builds compose's `build.target` (=`base`) and just TAGS it
  `designer:${TARGET}` — so to get the real LaTeX image you must `docker build --target full` explicitly
  (the env var only sets the tag, not the build target).
- **2026-06-06** — **ROOT CAUSE of the "read-only file system" container-start error: the dev override.**
  `docker-compose.override.yml` auto-loads and bind-mounts `app/web` READ-ONLY over
  `/app/htdocs/designer`; the results/sessions named volumes mount NESTED inside it, and a fresh server
  clone has no `app/web/results` dir, so Docker can't create the nested mountpoint -> EROFS. (NOT the
  containerd store, NOT empty dirs — the `.keep` was a red herring, though harmless.) The diagnosis that
  cracked it: `docker run -v vol:/app/htdocs/designer/results ... echo OK` worked but `docker compose up`
  didn't -> the only difference was the auto-loaded override. **Fix:** renamed it to
  `docker-compose.dev.yml` (opt-in via `-f docker-compose.yml -f docker-compose.dev.yml`), so plain
  `docker compose up` on a server uses only the base file. (Server: Docker 29.4.0, storage driver
  `overlayfs` = containerd image store — a distraction, not the cause.)
- Gotcha: the dev override bind-mounts `app/web` READ-ONLY over `/app/htdocs/designer`, which blocks
  writing `templates/sessions/...` — for backend/report testing, bring up with
  `docker compose -f docker-compose.yml up -d` (no override).
- **2026-06-06** — **Fixed download redirects.** User hit "Not Found" on report PDF and data ZIP:
  `designer-report.pl`/`designer-data.pl` redirected to absolute `http://spacegravity.org/...`, which
  404s anywhere but the live domain. Made those `Location:` headers root-relative (`/designer/...`).
  Bonus: a relative Location makes Apache serve the file INLINE (200) instead of an external 302.
  Verified on the running container with the user's real session: report → 200 application/pdf 2MB,
  data → 200 application/zip 2MB. Recovery/QR `#rc=` permalinks + paper hrefs stay absolute (unchanged).
  Patched the running container via `docker cp` (works now in the browser); image rebuild on deploy
  bakes it. Git: 3 commits now (containerize, verbatimbox, relative-redirect).
- **2026-06-06** — **About page → v1.2.** Bumped version to 1.2 + history entry; removed the German
  imprint (§5 TMG address/phone) and all German-law wording (author now in Florida); rewrote
  disclaimer (as-is/no-warranty), copyright (MIT + paper citation + repo link), and privacy statement
  (reflects actual data handling: voluntary personal data, recovery-code access, server logs, 3rd-party
  resources). Fixed stale "publication under preparation". Caveat told to user: good-faith text, not
  legal advice; GDPR may still apply to EU visitors. 4 commits total. (NOTE for future: the beta
  banner at index.html:~791 still says "beta version" — left as-is, not in scope.)

## Gotchas / watch-items
- **Polymer 0.3.4** — RESOLVED (2026-06-06): the 2014 `platform.js` still polyfills HTML Imports; the
  UI renders fine in a current browser, no extra polyfill needed. The only frontend fix required was
  the `jQuery.browser ||= {}` shim (see B). If a future browser drops support, fallback is to load
  `webcomponentsjs`/`HTMLImports.min.js` before `platform.js`.
- **CRLF / exec bit** — Perl scripts must be LF (a CRLF in `#!/usr/bin/perl` breaks CGI) and
  executable. Handled by `dos2unix` + `chmod +x` in the Docker build. Bind-mounting Perl from Windows
  is dev-only for this reason.
- **Math::Cephes / Imager::QRCode** — likely need `cpanm` + dev headers (`libqrencode-dev`) rather
  than clean apt packages; expect a build iteration.
- **Path codemod single-quote edge case** — `$ENV{APP_ROOT}` won't interpolate inside single-quoted
  Perl strings; after the sed pass, grep for `'[^']*\$ENV\{APP_ROOT\}` and fix by hand.
- **gnuplot `jsdir`** — was `http://spacegravity.org/designer/gnuplot.js/`; now root-relative
  `/designer/gnuplot.js/` (loads locally + under HTTPS). All OTHER spacegravity.org URLs are kept
  literal on purpose (old-paper / QR-recovery compatibility) — do not "fix" them.
- **gnuplot-nox terminals** — confirm `svg` + `pngcairo` are present (they are in Debian's
  `gnuplot-nox`); if a script needs an X-only terminal, switch to `gnuplot`.
- **PDF report needs Phase C** — it will fail on the `base` image (no LaTeX); that's expected.
