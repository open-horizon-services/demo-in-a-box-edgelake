# The Open Horizon organization ID namespace where you will be publishing files
export HZN_ORG_ID ?= myorg

# Which system configuration to be provisioned
export SYSTEM_CONFIGURATION ?= unicycle
export VAGRANT_HUB := "./configuration/Vagrantfile.hub"
export VAGRANT_VAGRANTFILE := "./configuration/Vagrantfile.${SYSTEM_CONFIGURATION}"
export VAGRANT_TEMPLATE := "./configuration/Vagrantfile.${SYSTEM_CONFIGURATION}.template"

# Detect Operating System running Make
OS := $(shell uname -s)

default: status

check:
	@echo "=====================     ============================================="
	@echo "ENVIRONMENT VARIABLES     VALUES"
	@echo "=====================     ============================================="
	@echo "SYSTEM_CONFIGURATION      ${SYSTEM_CONFIGURATION}"
	@echo "VAGRANT_HUB               ${VAGRANT_HUB}"
	@echo "VAGRANT_TEMPLATE          ${VAGRANT_TEMPLATE}"
	@echo "VAGRANT_VAGRANTFILE       ${VAGRANT_VAGRANTFILE}"
	@echo "HZN_ORG_ID                ${HZN_ORG_ID}"
	@echo "OS                        ${OS}"
	@echo "=====================     ============================================="
	@echo ""

init: up-hub up

up-hub: 
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant up | tee summary.txt
	@tail -n 2 summary.txt | cut -c 16- > mycreds.env
	@rm summary.txt

up: 
	$(eval export HZN_EXCHANGE_USER_AUTH := $(shell source mycreds.env && echo $$HZN_EXCHANGE_USER_AUTH))
	@envsubst < $(VAGRANT_TEMPLATE) > $(VAGRANT_VAGRANTFILE)
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant up
	@rm mycreds.env
#	@rm $(VAGRANT_VAGRANTFILE)

connect-hub:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant ssh

connect:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant ssh

status:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant status

status-hub:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant status

down: destroy destroy-hub clean

clean:
	@rm $(VAGRANT_VAGRANTFILE)

destroy:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_VAGRANTFILE) vagrant destroy -f

destroy-hub:
	@VAGRANT_VAGRANTFILE=$(VAGRANT_HUB) vagrant destroy -f

browse:
ifeq ($(OS),Darwin)
	@open http://127.0.0.1:8123
else
	@xdg-open http://127.0.0.1:8123
endif

.PHONY: default check init up-hub up status down destroy browse connect clean connect-hub status-hub destroy-hub