all: build run

build:
	docker build . --tag docker.io/sirrgb/dockdroid-base:latest

run:
	docker run --interactive --tty docker.io/sirrgb/dockdroid-base:latest

publish:
	tag ?= $$(date +%Y%m%d%H%M)
	docker tag docker.io/sirrgb/dockdroid-base:latest docker.io/sirrgb/dockdroid-base:$tag
	docker image push docker.io/sirrgb/dockdroid-base:$tag
	docker image push docker.io/sirrgb/dockdroid-base:latest
