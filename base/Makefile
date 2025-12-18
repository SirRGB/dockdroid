all: build run

build:
	docker build . --tag docker.io/sirrgb/dockdroid-base:latest

run:
	docker run --interactive --tty docker.io/sirrgb/dockdroid-base:latest

publish:
	docker image push docker.io/sirrgb/dockdroid-base:latest
