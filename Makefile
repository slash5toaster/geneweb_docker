SHELL := /usr/local/bin/bash

# Docker repository for tagging and publishing
DOCKER_REPO ?= localhost
D2S_VERSION ?= v3.9.4
EXPOSED_PORT ?= 9050

# Date for log files
LOGDATE := $(shell date +%F-%H%M)

# pull the name from the docker file - these labels *MUST* be set
CONTAINER_PROJECT ?= $(shell grep LABEL Dockerfile | grep -i project | cut -d = -f2 | tr -d '"')
CONTAINER_NAME ?= $(shell grep LABEL Dockerfile | grep -i name | cut -d = -f2 | tr -d '"')
CONTAINER_TAG ?= $(shell grep LABEL Dockerfile | grep -i version | cut -d = -f2| tr -d '"')
CONTAINER_STRING ?= $(CONTAINER_PROJECT)/$(CONTAINER_NAME):$(CONTAINER_TAG)

C_ID = $(shell ${GET_ID})
C_STATUS = $(shell ${GET_STATUS})
C_IMAGES = $(shell ${GET_IMAGES})

# HELP
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

envs: ## show the environments
	$(shell echo -e "${CONTAINER_STRING}\n\t${CONTAINER_PROJECT}\n\t${CONTAINER_NAME}\n\t${CONTAINER_TAG}")

local: ## Build the image locally.
	mkdir -vp source/logs/ ; \
	docker build . \
			--cache-from $(CONTAINER_STRING) \
			-t $(CONTAINER_STRING) \
			--progress plain \
			--label BUILDDATE=$(LOGDATE) 2>&1 \
	| tee source/logs/build-$(CONTAINER_PROJECT)-$(CONTAINER_NAME)_$(CONTAINER_TAG)-$(LOGDATE).log ;\
	docker inspect $(CONTAINER_STRING) > source/logs/inspect-$(CONTAINER_PROJECT)-$(CONTAINER_NAME)_$(CONTAINER_TAG)-$(LOGDATE).log

destroy: ## obliterate the local image
	[ "${C_IMAGES}" == "" ] || \
         docker rmi $(CONTAINER_STRING)

remote: ## Push the image to remote.
	$(MAKE) local

singularity: local ## Create a singularity version.
	docker run \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v $(shell pwd)/source:/output \
			--privileged \
			-t \
			--rm \
			quay.io/singularity/docker2singularity:$(D2S_VERSION) \
			$(CONTAINER_STRING)
run: ## run the image
	[ "${C_IMAGES}" ] || \
		make local
	[ "${C_ID}" ] || \
	docker run \
		--rm \
		--detach \
		-e TZ=PST8PDT \
		--name $(CONTAINER_NAME) \
		--hostname=$(CONTAINER_NAME)-$(CONTAINER_TAG) \
		--publish $(EXPOSED_PORT):$(EXPOSED_PORT) \
			$(CONTAINER_STRING)

shell: run ## shell in server image.
	[ "${C_ID}" ] || \
		make run
	docker exec \
		-it \
		-e DEBUG=0 \
		-e TZ=PST8PDT \
		$(CONTAINER_NAME) /bin/sh

kill: ## shutdown
	[ "${C_ID}" ] || \
	docker kill $(C_ID) && \
	docker rm $(C_ID)

publish: ## Push server image to remote
	@echo 'pushing server-$(VERSION) to $(DOCKER_REPO)'
	docker push $(CONTAINER_STRING)

# Commands for extracting information on the running container
GET_IMAGES := docker images ${CONTAINER_STRING} --format "{{.ID}}"
GET_CONTAINER := docker ps -a --filter "name=${CONTAINER_NAME}" --no-trunc
GET_ID := ${GET_CONTAINER} --format {{.ID}}
GET_STATUS := ${GET_CONTAINER} --format {{.Status}} | cut -d " " -f1
