# The Open Horizon organization ID namespace where you will be publishing files
export HZN_ORG_ID ?= myorg

# Which system configuration to be provisioned
export SYSTEM_CONFIGURATION ?= unicycle
export VAGRANT_VAGRANTFILE := "./configuration/Vagrantfile.${SYSTEM_CONFIGURATION}"

# Detect Operating System running Make
OS := $(shell uname -s)

default: status

check:
	@echo "====================="
	@echo "ENVIRONMENT VARIABLES"
	@echo "====================="
	@echo "SYSTEM_CONFIGURATION  default: unicycle                              actual: ${SYSTEM_CONFIGURATION}"
	@echo "VAGRANT_VAGRANTFILE   default: ./configuration/Vagrantfile.unicycle  actual: ${VAGRANT_VAGRANTFILE}"
	@echo "HZN_ORG_ID            default: myorg                                 actual: ${HZN_ORG_ID}"
	@echo "OS                    default: unknown                               actual: ${OS}"
	@echo ""

stop:
	@docker rm -f $(DOCKER_IMAGE_NAME) >/dev/null 2>&1 || :

init: up

up:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant up

status:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant status

down: destroy

destroy:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant destroy -f

browse:
ifeq ($(OS),Darwin)
	@open http://127.0.0.1:8123
else
	@xdg-open http://127.0.0.1:8123
endif

.PHONY: default check stop init up status down destroy browse