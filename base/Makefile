all: build run

build:
	docker build . --tag docker.io/sirrgb/dockdroid-base:latest

run:
	docker run --interactive --tty docker.io/sirrgb/dockdroid-base:latest

publish:
	docker tag docker.io/sirrgb/dockdroid-base:latest docker.io/sirrgb/dockdroid-base:$$(date +%Y%m%d%H%M)
	docker image push docker.io/sirrgb/dockdroid-base:$$(date +%Y%m%d%H%M)
	docker image push docker.io/sirrgb/dockdroid-base:latest
