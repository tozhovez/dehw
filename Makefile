PROJECTNAME=$(shell basename "$(PWD)")
PACKAGE_PREFIX := home-assignment
PACKAGE := ${PROJECTNAME}
STORAGE := ${PROJECTNAME}-storage
REQ_FILE = requirements.txt
PYTHON := $(shell which python)
PIP := $(shell which pip)
PYV := $(shell $(PYTHON) -c "import sys;t='{v[0]}.{v[1]}'.format(v=list(sys.version_info[:2]));sys.stdout.write(t)")
PWD := $(shell pwd)
SHELL = /bin/bash

.PHONY: clean

.DEFAULT_GOAL: help

help: ## Show this help
	@printf "\n\033[33m%s:\033[1m\n" 'Choose available commands run in "$(PROJECTNAME)"'
	@echo "======================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[32m%-14s		\033[35;1m-- %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\033[33m%s\033[1m\n"
	@echo "======================================================"


envs: ## Print environment variables
	@echo "======================================================"
	@echo "PROJECTNAME: $(PROJECTNAME)"
	@echo "PACKAGE_PREFIX: $(PACKAGE_PREFIX)"
	@echo "PACKAGE: $(PACKAGE)"
	@echo "STORAGE: $(STORAGE)"
	@echo "REQ_FILE: $(REQ_FILE)"
	@echo "PYTHON: $(PYTHON)"
	@echo "PIP: $(PIP)"
	@echo "PYV: $(PYV)"
	@echo "PWD: $(PWD)"
	@echo "SHELL: $(SHELL)"
	@echo "======================================================"


install-requirements: clean ## Install requirements
	@echo "======================================================"
	@echo "install-requirements $(PYV) $(PACKAGE)"
	@echo "======================================================"
	$(PIP) install -r $(REQ_FILE)
	@echo "======================================================"


run-infra: ## docker compose up infrastructure container
	@docker compose -f docker-compose.infra.yml up -d > /dev/null

stop-infra: ## docker compose stop infrastructure container
	@docker compose -f docker-compose.infra.yml down > /dev/null


create-database: ## Create postgres database and import schema
	@echo "======================================================"
	@echo ""
	@echo "======================================================"
	sudo chmod +x -R ./../$(PROJECTNAME)
	###&& chmod 777 -R ./../$(PROJECTNAME)
	@cd ./infra && $(PYTHON) create_database.py



dummy-data: ## create and insert dummy data to data base
	@cd ./infra && $(PYTHON) create_dummydata.py;
	@cd ./infra && $(PYTHON) insert_data.py;

uploader-data: ## Uploader data service start
	@cd ./infra && $(PYTHON) service.py

queries: ## Script to run SQLs
	@echo "======================================================"
	@echo "SQL queries that address the business requirements"
	@echo "and produce a combined datasets"
	@echo "for reports as described"
	@echo "======================================================"
	cd queries && sudo chmod +x ./query.sh;
	cd queries && query.sh;

clean: ## Clean sources
	@echo "======================================================"
	@echo clean $(PROJECTNAME)
	@echo $(find ./* -maxdepth 0 -name "*.pyc" -type f)
	echo $(find . -name ".DS_Store" -type f)
	@rm -fR __pycache__ venv "*.pyc"
	@find ./* -maxdepth 0 -name "*.pyc" -type f -delete
	@find ./* -name '*.py[cod]' -delete
	@find ./* -name '__pycache__' -delete
	find . -name '*.DS_Store' -delete


list: ## Makefile target list
	@echo "======================================================"
	@echo Makefile target list
	@echo "======================================================"
	@cat Makefile | grep "^[a-z]" | awk '{print $$1}' | sed "s/://g" | sort
