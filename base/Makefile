all: build run
tag ?= $$(date +%Y%m%d%H%M)

build:
	docker build . --tag docker.io/sirrgb/dockdroid-base:latest

run:
	docker run --interactive --tty docker.io/sirrgb/dockdroid-base:latest

publish:
	docker tag docker.io/sirrgb/dockdroid-base:latest docker.io/sirrgb/dockdroid-base:$(tag)
	docker image push docker.io/sirrgb/dockdroid-base:$(tag)
	docker image push docker.io/sirrgb/dockdroid-base:latest
