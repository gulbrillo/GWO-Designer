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

Put the host's existing Apache in front as a reverse proxy (it only needs `mod_proxy`/`mod_proxy_http`
/`mod_ssl`; all of Perl, gnuplot and LaTeX live inside the container). Install Docker
(`sudo apt install docker.io docker-compose-v2`), copy this repo to the server, then build and run the
container on a free host port — e.g. 8081 if 8080 is already taken:

```bash
docker build -f docker/Dockerfile --target full -t designer:full .
cd docker && HOST_PORT=8081 TARGET=full docker compose up -d
```

Then add an Apache vhost for your domain that terminates HTTPS and proxies to the container:

```apache
<VirtualHost *:443>
    ServerName spacegravity.org
    SSLEngine on
    SSLCertificateFile    /etc/letsencrypt/live/spacegravity.org/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/spacegravity.org/privkey.pem
    ProxyPreserveHost On
    ProxyPass        / http://127.0.0.1:8081/
    ProxyPassReverse / http://127.0.0.1:8081/
</VirtualHost>
```

`a2ensite` it, `apache2ctl configtest`, reload Apache, and the app is live. See
[docker/DEPLOY.md](docker/DEPLOY.md) for the full version (TLS via certbot, data-volume backups,
upgrades).

## License & citation

Code is released under the [MIT License](LICENSE). The underlying paper is published open access under
CC BY 3.0 — if you use the tool or its output in published work, please cite it (see
[CITATION.cff](CITATION.cff)). Bundled third-party components keep their own licenses (jQuery — MIT,
Polymer/Paper — BSD, gnuplot — gnuplot license, LaTeX — LPPL).
