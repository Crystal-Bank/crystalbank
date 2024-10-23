# Project configuration
PROJECT_NAME := crystalbank
COMPOSE_FILE := docker-compose.yml
COMPOSE_TEST_FILE := docker-compose.test.yml
COMPOSE_PROJECT_NAME := $(PROJECT_NAME)
COMPOSE_CMD := docker compose

# Docker image configuration
SERVICE_IMAGE := $(PROJECT_NAME):dev

# Environment files
ENV_FILE := .env-dev
ENV_FILE_TEST := .env-test
ENV_TEMPLATE := .env-dev.template

# Compose arguments
COMPOSE_ARGS := -f $(COMPOSE_FILE) -p $(COMPOSE_PROJECT_NAME)
COMPOSE_TEST_ARGS := -f $(COMPOSE_TEST_FILE) -p $(COMPOSE_PROJECT_NAME)

# Docker compose command helpers
dc        = $(COMPOSE_CMD) $(COMPOSE_ARGS) $(1)
dct       = $(COMPOSE_CMD) $(COMPOSE_TEST_ARGS) $(1)
dc-run    = $(call dc, run --entrypoint "bash -c" --rm cmd $(1))
dct-run    = $(call dct, run --entrypoint "bash -c" --rm cmd $(1))
dc-exec   = $(call dc, exec console $(1))

# Function to check if image exists
check_image_exists = $(shell docker image inspect $(SERVICE_IMAGE) >/dev/null 2>&1 && echo "true" || echo "false")

# Default target
all: help

# Help target
help:
	@echo "Available targets:"
	@echo "  build   			- Build docker image if it doesn't exist"
	@echo "  clean   			- Remove all persisted data"
	@echo "  console 			- Open a console in the web container"
	@echo "  dev     			- Run development environment (default)"
	@echo "  docker-info  - Outputs the current docker and docker-compose version"
	@echo "  down    			- Stop and remove containers and networks"
	@echo "  env     			- Create .env-dev and .env-test files if they don't exist"
	@echo "  lint    			- Runs the linter"
	@echo "  logs    			- Tail docker logs"
	@echo "  rebuild 			  - Force rebuild of the Docker image"
	@echo "  reset   			- Reset the local environment and rebuild from scratch"
	@echo "  restart 			- Restart the development environment"
	@echo "  shards  			- Install dependencies"
	@echo "  start   			- Start the app"
	@echo "  status  			- Check container status"
	@echo "  stop    			- Stop docker services"
	@echo "  test    			- Run tests"

# Development environment
dev: env build up bundle setup-db console

# Start app, jobs, and css containers
start: env build up bundle setup-db
	$(call dc, up -d --scale app=1)

# Build image if it doesn't exist
build-image:
	@if [ "$(call check_image_exists)" = "false" ]; then \
		echo "Building Docker image $(SERVICE_IMAGE)..."; \
		docker build -t $(SERVICE_IMAGE) -f Dockerfile.dev .; \
	else \
		echo "Docker image $(SERVICE_IMAGE) already exists. Skipping build."; \
	fi

# Build target (now just an alias for build-image)
build: build-image

# Force rebuild of the Docker image
rebuild:
	@echo "Forcing rebuild of Docker image $(SERVICE_IMAGE)..."
	docker build --no-cache -t $(SERVICE_IMAGE) -f Dockerfile.dev .

# Start services
up:
	$(call dc, up -d database console)

# Open console
console:
	$(call dc-exec, bash)

# Stop services
stop:
	$(call dc, stop)

# Stop and remove containers
down:
	$(call dc, down --remove-orphans)

# Remove all persisted data
clean:
	$(call dc, down --remove-orphans -v)

# Restart development environment
restart: down dev

# restart the database
restart-db:
	$(call dc, restart database)

# Reset everything to a clean state
reset: clean rebuild dev

# Check container status
ps: status
status:
	$(call dc, ps)

# Tail logs
logs:
	$(call dc, logs -f)

# Create .env-dev file if it doesn't exist
env:
	@test -f $(ENV_FILE) || cp $(ENV_TEMPLATE) $(ENV_FILE)
	@test -f $(ENV_FILE_TEST) || cp $(ENV_TEMPLATE) $(ENV_FILE_TEST)

# Install dependencies
shards:
	$(call dc-run, "shards install")

# Setup the database
setup-db:
# TODO: $(call dc-run, "bin/rails db:create db:prepare db:test:prepare")
# TODO: $(call dc-run, "bin/rails db:seed")

# Run tests
test:
	$(call dct-run, "crystal spec spec/")

# Run Linter
lint:
	$(call dct-run, "crystal tool format --check")

docker-info:
	docker -v
	docker-compose -v