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
- `USER 1000:1000` (numeric, so `runAsNonRoot` can verify it)
- label `io.nvisionx.goose.version`, inherited by the service image

## Local check

```sh
docker build -t goose-base:test .
docker run --rm --entrypoint goose goose-base:test --version
```
