SHELL := /bin/bash

GO := go
APP_NAME := rate_limiter
CLI_NAME := cli

DOCKER_IMG="rate-limiter:develop"

GIT_HASH := $(shell git log --format="%h" -n 1)
LDFLAGS := -X main.release="develop" -X main.buildDate=$(shell date -u +%Y-%m-%dT%H:%M:%S) -X main.gitHash=$(GIT_HASH)

include .env.docker
export $(shell sed 's/=.*//' .env)
export GO111MODULE=on
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=amd64

local-tidy:
	go mod tidy
local-vendor:
	go mod vendor
local-build-app:
	go build -o $(APP_NAME) ./cmd/$(APP_NAME)
local-build-cli:
	go build -o $(CLI_NAME) ./cmd/$(CLI_NAME)

local-build: local-tidy local-vendor local-build-app local-build-cli

local-run:
	./$(APP_NAME)
local-clean:
	go clean
	rm $(APP_NAME)
	rm $(CLI_NAME)
local-lint:
	golangci-lint run ./...
local-test:
	go test -race -count 100 ./internal/...
local-all:
	make local-test
	make local-build

local-check:
	./$(CLI_NAME) --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip}
local-reset:
	./$(CLI_NAME) --conf=.env.docker --cmd=reset --login=${login} --ip=${ip}
local-ab:
	./$(CLI_NAME) --conf=.env.docker --cmd=ab --ip=${ip}
local-rb:
	./$(CLI_NAME) --conf=.env.docker --cmd=rb --ip=${ip}
local-aw:
	./$(CLI_NAME) --conf=.env.docker --cmd=aw --ip=${ip}
local-rw:
	./$(CLI_NAME) --conf=.env.docker --cmd=rw --ip=${ip}

docker-check:
	docker exec rate-limiter-ms ./$(CLI_NAME) --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip}
docker-reset:
	docker exec rate-limiter-ms ./$(CLI_NAME) --conf=.env.docker --cmd=reset --login=${login} --ip=${ip}
docker-ab:
	docker exec rate-limiter-ms ./$(CLI_NAME) --conf=.env.docker --cmd=ab --ip=${ip}
docker-rb:
	docker exec rate-limiter-ms ./$(CLI_NAME) --conf=.env.docker --cmd=rb --ip=${ip}
docker-aw:
	docker exec rate-limiter-ms ./$(CLI_NAME) --conf=.env.docker --cmd=aw --ip=${ip}
docker-rw:
	docker exec rate-limiter-ms ./$(CLI_NAME) --conf=.env.docker --cmd=rw --ip=${ip}

docker-test:
	docker exec rate-limiter-ms go test -race -count 100 ./...

compose-up:
	docker compose up -d --build
protoc-install:

protoc:
	protoc --go_out=pb --go-grpc_out=pb api/rate_limiter.proto


# main commands

install-lint-deps:
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.3.0
#	(which golangci-lint > /dev/null) || curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin v2.3.0

lint: install-lint-deps
	golangci-lint run ./...

build: local-build

test:
	go test -race -count 10 ./...

build:
	go build -v -o $(APP_NAME) -ldflags "$(LDFLAGS)" ./cmd/$(APP_NAME)
	go build -o $(CLI_NAME) -ldflags "$(LDFLAGS)" ./cmd/$(CLI_NAME)

run: build
	$(APP_NAME) --conf=./env.docker

build-img:
	docker build \
		--build-arg=LDFLAGS="$(LDFLAGS)" \
		-t $(DOCKER_IMG) \
		-f build/Dockerfile .

run-img: build-img
	docker run $(DOCKER_IMG)


.PHONY: local-all local-test local-build


