# goose-base-image

Prebuilt [goose](https://github.com/pressly/goose) migration runner for the Go
services. Service repos put their SQL + `entrypoint.sh` on top of it instead of
each building goose themselves.

Image: `ghcr.io/nvision-x/goose-base-image`

## Tags

| Tag | Meaning |
|---|---|
| `v3` | latest goose 3.x, rebuilt weekly — what services should use |
| `v3.29` / `v3.29.0` | exact goose version, also rebuilt weekly |
| `v3.29.0-YYYYMMDD` | one build, never moves |
| `sha-<git sha>` | one build, never moves |

Every tag is rebuilt on Monday 02:00 UTC and on every push to `main`, so the
Go toolchain and alpine packages are current without touching any service repo.

## Use it in a service

`Dockerfile.migrations.alpine`:

```dockerfile
FROM ghcr.io/nvision-x/goose-base-image:v3

COPY migrations/ ./
```

The layout is the contract, not a setting: a service repo keeps its SQL and
`entrypoint.sh` under `migrations/` and never names the path in its Dockerfile.

What the base provides:

- `goose` on `PATH`, static binary
- `bash` (the entrypoints are `#!/bin/bash`)
- `WORKDIR /migrations` and `GOOSE_MIGRATION_DIR=/migrations`
- `ENTRYPOINT ["bash", "/migrations/entrypoint.sh"]`, so the file's exec bit doesn't matter
- user `goose` (uid 1000); the image does not set `USER`, the pod `securityContext` does

## Bumping

Everything is an `ARG` at the top of the `Dockerfile`:

```dockerfile
ARG GO_VERSION=1.27.2
ARG ALPINE_VERSION=3.24
ARG GOOSE_VERSION=v3.29.0
```

`GOOSE_VERSION` is the image version: the workflow derives `v3`, `v3.29` and
`v3.29.0` from it. Dependabot keeps `golang` and `alpine` moving; goose itself
is bumped by editing the ARG.

## Local check

```sh
docker build -t goose-base:test .
docker run --rm --entrypoint goose goose-base:test --version
```
