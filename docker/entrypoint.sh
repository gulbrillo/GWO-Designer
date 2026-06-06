#!/usr/bin/env bash
# Container entrypoint: render the vhost, ensure mounted volumes are writable, run Apache.
set -e

: "${APP_ROOT:=/app}"
export APP_ROOT

# Render the vhost template. Substitute ONLY $APP_ROOT so Apache's own ${APACHE_LOG_DIR}
# (and friends) survive for Apache to expand.
envsubst '${APP_ROOT}' \
    < /etc/apache2/sites-available/000-designer.conf.tmpl \
    > /etc/apache2/sites-available/000-designer.conf
a2ensite 000-designer >/dev/null

# Named volumes mount as root-owned the first time; make the writable dirs www-data's.
for d in \
    "$APP_ROOT/htdocs/designer/results" \
    "$APP_ROOT/htdocs/designer/sessions" \
    "$APP_ROOT/htdocs/designer/templates/sessions" \
    "$APP_ROOT/designer/identification"; do
    mkdir -p "$d"
    chown www-data:www-data "$d" 2>/dev/null || true
done

# Apache in the foreground (PID 1).
# shellcheck disable=SC1091
source /etc/apache2/envvars
# mod_cgid binds a unix socket under <run>/socks/ — that subdir must exist.
mkdir -p "${APACHE_RUN_DIR:-/var/run/apache2}/socks" "${APACHE_LOCK_DIR:-/var/lock/apache2}"
rm -f "${APACHE_PID_FILE:-/var/run/apache2/apache2.pid}"
exec apache2 -D FOREGROUND
