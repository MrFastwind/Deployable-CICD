# Find all docker-compose*.yml files in the current directory.
# The files are sorted alphabetically, so the order of the files is well-defined.
# The printf is used to construct the argument for docker-compose, which is something
# like "-f docker-compose.yml -f docker-compose.override.yml".
STACK_FILES:=$(shell find . -name "docker-compose*.yml" -print0 | sort -z | xargs -0 -I {} printf "-f %s " {})
TARGETS := $(shell docker-compose $(STACK_FILES) config --services)

all: destroy deploy status

# Show the status of the containers
.PHONY: status
status:
	docker-compose $(STACK_FILES) ps

# Start/stop/restart a service
.PHONY: $(TARGETS)
$(TARGETS): %:
	make stop-$* start-$*

# Start a service
.PHONY: start-%
start-%:
	docker-compose $(STACK_FILES) up -d $*

# Stop a service
.PHONY: stop-%
stop-%:
	docker-compose $(STACK_FILES) down $*

# Deploy the stack (up and start all services)
.PHONY: deploy
deploy: destroy
	docker-compose $(STACK_FILES) up -d

# Destroy the stack (stop and delete all services)
.PHONY: destroy
destroy:
	docker-compose $(STACK_FILES) down

