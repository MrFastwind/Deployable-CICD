STACK_FILES:= -f docker-compose.yml
TARGETS := $(shell docker-compose $(STACK_FILES) config --services)

all: destroy deploy status

# Show the status of the containers
.PHONY: status
status:
	docker-compose $(STACK_FILES) ps

# Start/stop/restart a service
.PHONY: $(TARGETS)
$(TARGETS): %: stop-% start-%

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

