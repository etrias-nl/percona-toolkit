MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

DOCKER_PROGRESS?=auto
DOCKER_IMAGE=etriasnl/percona-toolkit

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app

lint-yaml:
	${exec_docker} cytopia/yamllint .
lint-dockerfile:
	${exec_docker} hadolint/hadolint hadolint --ignore DL3018 Dockerfile
lint: lint-yaml lint-dockerfile
release:
	git tag "$(shell git describe --tags --abbrev=0 | cut -f1 -d '-')-$$(($(shell git describe --tags --abbrev=0 | cut -f2 -d '-') + 1))"
	git push --tags
build: lint
	docker buildx build --progress "${DOCKER_PROGRESS}" --tag "${DOCKER_IMAGE}:$(shell git describe --tags)" .
