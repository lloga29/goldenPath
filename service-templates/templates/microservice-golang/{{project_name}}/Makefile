# Makefile para {{ project_name }}
.PHONY: all build test lint run clean docker-build docker-push

# Variables
APP_NAME := {{ project_name }}
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
REGISTRY := ghcr.io/org
IMAGE := $(REGISTRY)/$(APP_NAME):$(VERSION)

# Go variables
GO := go
GOFLAGS := -v
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.GitCommit=$(GIT_COMMIT) -X main.BuildTime=$(BUILD_TIME) -w -s"

all: lint test build

## build: Compilar el binario
build:
	$(GO) build $(GOFLAGS) $(LDFLAGS) -o bin/$(APP_NAME) ./cmd/main.go

## test: Ejecutar tests
test:
	$(GO) test -v -race -coverprofile=coverage.out ./...

## lint: Ejecutar linters
lint:
	golangci-lint run ./...

## run: Ejecutar localmente
run:
	$(GO) run ./cmd/main.go

## clean: Limpiar artefactos
clean:
	rm -rf bin/ coverage.out

## docker-build: Construir imagen Docker
docker-build:
	docker build -t $(IMAGE) .

## docker-push: Pushear imagen a registry
docker-push: docker-build
	docker push $(IMAGE)

## help: Mostrar ayuda
help:
	@echo "Comandos disponibles:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'
