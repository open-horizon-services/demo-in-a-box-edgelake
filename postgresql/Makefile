# Multi-arch docker container instance of the open-source home assistant project intended for Open Horizon Linux edge nodes

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

# Default ARCH to the architecture of this machine (assumes hzn CLI installed)
export ARCH ?= amd64

# Detect Operating System running Make
OS := $(shell uname -s)

default: init run

check:
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
	@cat horizon/service.definition.json | envsubst
	@echo ""

stop:
	@docker rm -f $(DOCKER_IMAGE_NAME) >/dev/null 2>&1 || :

init:
	@docker volume create $(DOCKER_VOLUME_NAME)
	@sudo mkdir /db-data
	@sudo chmod 777 /db-data

run: stop
	@docker run -d \
		--name $(DOCKER_IMAGE_NAME) \
		--restart=unless-stopped \
		-v $(DOCKER_VOLUME_NAME):/config \
		-p 5432:5432 \
		$(DOCKER_IMAGE_BASE):$(DOCKER_IMAGE_VERSION)

dev: run attach

attach: 
	@docker exec -it \
		`docker ps -aqf "name=$(DOCKER_IMAGE_NAME)"` \
		/bin/bash		

clean: stop
	@docker rmi -f $(DOCKER_IMAGE_BASE):$(DOCKER_IMAGE_VERSION) >/dev/null 2>&1 || :
	@docker volume rm $(DOCKER_VOLUME_NAME)

distclean: agent-stop remove-deployment-policy remove-service clean

build:
	@echo "There is no Docker image build process since this container is provided by a third-party from official sources."

push:
	@echo "There is no Docker image push process since this container is provided by a third-party from official sources."

full-deployment: publish-service publish-deployment-policy agent-run
publish: publish-service publish-deployment-policy
# Pull, not push, Docker image since provided by third party
publish-service:
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@hzn exchange service publish -O -P --json-file=horizon/service.definition.json
	@echo ""

remove-service:
	@echo "=================="
	@echo "REMOVING SERVICE"
	@echo "=================="
	@hzn exchange service remove -f $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@echo ""

publish-deployment-policy:
	@echo "============================"
	@echo "PUBLISHING DEPLOYMENT POLICY"
	@echo "============================"
	@hzn exchange deployment addpolicy -f horizon/deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@echo ""

remove-deployment-policy:
	@echo "=========================="
	@echo "REMOVING DEPLOYMENT POLICY"
	@echo "=========================="
	@hzn exchange deployment removepolicy -f $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@echo ""

agent-run:
	@echo "================"
	@echo "REGISTERING NODE"
	@echo "================"
	@hzn register --policy=horizon/node.policy.json
	@watch hzn agreement list

agent-stop:
	@echo "==================="
	@echo "UN-REGISTERING NODE"
	@echo "==================="
	@hzn unregister -f
	@echo ""

deploy-check:
	@hzn deploycheck all -t device -B horizon/deployment.policy.json --service=horizon/service.definition.json --node-pol=horizon/node.policy.json

log:
	@echo "========="
	@echo "EVENT LOG"
	@echo "========="
	@hzn eventlog list
	@echo ""
	@echo "==========="
	@echo "SERVICE LOG"
	@echo "==========="
	@hzn service log -f $(SERVICE_NAME)

.PHONY: default stop init run dev clean build push attach publish publish-service publish-deployment-policy publish-pattern agent-run distclean deploy-check check log remove-deployment-policy remove-service
