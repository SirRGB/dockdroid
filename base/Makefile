all: build run
tag ?= $$(date +%Y%m%d%H%M)
user ?= sirrgb
registry ?= docker.io

build:
	docker build . --tag $(registry)/$(user)/dockdroid-base:latest --no-cache

run:
	docker run --interactive --tty $(registry)/$(user)/dockdroid-base:latest

publish:
	docker tag $(registry)/$(user)/dockdroid-base:latest $(registry)/$(user)/dockdroid-base:$(tag)
	docker image push $(registry)/$(user)/dockdroid-base:$(tag)
	docker image push $(registry)/$(user)/dockdroid-base:latest
