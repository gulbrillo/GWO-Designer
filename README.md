# GWO Designer

**Gravitational Wave Observatory Designer** — an interactive web tool to explore the sensitivity
limits of space-borne laser-interferometric gravitational-wave detectors (LISA-like missions). You
enter mission/instrument parameters and it computes the noise budget and strain sensitivity, draws
interactive plots, and generates a fully documented PDF report.

It is the tool behind the paper *Barke et al, "Towards a gravitational wave observatory designer:
sensitivity limits of spaceborne detectors", 2015 Class. Quantum Grav. **32** 095004*
([doi:10.1088/0264-9381/32/9/095004](https://doi.org/10.1088/0264-9381/32/9/095004)).

The stack is a Polymer web frontend, a Perl CGI backend, gnuplot for the interactive SVG plots, and
LaTeX for the PDF reports — all packaged into a single Docker image.

## Run locally

```bash
cd docker
docker compose up --build        # http://localhost:8080/designer/
```

That builds the `base` image (no LaTeX). For PDF report generation, build the `full` image too:

```bash
docker build -f docker/Dockerfile --target full -t designer:full ..
TARGET=full docker compose up -d
```

## Install on an Ubuntu + Apache server

The whole app (Apache + Perl + gnuplot + LaTeX) runs inside the container. The host's Apache is used
only as an HTTPS reverse proxy in front of it — it needs no Perl/LaTeX/etc., just the proxy modules.
The container listens on a local port (e.g. `8081`); the host Apache terminates TLS for
`spacegravity.org` and forwards requests to it.

The steps below assume a fresh Ubuntu server with Apache already serving other sites (as is the case
here — another app already uses port 8080, so this one uses **8081**; pick any free port).

### 1. Install Docker

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
# optional: run docker without sudo (log out/in afterwards)
sudo usermod -aG docker "$USER"
```

### 2. Clone the repository

```bash
sudo mkdir -p /opt && cd /opt
sudo git clone https://github.com/gulbrillo/gwo-designer.git
cd gwo-designer
```

### 3. Build the image and start the container

Build the `full` image (includes TeX Live — this is a large, ~5 GB download, done once) and start it
on host port 8081, bound to localhost so only the local Apache proxy can reach it:

```bash
docker build -f docker/Dockerfile --target full -t designer:full .
cd docker
HOST_PORT=8081 TARGET=full docker compose up -d
```

Quick local check (before wiring up Apache):

```bash
curl -I http://127.0.0.1:8081/designer/      # expect HTTP 200
```

The container restarts automatically on boot/crash (`restart: unless-stopped`). Generated reports and
sessions persist in Docker named volumes (see [docker/DEPLOY.md](docker/DEPLOY.md) for backups).

> To bind strictly to localhost, set the published port to `127.0.0.1:8081:80` in
> `docker/docker-compose.yml`, or rely on the host firewall.

### 4. Enable the Apache proxy modules

```bash
sudo a2enmod proxy proxy_http ssl rewrite headers
sudo systemctl reload apache2
```

### 5. Create the Apache site

Create `/etc/apache2/sites-available/spacegravity.org.conf`. This serves both `spacegravity.org` and
`www.spacegravity.org`, redirects HTTP→HTTPS, and proxies HTTPS traffic to the container on `:8081`:

```apache
<VirtualHost *:80>
    ServerName spacegravity.org
    ServerAlias www.spacegravity.org
    # Redirect all HTTP to HTTPS
    RewriteEngine on
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost _default_:443>
    ServerName spacegravity.org
    ServerAlias www.spacegravity.org
    ServerAdmin webmaster@spacegravity.org

    ProxyPreserveHost On
    ProxyPass        / http://127.0.0.1:8081/
    ProxyPassReverse / http://127.0.0.1:8081/

    ErrorLog  ${APACHE_LOG_DIR}/spacegravity.org_error.log
    CustomLog ${APACHE_LOG_DIR}/spacegravity.org_access.log combined

    SSLEngine on
    # These two lines are filled in automatically by certbot (step 6);
    # add them by hand only if you manage certificates yourself:
    # SSLCertificateFile    /etc/letsencrypt/live/spacegravity.org/fullchain.pem
    # SSLCertificateKeyFile /etc/letsencrypt/live/spacegravity.org/privkey.pem
</VirtualHost>
</IfModule>
```

> This app does **not** use WebSockets, so (unlike some setups) no `ws://` rewrite is needed — a plain
> `ProxyPass /` is enough. `ProxyPreserveHost On` keeps the `spacegravity.org` host header so the
> app's own links and the `#rc=` recovery permalinks resolve correctly.

Enable the site:

```bash
sudo a2ensite spacegravity.org
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### 6. Obtain the TLS certificate

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d spacegravity.org -d www.spacegravity.org
```

Certbot fills in the `SSLCertificate*` lines, sets up auto-renewal, and reloads Apache. Then browse to
**https://spacegravity.org/** — the landing page loads, and the app is at **/designer/**.

### Updating later

```bash
cd /opt/gwo-designer
git pull
docker build -f docker/Dockerfile --target full -t designer:full .
cd docker && HOST_PORT=8081 TARGET=full docker compose up -d   # recreates the container, keeps data
```

See [docker/DEPLOY.md](docker/DEPLOY.md) for data-volume backups and other operational notes.

## License & citation

Code is released under the [MIT License](LICENSE). The underlying paper is published open access under
CC BY 3.0 — if you use the tool or its output in published work, please cite it (see
[CITATION.cff](CITATION.cff)). Bundled third-party components keep their own licenses (jQuery — MIT,
Polymer/Paper — BSD, gnuplot — gnuplot license, LaTeX — LPPL).
