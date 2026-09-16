# syntax=docker/dockerfile:1
ARG GO_VERSION={{ go_version }}
FROM golang:${GO_VERSION}-bookworm AS builder

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

FROM gcr.io/distroless/static-debian12:nonroot

ARG VERSION=dev
ARG GIT_COMMIT=unknown

LABEL org.opencontainers.image.source="https://github.com/{{ github_owner }}/{{ project_name }}"
LABEL org.opencontainers.image.description="{{ description }}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"

COPY --from=builder /out/server /server

USER nonroot:nonroot
EXPOSE {{ port }}
ENTRYPOINT ["/server"]
