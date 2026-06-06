#!/usr/bin/env bash
# codemod.sh — one-time, idempotent rewrite of the old hardcoded absolute filesystem
# paths into a configurable env var, plus the single asset URL that must not stay absolute.
# Safe to re-run (already-rewritten files match nothing). Run from repo root:
#     bash docker/codemod.sh
#
# WHAT CHANGES
#   1. Filesystem root  /var/www/virtual/spacegravity.org  ->  $ENV{APP_ROOT}   (Perl; default /app)
#      ... and the same root -> the token <approot> in report.tex (not Perl), which
#      designer-report.pl expands to $ENV{APP_ROOT} when it streams the template.
#   2. gnuplot interactive-SVG jsdir URL
#         http://spacegravity.org/designer/gnuplot.js/  ->  /designer/gnuplot.js/  (root-relative)
#      Root-relative resolves identically at https://spacegravity.org AND when testing locally,
#      and avoids https mixed-content. It has no bearing on old papers (they never reference it).
#
# WHAT IS DELIBERATELY LEFT ALONE (backward-compat with papers made on the old install)
#   - All other http://spacegravity.org URLs: the recovery/permalink URL in designer-save.pl and
#     every \href in report.tex. The site is being rehosted at spacegravity.org, so these stay.
#
# NOTE: designer-report.pl also needs a one-line code edit (NOT a sed) adding
#   $_ =~ s|<approot>|$ENV{APP_ROOT}|g;
# at the top of its token-substitution foreach loop. That edit is committed in the file.
set -euo pipefail
cd "$(dirname "$0")/.."

OLD_FS='/var/www/virtual/spacegravity.org'
JSDIR_OLD='http://spacegravity.org/designer/gnuplot.js/'
JSDIR_NEW='/designer/gnuplot.js/'

echo ">> Perl: filesystem root -> \$ENV{APP_ROOT}; jsdir URL -> root-relative"
for f in app/cgi-bin/*.pl; do
  sed -i "s|${JSDIR_OLD}|${JSDIR_NEW}|g" "$f"   # specific asset URL
  sed -i "s|${OLD_FS}|\$ENV{APP_ROOT}|g" "$f"   # filesystem root (inside dquote/backtick -> interpolates)
done

echo ">> LaTeX: filesystem root -> <approot> token in report.tex"
sed -i "s|${OLD_FS}|<approot>|g" app/latex/report.tex

echo ">> Verify (hard): no filesystem-root literal remains in cgi-bin/latex"
if grep -rn "${OLD_FS}" app/cgi-bin app/latex; then
  echo "!! Leftover filesystem literal (see above)"; exit 1
fi
echo ">> Verify (hard): jsdir is root-relative in every .pl"
if grep -rn "${JSDIR_OLD}" app/cgi-bin/*.pl; then
  echo "!! jsdir still absolute (see above)"; exit 1
fi
echo ">> Preserved (expected): other spacegravity.org URLs in recovery/permalinks + paper"
grep -rn "http://spacegravity.org" app/cgi-bin/designer-save.pl app/latex/report.tex || true
echo ">> OK: codemod complete"
