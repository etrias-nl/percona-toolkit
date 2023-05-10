MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

IMAGE=$(shell docker run -i --rm mikefarah/yq '.env.DOCKER_IMAGE' < .github/workflows/publish.yaml)
IMAGE_TAG=${IMAGE}:$(shell git describe --tags --exact-match || git branch --show-current)

PT_VERSION=$(shell cat Dockerfile | grep 'ENV PERCONA_TOOLKIT_VERSION' | cut -f3 -d' ')

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -e CI -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app

lint-yaml:
	${exec_docker} cytopia/yamllint .
lint-dockerfile:
	${exec_docker} hadolint/hadolint hadolint --ignore DL3018 Dockerfile
lint: lint-yaml lint-dockerfile
release: lint
	@[ "$$(git status --porcelain)" ] && echo "Commit your changes" && exit 1 || true
	@[ "$$(git log --branches --not --remotes)" ] && echo "Push your commits" && exit 1 || true
	@[ "$$(git describe --tags --abbrev=0 --exact-match)" ] && echo "Commit already tagged" && exit 1 || true
	git tag "${PT_VERSION}-$$(($(shell git describe --tags --abbrev=0 | cut -f2 -d '-') + 1))"
	git push --tags
build: lint
	docker buildx build --load --tag "${IMAGE_TAG}" .
cli: clean build
	docker exec -it "$(shell docker run -it -d "${IMAGE_TAG}")" sh
clean:
	docker rm $(shell docker ps -aq -f "ancestor=${IMAGE_TAG}") --force || true
	docker rmi $(shell docker images -q "${IMAGE}") --force || true
