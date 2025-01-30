# Find all docker-compose*.yml files in the current directory.
# The files are sorted alphabetically, so the order of the files is well-defined.
# The printf is used to construct the argument for docker-compose, which is something
# like "-f docker-compose.yml -f docker-compose.override.yml".
STACK_FILES:=$(shell find . -name "docker-compose*.yml" -print0 | sort -z | xargs -0 -I {} printf "-f %s " {})
TARGETS:= $(shell docker-compose $(STACK_FILES) config --services)
COMPOSE_ARGS:=-p cicd $(STACK_FILES)

all: destroy deploy status

# Show the status of the containers
.PHONY: status
status:
	docker-compose $(COMPOSE_ARGS) ps

# Start/stop/restart a service
.PHONY: $(TARGETS)
$(TARGETS): %:
	make stop-$* start-$*

# Start a service
.PHONY: start-%
start-%:
	docker-compose $(COMPOSE_ARGS) up -d $*

# Stop a service
.PHONY: stop-%
stop-%:
	docker-compose $(COMPOSE_ARGS) up --scale $*=0 $*

# Deploy the stack (up and start all services)
.PHONY: deploy
deploy: destroy
	docker-compose $(COMPOSE_ARGS) up -d

# Destroy the stack (stop and delete all services)
.PHONY: destroy
destroy:
	docker-compose $(COMPOSE_ARGS) down


.PHONY: load
load: 
	docker-compose $(COMPOSE_ARGS) up --scale git-server=0 git-server
	docker-compose $(COMPOSE_ARGS) run --rm git-server sh -c "tar -xzf /backup/backup.tar.gz -C /"
	docker-compose $(COMPOSE_ARGS) up --scale git-server=0 git-server

.PHONY: save
save:
	docker-compose $(COMPOSE_ARGS) up --scale git-server=0 git-server
	docker-compose $(COMPOSE_ARGS) run --rm git-server sh -c "tar -czf /backup/backup.tar.gz /data"
	docker-compose $(COMPOSE_ARGS) up --scale git-server=0 git-server