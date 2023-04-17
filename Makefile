MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

DOCKER_PROGRESS?=auto
DOCKER_IMAGE=etriasnl/percona-toolkit
PT_VERSION=$(shell cat Dockerfile | grep 'ENV PERCONA_TOOLKIT_VERSION' | cut -f3 -d' ')
PATCH_VERSION=$$(($(shell curl -sS "https://hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/?page_size=1&page=1&name=${PT_VERSION}.&ordering=last_updated" | jq -r '.results[0].name' | cut -f2 -d '-') + 1))

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app

lint:
	${exec_docker} hadolint/hadolint hadolint Dockerfile
build: lint
	docker buildx build --progress "${DOCKER_PROGRESS}" --tag "$(shell git describe --tags)" .
