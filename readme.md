<h1 align="center">stunnel<br />
<div align="center">
<a href="https://github.com/dockur/stunnel"><img src="https://raw.githubusercontent.com/dockur/stunnel/master/.github/logo.png" title="Logo" style="max-width:100%;" width="128" /></a>
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Package]][pkg_url]
[![Pulls]][hub_url]

</div></h1>

Docker container of [stunnel](https://www.stunnel.org/), a proxy designed to add TLS encryption functionality to existing clients and servers without any changes in the programs' code.

## Usage  🐳

##### Via Docker Compose:

```yaml
services:
  stunnel:
    hostname: stunnel
    image: dockurr/stunnel
    container_name: stunnel
    environment:
      LISTEN_PORT: "853"
      CONNECT_PORT: "53"
      CONNECT_HOST: "1.1.1.1"
    volumes:
      - ./privkey.pem:/private.pem
      - ./certificate.pem:/cert.pem
    ports:
      - 853:853
    restart: always
```

##### Via Docker CLI:

```bash
docker run -it --rm --name stunnel -p 853:853 -e "LISTEN_PORT=853" -e "CONNECT_PORT=53" -e "CONNECT_HOST=1.1.1.1" -v "${PWD:-.}/privkey.pem:/private.pem" -v "${PWD:-.}/certificate.pem:/cert.pem" dockurr/stunnel
```

## Configuration ⚙️

### How do I select the mode?

Stunnel can operate in two modes. The __server mode__ works as a transparent proxy in front of a server, so that clients that connect negotiate an TLS connection while the traffic forwarded to the destination server stays unencrypted.

The __client mode__ does the opposite thing. Clients connecting to stunnel running in client mode can establish a plain text connection and stunnel will create an encrypted TLS tunnel to the destination server.

By default it will run in server mode, but to switch modes you can set the `CLIENT` variable like this:

```yaml
environment:
  CLIENT: "yes"
```

### How do I select the certificate?

When running in server mode, a certificate is needed. By default, a self-signed certificate will be generated, but you can supply your own `.pem` certificates by adding:

```yaml
volumes:
  - ./privkey.pem:/private.pem
  - ./certificate.pem:/cert.pem
```

Instead of `.pem` files you can also use `.crt`/`.key` files:

```yaml
volumes:
  - ./privkey.key:/private.key
  - ./certificate.crt:/cert.crt
```

### How do I modify the permissions?

You can set `UID` and `GID` environment variables to change the user and group ID.

```yaml
environment:
  UID: "1002"
  GID: "1005"
```

### How do I modify other settings?

If you need more advanced features, you can completely override the default configuration by binding your custom config to the container like this:

```yaml
volumes:
  - ./custom.conf:/stunnel.conf
```

## Stars 🌟
[![Stars](https://starchart.cc/dockur/stunnel.svg?variant=adaptive)](https://starchart.cc/dockur/stunnel)

[build_url]: https://github.com/dockur/stunnel
[hub_url]: https://hub.docker.com/r/dockurr/stunnel
[tag_url]: https://hub.docker.com/r/dockurr/stunnel/tags
[pkg_url]: https://github.com/dockur/stunnel/pkgs/container/stunnel

[Build]: https://github.com/dockur/stunnel/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/stunnel/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/stunnel.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/stunnel/latest?arch=amd64&sort=semver&color=066da5
[Package]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fipitio.github.io%2Fbackage%2Fdockur%2Fstunnel%2Fstunnel.json&query=%24.downloads&logo=github&style=flat&color=066da5&label=pulls
