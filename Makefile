COMPOSE  = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
LOGIN   ?= $(shell whoami)
DATA_DIR := /home/$(LOGIN)/data
VOLUMES  := $(DATA_DIR)/db $(DATA_DIR)/wp $(DATA_DIR)/backup

.PHONY: help prepare up down build stop restart ps ls logs logs-% clean fclean re \
        backup-now backup-list

help:
	@echo "make up           - prepare dirs, build images, start stack (detached)"
	@echo "make down         - stop and remove containers/network"
	@echo "make build        - build images"
	@echo "make stop         - stop containers"
	@echo "make restart      - down + up"
	@echo "make ps | ls      - show compose status"
	@echo "make logs         - follow logs for all services"
	@echo "make logs-<svc>   - follow logs for a single service (e.g., logs-wordpress)"
	@echo "make backup-now   - run an immediate backup in the backup service"
	@echo "make backup-list  - list backup files on the host (VM)"
	@echo "make clean        - prune networks (after down)"
	@echo "make fclean       - FULL docker prune (images/volumes!)"
	@echo "make re           - fclean + up"

prepare:
	mkdir -p $(VOLUMES)

up: prepare build
	$(COMPOSE) up -d

build: prepare
	$(COMPOSE) build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) down
	$(COMPOSE) up -d

ps:
	$(COMPOSE) ps

ls:
	$(COMPOSE) ls

logs:
	$(COMPOSE) logs -f

logs-%:
	$(COMPOSE) logs -f $*

backup-now:
	$(COMPOSE) up -d backup
	$(COMPOSE) exec -T backup /usr/local/bin/backup.sh
	@echo "Latest backups:" && ls -lh $(DATA_DIR)/backup | tail -n 5 || true

backup-list:
	@test -d $(DATA_DIR)/backup && ls -lh $(DATA_DIR)/backup || echo "No backups in $(DATA_DIR)/backup"

clean: down
	- docker network prune -f

fclean: down
	- docker system prune -af --volumes

re: fclean up
