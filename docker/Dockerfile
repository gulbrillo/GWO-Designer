# GWO "Designer" — containerized legacy Perl-CGI app.
#
# Layer strategy: the heavy, stable pieces (system packages, CPAN modules, and the
# ~5GB texlive-full) live in stages that DO NOT depend on the application files, so
# editing app code never busts the texlive layer / forces a re-download.
#
#   system  : Apache + Perl + CPAN deps + gnuplot/rsvg/ImageMagick/zip   (no LaTeX, no app)
#   texlive : system + texlive-full                                      (no app)
#   base    : system  + app   -> everything except PDF reports           (default target)
#   full    : texlive + app   -> PDF reports work too
#
# Build base (small, fast):   docker build -f docker/Dockerfile --target base -t designer:base ..
# Build full (adds ~5GB TeX): docker build -f docker/Dockerfile --target full -t designer:full ..
# (docker-compose selects the target; default is base.)

# ===========================================================================
# system — stable heavy dependencies. No application code, no LaTeX.
# ===========================================================================
FROM debian:bookworm-slim AS system

ARG APP_ROOT=/app
ENV APP_ROOT=${APP_ROOT} \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Web/CGI + build toolchain for the CPAN modules that aren't packaged; Perl deps via
# apt where available (precompiled); graphics/report tools the scripts shell out to.
RUN apt-get update && apt-get install -y --no-install-recommends \
        apache2 \
        perl cpanminus build-essential \
        dos2unix locales gettext-base ca-certificates \
        libcgi-pm-perl libdata-uuid-perl libjson-parse-perl \
        libsvg-perl libimager-perl pdl \
        gnuplot-nox librsvg2-bin imagemagick ghostscript zip \
        fonts-roboto fonts-roboto-unhinted \
    && rm -rf /var/lib/apt/lists/*

# CPAN modules not in Debian (need the build toolchain above).
RUN cpanm --notest Math::Cephes Imager::QRCode

# Locale for Perl (use utf8), gnuplot (set encoding utf8) and LaTeX.
RUN sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen

# Apache modules: cgid (run CGI), rewrite (.htaccess), headers.
RUN a2enmod cgid rewrite headers && (a2dismod -f autoindex 2>/dev/null || true)

# Apache wiring (vhost template + entrypoint). Stable, so it lives in `system`.
COPY docker/000-designer.conf /etc/apache2/sites-available/000-designer.conf.tmpl
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN dos2unix /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh \
    && a2dissite 000-default \
    && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# ===========================================================================
# texlive — system + full TeX Live. Depends ONLY on `system`, never on the app,
# so app edits don't trigger a 5GB re-download.
# ===========================================================================
FROM system AS texlive
RUN apt-get update && apt-get install -y --no-install-recommends texlive-full \
    && rm -rf /var/lib/apt/lists/*

# ===========================================================================
# Application install. Identical in `base` and `full` — KEEP THE TWO IN SYNC.
# (Dockerfile can't share a RUN block across stages.)
#
# Layout mirrors the old server's sub-paths, rooted at $APP_ROOT (see codemod):
#   root     -> $APP_ROOT/htdocs            (spacegravity.org landing page at /)
#   web      -> $APP_ROOT/htdocs/designer   (the app, served at /designer/)
#   cgi-bin  -> $APP_ROOT/cgi-bin           (ScriptAlias /cgi-bin/)
#   latex    -> $APP_ROOT/designer/latexelements
#   presets  -> $APP_ROOT/designer/plotelements
# ===========================================================================

# ----- base target: no LaTeX -----
FROM system AS base
COPY app/root    ${APP_ROOT}/htdocs
COPY app/web     ${APP_ROOT}/htdocs/designer
COPY app/cgi-bin ${APP_ROOT}/cgi-bin
COPY app/latex   ${APP_ROOT}/designer/latexelements
COPY app/presets ${APP_ROOT}/designer/plotelements
# Normalize line endings (Windows checkout) + make CGI executable (a CRLF in the
# #! line silently breaks CGI); create writable runtime dirs; compile-check scripts.
RUN dos2unix ${APP_ROOT}/cgi-bin/*.pl ${APP_ROOT}/cgi-bin/head.htm \
             ${APP_ROOT}/designer/latexelements/*.tex \
             ${APP_ROOT}/designer/latexelements/*.cls 2>/dev/null || true; \
    chmod +x ${APP_ROOT}/cgi-bin/*.pl; \
    mkdir -p ${APP_ROOT}/htdocs/designer/results \
             ${APP_ROOT}/htdocs/designer/sessions \
             ${APP_ROOT}/htdocs/designer/templates/sessions \
             ${APP_ROOT}/designer/identification; \
    chown -R www-data:www-data ${APP_ROOT}; \
    set -e; for f in ${APP_ROOT}/cgi-bin/*.pl; do echo "perl -c $f"; perl -c "$f"; done

# ----- full target: same app, on top of texlive -----
FROM texlive AS full
COPY app/root    ${APP_ROOT}/htdocs
COPY app/web     ${APP_ROOT}/htdocs/designer
COPY app/cgi-bin ${APP_ROOT}/cgi-bin
COPY app/latex   ${APP_ROOT}/designer/latexelements
COPY app/presets ${APP_ROOT}/designer/plotelements
RUN dos2unix ${APP_ROOT}/cgi-bin/*.pl ${APP_ROOT}/cgi-bin/head.htm \
             ${APP_ROOT}/designer/latexelements/*.tex \
             ${APP_ROOT}/designer/latexelements/*.cls 2>/dev/null || true; \
    chmod +x ${APP_ROOT}/cgi-bin/*.pl; \
    mkdir -p ${APP_ROOT}/htdocs/designer/results \
             ${APP_ROOT}/htdocs/designer/sessions \
             ${APP_ROOT}/htdocs/designer/templates/sessions \
             ${APP_ROOT}/designer/identification; \
    chown -R www-data:www-data ${APP_ROOT}; \
    set -e; for f in ${APP_ROOT}/cgi-bin/*.pl; do echo "perl -c $f"; perl -c "$f"; done
