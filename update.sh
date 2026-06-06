#!/usr/bin/env bash
#
# update.sh - pull the latest code and redeploy the GWO Designer container.
#
#   cd /var/www/docker/gwo-designer
#   ./update.sh                      # or:  bash update.sh
#
# Force-syncs the checkout to the git remote (so a stray local edit can't block the
# update), rebuilds the full image, and restarts the container. Data volumes are kept.
#
# Override the defaults inline if needed, e.g.:   HOST_PORT=9000 ./update.sh
set -euo pipefail

HOST_PORT="${HOST_PORT:-8081}"     # host port the container is published on
TARGET="${TARGET:-full}"           # 'full' (with LaTeX/PDF) or 'base' (no LaTeX)

cd "$(dirname "$0")"               # repo root (where this script lives)
REPO_ROOT="$(pwd)"

echo "==> [1/4] Syncing code to the git remote"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git fetch origin "$BRANCH"
git reset --hard "origin/$BRANCH"  # discards local changes; makes the checkout mirror the repo

echo "==> [2/4] Building image (target=$TARGET)"
docker build -f docker/Dockerfile --target "$TARGET" -t "designer:$TARGET" "$REPO_ROOT"

echo "==> [3/4] Restarting container (host port=$HOST_PORT)"
cd "$REPO_ROOT/docker"
# -f docker-compose.yml = production only (never the dev overlay)
HOST_PORT="$HOST_PORT" TARGET="$TARGET" docker compose -f docker-compose.yml up -d

echo "==> [4/4] Status + health check"
HOST_PORT="$HOST_PORT" TARGET="$TARGET" docker compose -f docker-compose.yml ps
code="$(curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HOST_PORT}/designer/" || true)"
echo "    http://127.0.0.1:${HOST_PORT}/designer/  ->  HTTP ${code:-no-response}"
if [ "$code" = "200" ]; then
  echo "==> Update complete."
else
  echo "==> WARNING: app did not return 200 - check 'cd docker && docker compose logs --tail=50'"
fi
