# linux-lab — Selin/TechLabs recording substrate
IMAGE     ?= linux-lab:l0
RUN_FLAGS  = --rm --hostname staging-server-01 --tmpfs /tmp -e TERM=xterm-256color

.PHONY: help build verify shell record clean

help:                ## Show this help
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

build:               ## Build the Level 0 recording image
	docker build -t $(IMAGE) images/l0

verify: build        ## Run the Day 1 teaching-invariant checks in a fresh container
	docker run $(RUN_FLAGS) -v "$(PWD)/test:/test:ro" $(IMAGE) bash /test/verify-day1.sh

shell: build         ## Interactive shell in a fresh container (manual rehearsal)
	docker run -it $(RUN_FLAGS) $(IMAGE) bash

record:              ## Record a lesson tape (option (a) plugs in here)
	echo "TODO (option a): start container -> vhs exec into it -> out/<lesson>.mp4"

clean:               ## Remove the built image
	-docker rmi $(IMAGE)
