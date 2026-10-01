-include srcs/.env

NAME        = inception
COMPOSE     = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
DATA_PATH  ?= /home/$(LOGIN)/data

all: setup
	$(COMPOSE) up -d --build

setup:
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo "Data directories ready at $(DATA_PATH)"
	@echo "Make sure '127.0.0.1 $(DOMAIN_NAME)' is in /etc/hosts"

down:
	$(COMPOSE) down

clean: down
	$(COMPOSE) down --rmi all --remove-orphans

fclean: clean
	$(COMPOSE) down -v
	sudo rm -rf $(DATA_PATH)

re: fclean all

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

.PHONY: all setup down clean fclean re logs ps
