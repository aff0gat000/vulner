BINARY := vulner
PKG := github.com/vulner/vulner
CMD := ./cmd/vulner
GOFLAGS := -trimpath
LDFLAGS := -s -w -X main.version=$(shell git describe --tags --always --dirty 2>/dev/null || echo dev)

# Tools
GOLANGCI_LINT := $(shell which golangci-lint 2>/dev/null)
GOSEC := $(shell which gosec 2>/dev/null)
GOVULNCHECK := $(shell which govulncheck 2>/dev/null)

.PHONY: all build clean test test-verbose test-race coverage coverage-html lint sec vulncheck vet fmt check docker run help

all: check build ## Run all checks and build

## ---- Build ----

build: ## Build the binary
	go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o bin/$(BINARY) $(CMD)

build-linux: ## Cross-compile for Linux amd64
	GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o bin/$(BINARY)-linux-amd64 $(CMD)

build-all: ## Build for all platforms
	GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o bin/$(BINARY)-linux-amd64 $(CMD)
	GOOS=linux GOARCH=arm64 go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o bin/$(BINARY)-linux-arm64 $(CMD)
	GOOS=darwin GOARCH=amd64 go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o bin/$(BINARY)-darwin-amd64 $(CMD)
	GOOS=darwin GOARCH=arm64 go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o bin/$(BINARY)-darwin-arm64 $(CMD)

clean: ## Remove build artifacts
	rm -rf bin/ dist/ coverage.out coverage.html gosec-report.* trivy-results.*

## ---- Test ----

test: ## Run tests
	go test ./... -count=1

test-verbose: ## Run tests with verbose output
	go test ./... -v -count=1

test-race: ## Run tests with race detector
	go test ./... -race -count=1

test-short: ## Run only short tests
	go test ./... -short -count=1

coverage: ## Run tests with coverage
	go test ./... -coverprofile=coverage.out -covermode=atomic
	go tool cover -func=coverage.out

coverage-html: coverage ## Generate HTML coverage report
	go tool cover -html=coverage.out -o coverage.html
	@echo "Open coverage.html in your browser"

## ---- Code Quality ----

fmt: ## Format code
	gofmt -s -w .
	goimports -w . 2>/dev/null || true

vet: ## Run go vet
	go vet ./...

lint: ## Run golangci-lint
ifdef GOLANGCI_LINT
	golangci-lint run ./...
else
	@echo "golangci-lint not installed. Run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
	@exit 1
endif

## ---- Security ----

sec: ## Run gosec security scanner
ifdef GOSEC
	gosec -fmt json -out gosec-report.json ./... || true
	gosec ./...
else
	@echo "gosec not installed. Run: go install github.com/securego/gosec/v2/cmd/gosec@latest"
	@exit 1
endif

vulncheck: ## Run govulncheck for known vulnerabilities in dependencies
ifdef GOVULNCHECK
	govulncheck ./...
else
	@echo "govulncheck not installed. Run: go install golang.org/x/vuln/cmd/govulncheck@latest"
	@exit 1
endif

## ---- Checks (local CI pipeline) ----

check: fmt vet test-race ## Run full local CI pipeline (fmt, vet, race tests)
	@echo "All checks passed."

check-full: fmt vet lint sec vulncheck test-race coverage ## Full pipeline including security + coverage
	@echo "Full check pipeline passed."

## ---- Docker ----

docker-build: ## Build Docker image
	docker build -t $(BINARY):latest .

docker-run: docker-build ## Run scan inside Docker container
	docker run --rm $(BINARY):latest scan --type os

docker-scan: docker-build ## Scan the Docker image itself with trivy
	trivy image --severity HIGH,CRITICAL $(BINARY):latest

## ---- Install Dev Tools ----

tools: ## Install development tools
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/securego/gosec/v2/cmd/gosec@latest
	go install golang.org/x/vuln/cmd/govulncheck@latest
	go install golang.org/x/tools/cmd/goimports@latest

## ---- Run ----

run: build ## Build and run a local OS scan
	./bin/$(BINARY) scan --type os

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'
