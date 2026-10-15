# syntax=docker/dockerfile:1
ARG GO_VERSION=1.27.2
ARG ALPINE_VERSION=3.24
ARG GOOSE_VERSION=v3.29.0

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS build
ARG GOOSE_VERSION
ARG TARGETOS
ARG TARGETARCH
# cross-compiled `go install` lands in /go/bin/<os>_<arch>/, native in /go/bin/
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go install -trimpath -ldflags="-s -w" "github.com/pressly/goose/v3/cmd/goose@${GOOSE_VERSION}" \
    && mkdir -p /out \
    && cp "$(find /go/bin -type f -name goose | head -n1)" /out/goose

FROM alpine:${ALPINE_VERSION}
# entrypoint.sh in every service repo is a bash script; alpine ships only busybox sh
RUN apk upgrade --no-cache \
    && apk add --no-cache bash ca-certificates tzdata \
    && addgroup -g 1000 -S goose \
    && adduser -u 1000 -S -G goose -h /home/goose -s /sbin/nologin goose
COPY --from=build /out/goose /bin/goose

# service images ADD their migrations/ here; goose reads from cwd (and from
# GOOSE_MIGRATION_DIR for entrypoints that run it from elsewhere)
WORKDIR /migrations
ENV GOOSE_MIGRATION_DIR=/migrations
ENTRYPOINT ["/migrations/entrypoint.sh"]
