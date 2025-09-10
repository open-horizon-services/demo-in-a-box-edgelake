#!/bin/Makefile

# Default values
SHELL := /bin/bash

# The Open Horizon organization ID namespace where you will be publishing files
export HZN_ORG_ID ?= myorg

# Which system configuration to be provisioned
export SYSTEM_CONFIGURATION ?= unicycle

# Configuration parameters for the ERB template
export NUM_AGENTS ?= 1
export BASE_IP ?= 20
export MEMORY ?= 2048
export DISK_SIZE ?= 20

# Map system configurations to parameters
ifeq ($(SYSTEM_CONFIGURATION),unicycle)
    NUM_AGENTS := 1
    BASE_IP := 20
    MEMORY := 2048
    DISK_SIZE := 20
else ifeq ($(SYSTEM_CONFIGURATION),bicycle)
    NUM_AGENTS := 3
    BASE_IP := 20
    MEMORY := 2048
    DISK_SIZE := 20
else ifeq ($(SYSTEM_CONFIGURATION),car)
    NUM_AGENTS := 5
    BASE_IP := 20
    MEMORY := 2048
    DISK_SIZE := 20
else ifeq ($(SYSTEM_CONFIGURATION),semi)
    NUM_AGENTS := 7
    BASE_IP := 20
    MEMORY := 2048
    DISK_SIZE := 20
endif

export VAGRANT_HUB := "./configuration/Vagrantfile.hub"
export VAGRANT_VAGRANTFILE := "./configuration/Vagrantfile.${SYSTEM_CONFIGURATION}"
export VAGRANT_TEMPLATE := "./configuration/Vagrantfile.template.erb"
export VAGRANT_TEMPLATE_LEGACY := "./configuration/Vagrantfile.${SYSTEM_CONFIGURATION}.template"
VMNAME :=

# Detect Operating System running Make
OS := $(shell uname -s)
ARCH := $(shell hzn architecture)

ifeq ($(findstring grafana-,$(MAKECMDGOALS)),grafana-)
    # Multi-arch docker container instance of the open-source grafana project intended for Open Horizon Linux edge nodes
    # grafana docker supports amd64, arm/v7 and arm64
    export DOCKER_IMAGE_BASE ?= grafana/grafana-oss
    export DOCKER_IMAGE_NAME ?= grafana
    export DOCKER_IMAGE_VERSION ?= latest
    export DOCKER_VOLUME_NAME ?= grafana-storage

    # DockerHub ID of the third party providing the image (usually yours if building and pushing)
    export DOCKER_HUB_ID ?= grafana

    # The Open Horizon organization ID namespace where you will be publishing the service definition file
    export HZN_ORG_ID ?= examples

    # Variables required by Home Assistant, can be overridden by your environment variables
    export MY_TIME_ZONE ?= America/New_York

    # Open Horizon settings for publishing metadata about the service
    export DEPLOYMENT_POLICY_NAME ?= deployment-policy-grafana
    export NODE_POLICY_NAME ?= node-policy-grafana
    export SERVICE_NAME ?= service-grafana
    export SERVICE_VERSION ?= 0.0.1

else ifeq ($(findstring psql-,$(MAKECMDGOALS)),psql-)
    # PostgreSQL settings
    export DOCKER_IMAGE_BASE ?= postgres
    export DOCKER_IMAGE_NAME ?= postgres
    export DOCKER_IMAGE_VERSION ?= 17.4
    export DOCKER_VOLUME_NAME ?= postgresql_config

    # DockerHub ID of the third party providing the image (usually yours if building and pushing)
    export DOCKER_HUB_ID ?= postgres

    # The Open Horizon organization ID namespace where you will be publishing the service definition file
    export HZN_ORG_ID ?= examples

    # Open Horizon settings for publishing metadata about the service
    export DEPLOYMENT_POLICY_NAME ?= deployment-policy-postgresql
    export NODE_POLICY_NAME ?= node-policy-postgresql
    export SERVICE_NAME ?= service-postgresql
    export SERVICE_VERSION ?= 0.0.1
else
	export EDGELAKE_TYPE ?= operator
	export HZN_ORG_ID ?= myorg
	export HZN_LISTEN_IP ?= 127.0.0.1
	export SERVICE_NAME ?= service-edgelake-$(EDGELAKE_TYPE)
	export SERVICE_VERSION ?= 1.3.5
	export TEST_CONN ?=

	export DOCKER_IMAGE_VERSION := 1.3.2504-beta19
	ifeq ($(ARCH),aarch64 arm64)
		DOCKER_IMAGE_VERSION := 1.3.2504-beta19-arm64
	endif

	ifneq ($(filter test-node test-network,$(MAKECMDGOALS)),test-node test-network)
		export NODE_NAME := $(shell cat edgelake/configurations/edgelake_${EDGELAKE_TYPE}.env | grep NODE_NAME | awk -F "=" '{print $$2}' | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]')
		export ANYLOG_SERVER_PORT := $(shell cat edgelake/configurations/edgelake_${EDGELAKE_TYPE}.env | grep ANYLOG_SERVER_PORT | awk -F "=" '{print $$2}')
		export ANYLOG_REST_PORT := $(shell cat edgelake/configurations/edgelake_${EDGELAKE_TYPE}.env | grep ANYLOG_REST_PORT | awk -F "=" '{print $$2}')
		export ANYLOG_BROKER_PORT := $(shell cat edgelake/configurations/edgelake_${EDGELAKE_TYPE}.env | grep ANYLOG_BROKER_PORT | awk -F "=" '{print $$2}' | grep -v '^$$')
		export REMOTE_CLI := $(shell cat edgelake/configurations/edgelake_${EDGELAKE_TYPE}.env | grep REMOTE_CLI | awk -F "=" '{print $$2}')
		export ENABLE_NEBULA := $(shell cat edgelake/configurations/edgelake_${EDGELAKE_TYPE}.env | grep ENABLE_NEBULA | awk -F "=" '{print $$2}')
		export DOCKER_IMAGE_BASE ?= $(shell cat edgelake/configurations/.env | grep IMAGE | awk -F "=" '{print $$2}')
		export IMAGE_ORG ?= $(shell echo $(DOCKER_IMAGE_BASE) | cut -d '/' -f 1)
		export IMAGE_NAME ?= $(shell echo $(DOCKER_IMAGE_BASE) | cut -d '/' -f 2)
	endif
endif

export CONTAINER_CMD := $(shell if command -v podman >/dev/null 2>&1; then echo "podman"; else echo "docker"; fi)

export PYTHON_CMD := $(shell if command -v python >/dev/null 2>&1; then echo "python"; \
	elif command -v python3 >/dev/null 2>&1; then echo "python3"; fi)

all: help

#======================================================================================================================#
#  										   VAGRANT related commands											   	   	   #
#======================================================================================================================#
default: status

check: ## Show all environment variable values related to VAGRANT
	@echo "=====================     ============================================="
	@echo "ENVIRONMENT VARIABLES     VALUES"
	@echo "=====================     ============================================="
	@echo "SYSTEM_CONFIGURATION      ${SYSTEM_CONFIGURATION}"
	@echo "NUM_AGENTS                ${NUM_AGENTS}"
	@echo "BASE_IP                   ${BASE_IP}"
	@echo "MEMORY                    ${MEMORY}"
	@echo "DISK_SIZE                 ${DISK_SIZE}"
	@echo "VAGRANT_HUB               ${VAGRANT_HUB}"
	@echo "VAGRANT_TEMPLATE          ${VAGRANT_TEMPLATE}"
	@echo "VAGRANT_VAGRANTFILE       ${VAGRANT_VAGRANTFILE}"
	@echo "HZN_ORG_ID                ${HZN_ORG_ID}"
	@echo "OS                        ${OS}"
	@echo "=====================     ============================================="
	@echo ""

init: up-hub up ## Initiate VAGRANT process

up-hub: ## Setup VAGRANT file
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant up | tee summary.txt
	@grep 'export HZN_ORG_ID=' summary.txt | cut -c16- | tail -n1 > mycreds.env
	@grep 'export HZN_EXCHANGE_USER_AUTH=' summary.txt | cut -c16- | tail -n1 >>mycreds.env
	@if [ -f summary.txt ]; then rm summary.txt; fi

up: ## Run VAGRANT using ERB template
	$(eval include ./mycreds.env)
	@erb hzn_org_id=${HZN_ORG_ID} hzn_exchange_user_auth=${HZN_EXCHANGE_USER_AUTH} num_agents=$(NUM_AGENTS) base_ip=$(BASE_IP) memory=$(MEMORY) disk_size=$(DISK_SIZE) $(VAGRANT_TEMPLATE) > $(VAGRANT_VAGRANTFILE)
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant up --parallel

up-legacy: ## Run VAGRANT using legacy static template
	$(eval include ./mycreds.env)
	@envsubst < $(VAGRANT_TEMPLATE_LEGACY) > $(VAGRANT_VAGRANTFILE)
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant up

connect-hub: ## connect to VAGRANT hub
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant ssh

connect: ## connect to VAGRANT
	@if [ -f $(VAGRANT_VAGRANTFILE) ]; then \
		VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant ssh $(VMNAME); \
	else \
		echo "Error: Vagrantfile not found at $(VAGRANT_VAGRANTFILE). Run 'make up' first to generate it."; \
		exit 1; \
	fi

status: ## check VAGRANT status
	@if [ -f $(VAGRANT_VAGRANTFILE) ]; then \
		VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant status; \
	else \
		echo "Error: Vagrantfile not found at $(VAGRANT_VAGRANTFILE). Run 'make up' first to generate it."; \
		exit 1; \
	fi

status-hub: ## check VAGRANT hub status
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant status

down: destroy destroy-hub clean ## stop and clean VAGRANT

clean: ## clean VAGRANT and hub
	@if [ -f $(VAGRANT_VAGRANTFILE) ]; then rm $(VAGRANT_VAGRANTFILE); fi
	@if [ -f summary.txt ]; then rm summary.txt; fi
	@if [ -f mycreds.env ]; then rm mycreds.env; fi
	@vagrant global-status --prune

destroy: ## destroy VAGRANT
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant destroy -f

destroy-hub: ## clean  VAGRANT hub
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant destroy -f

browse: ## show connection information
ifeq ($(OS),Darwin)
	@open http://127.0.0.1:8123
else
	@xdg-open http://127.0.0.1:8123
endif

#======================================================================================================================#
#  										   Grafana related commands											   	   	   #
#======================================================================================================================#
grafana-prep-service: ## prepare  `edgelake/service.definition.json` with Grafana service
	@$(PYTHON_CMD) edgelake/update_service_deployment.py --required-services service-grafana
grafana-publish: grafana-publish-service grafana-publish-service-policy grafana-publish-deployment-policy ## publish services and policies
grafana-publish-version: grafana-publish-service grafana-publish-service-policy ## update version
grafana-publish-service: ## publish service
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@#hzn exchange service publish -O -P --json-file=service.definition.json
	@hzn exchange service publish --org=${HZN_ORG_ID} --user-pw=${HZN_EXCHANGE_USER_AUTH} -O -P --json-file=grafana/service.definition.json
grafana-publish-service-policy: ##  public service policy
	@echo "========================="
	@echo "PUBLISHING SERVICE POLICY"
	@echo "========================="
	# @hzn exchange service addpolicy -f service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@hzn exchange service addpolicy --org=${HZN_ORG_ID} --user-pw=${HZN_EXCHANGE_USER_AUTH} -f grafana/service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
grafana-publish-deployment-policy: grafana-prep-service ## publish deployment policy
	@echo "============================"
	@echo "PUBLISHING DEPLOYMENT POLICY"
	@echo "============================"
	# @hzn exchange deployment addpolicy -f deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@hzn exchange deployment addpolicy --org=$(HZN_ORG_ID) --user-pw=$(HZN_EXCHANGE_USER_AUTH) -f grafana/deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
grafana-check: ## check Grafana variables
	@echo "====================="
	@echo "ENVIRONMENT VARIABLES"
	@echo "====================="
	@echo "DOCKER_IMAGE_BASE      default: grafana/grafana-oss			actual: ${DOCKER_IMAGE_BASE}"
	@echo "DOCKER_IMAGE_NAME      default: grafana                         actual: ${DOCKER_IMAGE_NAME}"
	@echo "DOCKER_IMAGE_VERSION   default: latest                                actual: ${DOCKER_IMAGE_VERSION}"
	@echo "DOCKER_VOLUME_NAME     default: grafana-storage                  actual: ${DOCKER_VOLUME_NAME}"
	@echo "DOCKER_HUB_ID           default: grafana                         actual: ${DOCKER_HUB_ID}"
	@echo "HZN_ORG_ID             default: examples                              actual: ${HZN_ORG_ID}"
	@echo "MY_TIME_ZONE           default: America/New_York                      actual: ${MY_TIME_ZONE}"
	@echo "DEPLOYMENT_POLICY_NAME default: deployment-policy-grafana       actual: ${DEPLOYMENT_POLICY_NAME}"
	@echo "NODE_POLICY_NAME       default: node-policy-grafana             actual: ${NODE_POLICY_NAME}"
	@echo "SERVICE_NAME           default: service-grafana                 actual: ${SERVICE_NAME}"
	@echo "SERVICE_VERSION        default: 0.0.1                                 actual: ${SERVICE_VERSION}"
	@echo "ARCH                   default: amd64                                 actual: ${ARCH}"
	@echo ""
	@echo "=================="
	@echo "SERVICE DEFINITION"
	@echo "=================="
	@cat grafana/service.definition.json | envsubst
	@echo ""

#======================================================================================================================#
#  										   Postgres related commands											   	   #
#======================================================================================================================#
psql-prep-service: ## prepare  `edgelake/service.definition.json` with Postgres Service
	@$(PYTHON_CMD) edgelake/update_service_deployment.py --required-services service-postgresql
psql-publish: psql-publish-service psql-publish-service-policy psql-publish-deployment-policy ## publish services and policies
psql-publish-version: psql-publish-service psql-publish-service-policy ## update version
psql-publish-service: ## publish service
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@#hzn exchange service publish -O -P --json-file=service.definition.json
	@hzn exchange service publish --org=${HZN_ORG_ID} --user-pw=${HZN_EXCHANGE_USER_AUTH} -O -P --json-file=postgresql/horizon/service.definition.json
psql-publish-service-policy: ##  public service policy
	@echo "========================="
	@echo "PUBLISHING SERVICE POLICY"
	@echo "========================="
	# @hzn exchange service addpolicy -f service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@hzn exchange service addpolicy --org=${HZN_ORG_ID} --user-pw=${HZN_EXCHANGE_USER_AUTH} -f postgresql/horizon/deployment.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
psql-publish-deployment-policy: psql-prep-service ## publish deployment policy
	@echo "============================"
	@echo "PUBLISHING DEPLOYMENT POLICY"
	@echo "============================"
	# @hzn exchange deployment addpolicy -f deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@hzn exchange deployment addpolicy --org=$(HZN_ORG_ID) --user-pw=$(HZN_EXCHANGE_USER_AUTH) -f postgresql/horizon/deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)

psql-check: ## PostgresSQL variable check
	@echo "====================="
	@echo "ENVIRONMENT VARIABLES"
	@echo "====================="
	@echo "DOCKER_IMAGE_BASE      default: postgres                              actual: ${DOCKER_IMAGE_BASE}"
	@echo "DOCKER_IMAGE_NAME      default: postgres                              actual: ${DOCKER_IMAGE_NAME}"
	@echo "DOCKER_IMAGE_VERSION   default: latest                                actual: ${DOCKER_IMAGE_VERSION}"
	@echo "DOCKER_VOLUME_NAME     default: postgresql_config                     actual: ${DOCKER_VOLUME_NAME}"
	@echo "DOCKER_HUB_ID          default: postgres                              actual: ${DOCKER_HUB_ID}"
	@echo "HZN_ORG_ID             default: examples                              actual: ${HZN_ORG_ID}"
	@echo "DEPLOYMENT_POLICY_NAME default: deployment-policy-postgresql          actual: ${DEPLOYMENT_POLICY_NAME}"
	@echo "NODE_POLICY_NAME       default: node-policy-postgresql                actual: ${NODE_POLICY_NAME}"
	@echo "SERVICE_NAME           default: service-postgresql                    actual: ${SERVICE_NAME}"
	@echo "SERVICE_VERSION        default: 0.0.1                                 actual: ${SERVICE_VERSION}"
	@echo "ARCH                   default: amd64                                 actual: ${ARCH}"
	@echo ""
	@echo "=================="
	@echo "SERVICE DEFINITION"
	@echo "=================="
	@cat postgresql/horizon/service.definition.json | envsubst
	@echo ""

#======================================================================================================================#
#  										   EdgeLake related commands											   	   #
#======================================================================================================================#
prep-service: ## prepare `service.deployment.json` file using python / python3
	@$(PYTHON_CMD) edgelake/create_policy.py $(SERVICE_VERSION) edgelake/configurations/edgelake_${EDGELAKE_TYPE}.env
full-deploy: publish-service publish-service-policy  publish-deployment-policy agent-run ## deploy all services and policies, then start agent
deploy: publish-deployment-policy agent-run ## publish deployment and run agent
publish: publish-service publish-service-policy publish-deployment-policy ## publish services and policies
publish-version: publish-service publish-service-policy ## update version
publish-service: ## publish service
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@#hzn exchange service publish -O -P --json-file=service.definition.json
	@hzn exchange service publish --org=${HZN_ORG_ID} --user-pw=${HZN_EXCHANGE_USER_AUTH} -O -P --json-file=edgelake/service.definition.json
publish-service-policy: ##  public service policy
	@echo "========================="
	@echo "PUBLISHING SERVICE POLICY"
	@echo "========================="
	# @hzn exchange service addpolicy -f service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@hzn exchange service addpolicy --org=${HZN_ORG_ID} --user-pw=${HZN_EXCHANGE_USER_AUTH} -f edgelake/service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
publish-deployment-policy: prep-service ## publish deployment policy
	@echo "============================"
	@echo "PUBLISHING DEPLOYMENT POLICY"
	@echo "============================"
	# @hzn exchange deployment addpolicy -f deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@hzn exchange deployment addpolicy --org=$(HZN_ORG_ID) --user-pw=$(HZN_EXCHANGE_USER_AUTH) -f edgelake/service.deployment.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
agent-run: ## start agent
	@echo "================"
	@echo "REGISTERING NODE"
	@echo "================"
	@#hzn register --policy=node.policy.json
	@hzn register --name=hzn-client --policy=edgelake/node.policy.json
	@watch $(MAKE) hzn-agreement-list #w atch agreement list
hzn-clean: ## unregister agent(s) from OpenHorizon
	@echo "==================="
	@echo "UN-REGISTERING NODE"
	@echo "==================="
	@hzn unregister -f
	@echo ""
hzn-agreement-list: ## check agreement list
	@hzn agreement list
hzn-logs: ## logs for Docker container when running in OpenHorizon
	@$(CONTAINER_CMD) logs $(CONTAINER_ID)
deploy-check: ## check deployment
	@hzn deploycheck all -t device -B edgelake/service.deployment.json --service=edgelake/service.definition.json --service-pol=edgelake/service.policy.json --node-pol=edgelake/node.policy.json

#======================================================================================================================#
#  											Testing / Help related commands											   #
#======================================================================================================================#
test: ## Test ERB template syntax and generation
	@echo "=================="
	@echo "TESTING ERB TEMPLATE"
	@echo "=================="
	@echo "Testing ERB template syntax..."
	@ruby -c -e "require 'erb'; ERB.new(File.read('$(VAGRANT_TEMPLATE)'))" 2>/dev/null && echo "✅ ERB syntax is valid" || (echo "❌ ERB syntax error detected" && exit 1)
	@echo "Testing template generation with sample data..."
	@mkdir -p test_output
	@erb hzn_org_id=testorg hzn_exchange_user_auth=testuser:testpass num_agents=2 base_ip=30 memory=1024 disk_size=10 $(VAGRANT_TEMPLATE) > test_output/Vagrantfile.test 2>/dev/null && echo "✅ Template generation successful" || (echo "❌ Template generation failed" && exit 1)
	@echo "Validating generated Vagrantfile syntax..."
	@ruby -c test_output/Vagrantfile.test 2>/dev/null && echo "✅ Generated Vagrantfile syntax is valid" || (echo "❌ Generated Vagrantfile has syntax errors" && exit 1)
	@echo "Testing with different system configurations..."
	@for config in unicycle bicycle car semi; do \
		echo "Testing $$config configuration..."; \
		erb hzn_org_id=testorg hzn_exchange_user_auth=testuser:testpass num_agents=$$(grep -A 20 "ifeq (\$$(SYSTEM_CONFIGURATION),$$config)" $(MAKEFILE_LIST) | grep "NUM_AGENTS :=" | head -1 | awk '{print $$3}') base_ip=$$(grep -A 20 "ifeq (\$$(SYSTEM_CONFIGURATION),$$config)" $(MAKEFILE_LIST) | grep "BASE_IP :=" | head -1 | awk '{print $$3}') memory=$$(grep -A 20 "ifeq (\$$(SYSTEM_CONFIGURATION),$$config)" $(MAKEFILE_LIST) | grep "MEMORY :=" | head -1 | awk '{print $$3}') disk_size=$$(grep -A 20 "ifeq (\$$(SYSTEM_CONFIGURATION),$$config)" $(MAKEFILE_LIST) | grep "DISK_SIZE :=" | head -1 | awk '{print $$3}') $(VAGRANT_TEMPLATE) > test_output/Vagrantfile.$$config.test 2>/dev/null && echo "✅ $$config configuration test passed" || (echo "❌ $$config configuration test failed" && exit 1); \
	done
	@echo "Cleaning up test files..."
	@rm -rf test_output
	@echo "🎉 All ERB template tests passed successfully!"

test-node: ## Test a node via REST interface
ifeq ($(TEST_CONN), )
	@echo "Missing Connection information (Param Name: TEST_CONN)"
	exit 1
endif
	@echo "Test Node against $(TEST_CONN)"
	@curl -X GET http://$(TEST_CONN) -H "command: test node" -H "User-Agent: AnyLog/1.23" -w "\n"
test-network: ## Test the network via REST interface
ifeq ($(TEST_CONN), )
	@echo "Missing Connection information (Param Name: TEST_CONN)"
	exit 1
endif
	@echo "Test Network against $(TEST_CONN)"
	@curl -X GET http://$(TEST_CONN) -H "command: test network" -H "User-Agent: AnyLog/1.23" -w "\n"
check-vars: ## Show all environment variable values related to EdgeLake
	@echo "====================="
	@echo   "ENVIRONMENT VARIABLES"
	@echo "====================="
	@echo "EDGELAKE_TYPE          default: generic                               actual: $(EDGELAKE_TYPE)"
	@echo "DOCKER_IMAGE_BASE      default: anylogco/edgelake                     actual: $(DOCKER_IMAGE_BASE)"
	@echo "DOCKER_IMAGE_NAME      default: edgelake                              actual: $(IMAGE_NAME)"
	@echo "DOCKER_IMAGE_VERSION   default: 1.3.2504                                actual: $(DOCKER_IMAGE_VERSION)"
	@echo "DOCKER_HUB_ID          default: anylogco                              actual: $(IMAGE_ORG)"
	@echo "HZN_ORG_ID             default: myorg                                 actual: ${HZN_ORG_ID}"
	@echo "HZN_LISTEN_IP          default: 127.0.0.1                             actual: ${HZN_LISTEN_IP}"
	@echo "SERVICE_NAME                                                          actual: ${SERVICE_NAME}"
	@echo "SERVICE_VERSION                                                       actual: ${SERVICE_VERSION}"
	@echo "ARCH                   default: amd64                                 actual: ${ARCH}"
	@echo "==================="
	@echo "EDGELAKE DEFINITION"
	@echo "==================="
	@echo "EDGELAKE_TYPE         Default: generic            Value: $(EDGELAKE_TYPE)"
	@echo "NODE_NAME             Default: edgelake-node      Value: $(NODE_NAME)"
	@echo "DOCKER_IMAGE_VERSION  Default: 1.3.2504             Value: $(DOCKER_IMAGE_VERSION)"
	@echo "ANYLOG_SERVER_PORT    Default: 32548              Value: $(ANYLOG_SERVER_PORT)"
	@echo "ANYLOG_REST_PORT      Default: 32549              Value: $(ANYLOG_REST_PORT)"
	@echo "ANYLOG_BROKER_PORT    Default:                    Value: $(ANYLOG_BROKER_PORT)"
help:
	@echo ""
	@echo "Usage: make [target] [VARIABLE=value]"
	@echo ""

	@echo "======================================================================================================================"
	@echo "                                             VAGRANT related commands                                                  "
	@echo "======================================================================================================================"
	@grep -E '^(default|check|init|up-hub|up|up-legacy|connect-hub|connect|status|status-hub|down|clean|destroy|destroy-hub|browse):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':|##' '{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3 }'

	@echo ""
	@echo "======================================================================================================================"
	@echo "                                             Grafana related commands                                                  "
	@echo "======================================================================================================================"
	@grep -E '^(grafana-prep-service|grafana-publish|grafana-publish-version|grafana-publish-service|grafana-publish-service-policy|grafana-publish-deployment-policy|grafana-check):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':|##' '{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3 }'

	@echo ""
	@echo "======================================================================================================================"
	@echo "                                             Postgres related commands                                                 "
	@echo "======================================================================================================================"
	@grep -E '^(psql-prep-service|psql-publish|psql-publish-version|psql-publish-service|psql-publish-service-policy|psql-publish-deployment-policy|psql-check):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':|##' '{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3 }'

	@echo ""
	@echo "======================================================================================================================"
	@echo "                                             EdgeLake related commands                                                 "
	@echo "======================================================================================================================"
	@grep -E '^(prep-service|full-deploy|deploy|publish|publish-version|publish-service|publish-service-policy|publish-deployment-policy|agent-run|hzn-clean|hzn-agreement-list|hzn-logs|deploy-check):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':|##' '{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3 }'

	@echo ""
	@echo "======================================================================================================================"
	@echo "                                             Testing / Help related commands                                           "
	@echo "======================================================================================================================"
	@grep -E '^(test|test-node|test-network|check-vars|help):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':|##' '{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3 }'

	@echo ""
	@echo "======================================================================================================================"
	@echo "                                              Common variables you can override                                       "
	@echo "======================================================================================================================"
	@echo "  EDGELAKE_TYPE         Type of node to deploy (e.g., master, operator)"
	@echo "  DOCKER_IMAGE_VERSION  Docker image tag to use"
	@echo "  NODE_NAME             Custom name for the container"
	@echo "  ANYLOG_SERVER_PORT    Port for server communication"
	@echo "  ANYLOG_REST_PORT      Port for REST API"
	@echo "  ANYLOG_BROKER_PORT    Optional broker port"
	@echo "  TEST_CONN             REST connection information for testing network connectivity"
	@echo "  NUM_AGENTS            Number of agent VMs to create (ERB template)"
	@echo "  BASE_IP               Starting IP address for agent VMs (ERB template)"
	@echo "  MEMORY                Memory allocation per agent VM in MB (ERB template)"
	@echo "  DISK_SIZE             Disk size per agent VM in GB (ERB template)"

.PHONY: default check init up-hub up up-legacy status down destroy browse connect clean connect-hub status-hub destroy-hub