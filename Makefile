# This Makefile requires GNU Make.
MAKEFLAGS += --silent

# Settings
C_BLU='\033[0;34m'
C_GRN='\033[0;32m'
C_RED='\033[0;31m'
C_YEL='\033[0;33m'
C_END='\033[0m'

include .env

DOCKER_ABBR=$(PROJECT_ABBR)
DOCKER_HOST=$(PROJECT_HOST)
DOCKER_PORT=$(PROJECT_PORT)
DOCKER_NAME=$(PROJECT_CONT)
DOCKER_PATH=$(PROJECT_PATH)

CURRENT_DIR=$(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
DIR_BASENAME=$(shell basename $(CURRENT_DIR))
ROOT_DIR=$(CURRENT_DIR)

help: ## shows this Makefile help message
	echo 'usage: make [target]'
	echo
	echo 'targets:'
	egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

# -------------------------------------------------------------------------------------------------
#  System
# -------------------------------------------------------------------------------------------------
.PHONY: hostname fix-permission host-check

hostname: ## shows local machine ip
	echo $(word 1,$(shell hostname -I))

fix-permission: ## sets project directory permission
	$(DOCKER_USER) chown -R ${USER}: $(ROOT_DIR)/

ports-check: ## shows this project ports availability on local machine
	cd docker/php && $(MAKE) port-check
	cd docker/mariadb && $(MAKE) port-check

# -------------------------------------------------------------------------------------------------
#  Docker
# -------------------------------------------------------------------------------------------------
.PHONY: docker-ip docker-host

docker-ip:
	$(DOCKER_USER) docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(DOCKER_NAME)

docker-host:
	echo ${C_BLU}"Docker Host:"${C_END}; \
	echo $(shell make docker-ip):$(DOCKER_PORT)
	echo ${C_BLU}"Local Host:"${C_END}; \
	echo localhost:$(DOCKER_PORT); \
	echo 127.0.0.1:$(DOCKER_PORT); \
	echo ${C_BLU}"Project Host:"${C_END}; \
	echo $(DOCKER_HOST):$(DOCKER_PORT); \

# -------------------------------------------------------------------------------------------------
#  Wordpress https://wordpress.org/wordpress-6.4.3.zip
# -------------------------------------------------------------------------------------------------
.PHONY: wordpress-set wordpress-build wordpress-start wordpress-stop wordpress-destroy

wordpress-set: ## sets the Wordpress PHP enviroment file to build the container
	cd docker/php && $(MAKE) env-set

wordpress-build: ## builds the Wordpress PHP container from Docker image
	cd docker/php && $(MAKE) build

wordpress-start: ## starts up the Wordpress PHP container running
	cd docker/php && $(MAKE) up

wordpress-stop: ## stops the Wordpress PHP container but data won't be destroyed
	cd docker/php && $(MAKE) stop

wordpress-destroy: ## stops and removes the Wordpress PHP container from Docker network destroying its data
	cd docker/php && $(MAKE) stop clear

# -------------------------------------------------------------------------------------------------
#  Wordpress - MariaDB database
# -------------------------------------------------------------------------------------------------
.PHONY: database-set database-build database-start database-stop database-destroy database-install database-download

database-set: ## sets the database enviroment file to build the container
	cd docker/mariadb && $(MAKE) env-set

database-build: ## builds the database container from Docker image
	cd docker/mariadb && $(MAKE) build

database-start: ## starts up the database container running
	cd docker/mariadb && $(MAKE) up

database-stop: ## stops the database container but data won't be destroyed
	cd docker/mariadb && $(MAKE) stop

database-destroy: ## stops and removes the database container from Docker network destroying its data
	cd docker/mariadb && $(MAKE) stop clear

database-install: ## Copies the .sql file into container selected database
	cd docker/mariadb && $(MAKE) sql-install
	echo ${C_BLU}"$(DOCKER_ABBR)"${C_END}" database has been "${C_GRN}"installed."${C_END};

database-download: ## Download a copy as .sql file from container to a determined local host directory
	cd docker/mariadb && $(MAKE) sql-backup
	echo ${C_BLU}"$(DOCKER_ABBR)"${C_END}" database has been "${C_GRN}"dowloaded."${C_END};

# -------------------------------------------------------------------------------------------------
#  Wordpress Project
# -------------------------------------------------------------------------------------------------
.PHONY: project-build project-start project-stop project-destroy

project-build: ## builds both Wordpress and database containers from their Docker images
	$(MAKE) wordpress-set database-set database-build wordpress-build

project-start: ## starts up both Wordpress and database containers running
	$(MAKE) database-start wordpress-start

project-stop: ## stops both Wordpress and database containers but data won't be destroyed
	$(MAKE) database-stop wordpress-stop

project-destroy: ## stops and removes both Wordpress and database containers from Docker network destroying their data
	$(MAKE) database-destroy wordpress-destroy

# -------------------------------------------------------------------------------------------------
#  Wordpress Example Plugin
# -------------------------------------------------------------------------------------------------
.PHONY: plugin-zip

plugin-zip:
	cd resources/plugin/dev && zip -r ../pr-custom.zip *

# -------------------------------------------------------------------------------------------------
#  Wordpress Example Plugin
# -------------------------------------------------------------------------------------------------
repo-flush: ## clears local git repository cache specially to update .gitignore
	git rm -rf --cached .
	git add .
	git commit -m "fix: cache cleared for untracked files"