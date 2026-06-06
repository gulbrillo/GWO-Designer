# Deploying GWO Designer

The app ships as a single self-contained Docker image (its own Apache runs the Perl CGI; Perl,
gnuplot, LaTeX, etc. all live inside). Nothing but Docker + a reverse proxy is needed on the host.

Two image targets (see `Dockerfile`):
- **`base`** — everything except LaTeX. Frontend, plots, QR, ZIP export all work; PDF report does not.
- **`full`** — `base` + `texlive-full`, so PDF reports work too. **Use `full` in production.**

---

## Local (Windows / Docker Desktop)

```powershell
cd docker
docker compose up --build           # base target by default -> http://localhost:8080/designer/
```

For PDF reports locally, build/run the full target:
```powershell
docker build -f docker/Dockerfile --target full -t designer:full ..
$env:TARGET="full"; docker compose up -d
```

To live-edit the STATIC frontend (HTML/CSS/JS) without rebuilding, opt into the dev overlay:
`docker compose -f docker-compose.yml -f docker-compose.dev.yml up`. It is dev-only and NOT
auto-loaded (it bind-mounts `app/web` read-only, which conflicts with the data volumes on a fresh
server clone). Perl/LaTeX changes always need a rebuild.

---

## Production (Ubuntu server, behind the existing Apache reverse proxy)

The server already runs another container on host **:8080** via Apache `mod_proxy`. Designer publishes
on a **different** host port (8081) and gets its own vhost.

### 1. Copy the repo to the server and build the `full` image
```bash
cd /path/to/Designer
docker build -f docker/Dockerfile --target full -t designer:full .
```
(`texlive-full` makes this a long, ~5GB build. Do it once; the layer caches.)

### 2. Run the container on host port 8081, bound to localhost
The compose port is `${HOST_PORT:-8080}:80`. Override it and point compose at the `full` image:
```bash
cd docker
HOST_PORT=8081 TARGET=full docker compose up -d
```
> For defense in depth, bind only to localhost so nothing but the local proxy can reach it. Either set
> the compose port to `"127.0.0.1:${HOST_PORT:-8080}:80"`, or rely on the host firewall. The reverse
> proxy connects to `127.0.0.1:8081`.

### 3. Add an Apache vhost for spacegravity.org (HTTPS terminates here)
Enable the modules, then create `/etc/apache2/sites-available/spacegravity.org.conf` (serves both
`spacegravity.org` and `www.spacegravity.org`):
```bash
sudo a2enmod proxy proxy_http ssl rewrite headers
```
```apache
<VirtualHost *:80>
    ServerName spacegravity.org
    ServerAlias www.spacegravity.org
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =www.spacegravity.org [OR]
    RewriteCond %{SERVER_NAME} =spacegravity.org
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost _default_:443>
    ServerName spacegravity.org
    ServerAlias www.spacegravity.org

    ProxyPreserveHost On
    ProxyPass        / http://127.0.0.1:8081/
    ProxyPassReverse / http://127.0.0.1:8081/

    ErrorLog  ${APACHE_LOG_DIR}/spacegravity.org_error.log
    CustomLog ${APACHE_LOG_DIR}/spacegravity.org_access.log combined

    SSLEngine on
    # filled in by certbot (below); add by hand only if self-managing certs:
    # SSLCertificateFile    /etc/letsencrypt/live/spacegravity.org/fullchain.pem
    # SSLCertificateKeyFile /etc/letsencrypt/live/spacegravity.org/privkey.pem
</VirtualHost>
</IfModule>
```
No WebSocket rewrite is needed (this app doesn't use WebSockets). Then:
```bash
sudo a2ensite spacegravity.org && sudo apache2ctl configtest && sudo systemctl reload apache2
sudo certbot --apache -d spacegravity.org -d www.spacegravity.org
```

Visiting `https://spacegravity.org/` → the landing page; the app is at `/designer/`. Old-paper
recovery permalinks `https://spacegravity.org/designer/#rc=<code>` resolve through the same proxy.

---

## Data persistence & backup

Generated data lives in named volumes (survives restarts/upgrades):
`gwo-designer_results`, `gwo-designer_sessions`, `gwo-designer_tmpl_sessions`,
`gwo-designer_identification`.

Back them up, e.g.:
```bash
docker run --rm -v gwo-designer_sessions:/v -v "$PWD":/b alpine \
    tar czf /b/sessions-backup.tar.gz -C /v .
```
(Repeat per volume.) To seed from the old server's data, restore into the matching volume the same way.

## Upgrades
```bash
git pull            # or copy new code
docker build -f docker/Dockerfile --target full -t designer:full .
cd docker && HOST_PORT=8081 TARGET=full docker compose up -d   # recreates container, keeps volumes
```
