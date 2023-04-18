MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

PT_VERSION=$(shell cat Dockerfile | grep 'ENV PERCONA_TOOLKIT_VERSION' | cut -f3 -d' ')

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app

lint-yaml:
	${exec_docker} cytopia/yamllint .
lint-dockerfile:
	${exec_docker} hadolint/hadolint hadolint --ignore DL3018 Dockerfile
lint: lint-yaml lint-dockerfile
release: lint
	git tag "${PT_VERSION}-$$(($(shell git describe --tags --abbrev=0 | cut -f2 -d '-') + 1))"
	git push --tags
build: lint
	docker buildx build --load --tag "$(shell ${exec_docker} mikefarah/yq e '.env.DOCKER_IMAGE' .github/workflows/publish.yaml):$(shell git describe --tags)" .
