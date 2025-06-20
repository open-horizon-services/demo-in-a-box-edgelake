#!/bin/Makefile

# Default values
SHELL := /bin/bash

export EDGELAKE_TYPE ?= generic
export HZN_ORG_ID ?= myorg
export HZN_LISTEN_IP ?= 127.0.0.1
export SERVICE_NAME ?= service-edgelake-$(EDGELAKE_TYPE)
export SERVICE_VERSION ?= 1.3.5
export TEST_CONN ?=

# Detect OS type
export OS := $(shell uname -s)

# Conditional port override based on EDGELAKE_TYPE

export DOCKER_IMAGE_VERSION := 1.3.2504
ARCH := $(shell hzn architecture)
ifeq ($(ARCH),aarch64 arm64)
	DOCKER_IMAGE_VERSION := 1.3.2504-arm64
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

export CONTAINER_CMD := $(shell if command -v podman >/dev/null 2>&1; then echo "podman"; else echo "docker"; fi)

export PYTHON_CMD := $(shell if command -v python >/dev/null 2>&1; then echo "python"; \
	elif command -v python3 >/dev/null 2>&1; then echo "python3"; fi)

all: help
#======================================================================================================================#
#  										   OpenHorizon related commands											   	   #
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
check-vars: ## Show all environment variable values
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
	@echo "Usage: make [target] [VARIABLE=value]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':|##' '{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3 }'
	@echo ""
	@echo "Common variables you can override:"
	@echo "  EDGELAKE_TYPE         Type of node to deploy (e.g., master, operator)"
	@echo "  DOCKER_IMAGE_VERSION  Docker image tag to use"
	@echo "  NODE_NAME           Custom name for the container"
	@echo "  ANYLOG_SERVER_PORT  Port for server communication"
	@echo "  ANYLOG_REST_PORT    Port for REST API"
	@echo "  ANYLOG_BROKER_PORT  Optional broker port"
	@echo "  TEST_CONN           REST connection information for testing network connectivity"