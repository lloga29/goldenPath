# Build stage
FROM golang:1.22-alpine AS builder

ARG VERSION=dev
ARG BUILD_TIME=unknown
ARG GIT_COMMIT=unknown

WORKDIR /app

# Instalar dependencias del sistema
RUN apk add --no-cache git ca-certificates tzdata

# Copiar go.mod y go.sum primero para cache de dependencias
COPY go.mod go.sum* ./
RUN go mod download

# Copiar código fuente
COPY . .

# Build binario estático con información de versión
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME} -X main.GitCommit=${GIT_COMMIT}" \
    -o /app/server \
    ./cmd/main.go

# Runtime stage - usando distroless para mejor seguridad
FROM gcr.io/distroless/static-debian12:nonroot

# Labels para trazabilidad
LABEL org.opencontainers.image.source="https://github.com/org/{{ project_name }}"
LABEL org.opencontainers.image.description="{{ description }}"
LABEL org.opencontainers.image.version="${VERSION}"

# Copiar zona horaria
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copiar certificados CA
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copiar binario
COPY --from=builder /app/server /server

# Usuario no-root (ya definido en nonroot image)
USER nonroot:nonroot

# Puerto de la aplicación
EXPOSE {{ port }}

# Health check nativo de Kubernetes (usar probes en deployment)
# No usar HEALTHCHECK de Docker en Kubernetes

ENTRYPOINT ["/server"]
