<p align="center"><a href="https://github.com/k44sh/stunnel" target="_blank"><img src="https://raw.githubusercontent.com/k44sh/stunnel/main/.screens/stunnel.png"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/k44sh/stunnel/tags?page=1&ordering=last_updated"><img src="https://img.shields.io:/docker/v/k44sh/stunnel/latest?logo=docker" alt="Latest Version"></a>
  <a href="https://hub.docker.com/r/k44sh/stunnel/"><img src="https://img.shields.io:/docker/image-size/k44sh/stunnel?logo=docker" alt="Docker Size"></a>
  <a href="https://hub.docker.com/r/k44sh/stunnel/"><img src="https://img.shields.io:/docker/pulls/k44sh/stunnel?logo=docker" alt="Docker Pulls"></a>
  <a href="https://github.com/k44sh/stunnel/actions?workflow=build"><img src="https://img.shields.io/github/actions/workflow/status/k44sh/stunnel/build.yml" alt="Build Status"></a>
</p>

## About

[Stunnel](https://stunnel.org/) Docker image based on [Alpine Linux](https://www.alpinelinux.org/).<br/>
___

## Features

* Run as non-root user
* Multi-platform image

## Supported platforms

* linux/amd64
* linux/arm64
* linux/arm/v7

## Usage

This docker can be used with an existing `stunnel` configuration using a volume (`/etc/stunnel`).

Otherwise you can just adapt the environment variables to run a simple configuration.

### Docker Compose

Docker compose is the recommended way to run this image. Edit the compose file with your preferences and run the following command:

```shell
git clone https://github.com/k44sh/stunnel.git && cd stunnel
mkdir stunnel
docker compose up -d
docker compose logs -f
```

### Command line

You can also use the following minimal command:

```shell
docker run --rm -d --name stunnel -p 389:389 \
-e CONNECT_HOST=ldap.google.com -e CONNECT_PORT=636 \
-v $(pwd)/stunnel.crt:/etc/stunnel/stunnel.crt \
-v $(pwd)/stunnel.key:/etc/stunnel/stunnel.key \
k44sh/stunnel:latest
```

### Environment variables

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: User id (default `1000`)
* `PGID`: User group id (default `1000`)
* `LISTEN_HOST`: Listening server address (default `0.0.0.0`)
* `LISTEN_PORT`: Listening server port (default `389`)
* `CONNECT_HOST`: Remote server address (default `ldap.google.com`)
* `CONNECT_PORT`: Remote server port (default `636`)
* `HEALTHCHECK`: Host for healthcheck (default `127.0.0.1`)

### Upgrade

To upgrade, pull the newer image and launch the container:

```shell
docker compose pull
docker compose up -d
```
