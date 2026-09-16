# Developer commands for {{ project_name }}.
.PHONY: help fmt fmt-check vet lint test build verify run clean docker-build docker-push

APP_NAME := {{ project_name }}
GIT_COMMIT := $(shell git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)
VERSION ?= $(GIT_COMMIT)
REGISTRY ?= ghcr.io/{{ github_owner }}
IMAGE := $(REGISTRY)/$(APP_NAME):$(VERSION)
GO := go
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.GitCommit=$(GIT_COMMIT) -w -s"

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z_-]+:.*?## / {printf "%-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

fmt: ## Format Go source files
	gofmt -w .

fmt-check: ## Fail when Go source files need formatting
	@files="$$(gofmt -l .)"; test -z "$$files" || { echo "Unformatted files:"; echo "$$files"; exit 1; }

vet: ## Run go vet
	$(GO) vet ./...

lint: ## Run golangci-lint (must be installed locally)
	golangci-lint run ./...

test: ## Run tests with the race detector
	$(GO) test -race -cover ./...

build: ## Build the service binary
	mkdir -p bin
	$(GO) build $(LDFLAGS) -trimpath -o bin/$(APP_NAME) ./cmd

verify: fmt-check vet lint test build ## Run the local quality gate

run: ## Run the service locally
	$(GO) run ./cmd

docker-build: ## Build an immutable-tagged local container image
	docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		-t $(IMAGE) .

docker-push: docker-build ## Push the selected immutable image tag
	docker push $(IMAGE)

clean: ## Remove local build/test artifacts
	rm -rf bin coverage.out
