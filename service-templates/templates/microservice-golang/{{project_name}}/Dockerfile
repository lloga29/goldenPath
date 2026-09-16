# syntax=docker/dockerfile:1
FROM golang:1.26.8-bookworm@sha256:9fdc884aacc3bec89b20ffc69f4bb369c78210e3e4f600387b5128b12c199f81 AS builder

ARG VERSION=dev
ARG GIT_COMMIT=unknown

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-w -s -X main.Version=${VERSION} -X main.GitCommit=${GIT_COMMIT}" \
    -o /out/server \
    ./cmd

FROM gcr.io/distroless/static-debian13:nonroot@sha256:f7f8f729987ad0fdf6b05eeeae94b26e6a0f613bdf46feea7fc40f7bd72953e6

ARG VERSION=dev
ARG GIT_COMMIT=unknown
ARG IMAGE_SOURCE=https://github.com/unknown/unknown
ARG SERVICE_PORT=8080

LABEL org.opencontainers.image.source="${IMAGE_SOURCE}"
LABEL org.opencontainers.image.description="Golden Path Go service"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"

COPY --from=builder /out/server /server

USER nonroot:nonroot
EXPOSE ${SERVICE_PORT}
ENTRYPOINT ["/server"]
