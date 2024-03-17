.DEFAULT_GOAL := provision

include .env

ACTIVATE = . venv/bin/activate;
ASSETS = $(shell find assets -type f -name '*')
ANSIBLE = $(ACTIVATE) \
			VPS_ALIAS=$(VPS_ALIAS) \
			VPS_IP=$(VPS_IP) \
			VPS_USER=$(VPS_USER) \
			ansible-playbook -i vps/inventory/inventory.py
PROJECT_NAME = tifa

.git/hooks/pre-commit:
	$(ACTIVATE) pre-commit install
	@touch $@

venv: venv/.touchfile .git/hooks/pre-commit
venv/.touchfile: requirements.txt
	test -d venv || virtualenv venv
	$(ACTIVATE) pip install -Ur requirements.txt
	@touch $@

.PHONY: check
check: venv
	@$(ACTIVATE) pre-commit run --all
	@$(ACTIVATE) pre-commit run --hook-stage push

.PHONY: bootstrap
bootstrap: venv
	@$(ANSIBLE) vps/bootstrap.yaml --ask-pass \
		-e "vps_alias=$(VPS_ALIAS)" \
		-e "vps_ip=$(VPS_IP)" \
		-e "vps_user=$(VPS_USER)" \
		-e "vps_key_file=$(VPS_KEY_FILE)"

.PHONY: provision
provision: venv
	@$(ANSIBLE) vps/provision.yaml

build: venv/.build_touchfile
venv/.build_touchfile: Dockerfile $(ASSETS)
	@docker build -t proxy .
	@touch $@

.PHONY: start
start: cert build network
	@docker compose --project-name $(PROJECT_NAME) up --detach

.PHONY: stop
stop:
	@docker compose --project-name $(PROJECT_NAME) down --remove-orphans
	@$(MAKE) network-stop

.PHONY: restart
restart: stop start

.PHONY: cert
cert: cert-$(ENVIRONMENT)

.PHONY: cert-prod
cert-prod:

.PHONY: cert-dev
cert-dev:
	$(eval CERT_HOSTNAMES=$(shell echo $(CERT_HOSTNAMES) | awk 'BEGIN{OFS=", "; RS=","; prefix="DNS:"} {$$1=prefix $$1} {printf("%s%s", NR==1 ? "" : OFS, $$1)} END {printf("\n")}'))
	@HOSTNAME="$(HOSTNAME)" \
		CERT_HOSTNAMES="$(CERT_HOSTNAMES)" \
		envsubst < ./assets/traefik/dev/certs/dev.ext > ./assets/traefik/dev/certs/dev.ext.tmp; \
	docker run --rm -it -v ./assets/traefik/dev/certs/:/etc/traefik/certs/ \
		-w /etc/traefik/certs/ \
		alpine/openssl req \
			-newkey rsa:2048 -x509 -nodes -new -sha256 -days 365 \
    		-keyout "dev.key" -out "dev.crt" -subj "/CN=$(HOSTNAME)" \
    		-reqexts req_ext -extensions req_ext -config dev.ext.tmp
	@[ "$(shell uname -s)" != "Darwin" ] || sudo security delete-certificate -c "$(HOSTNAME)" /Library/Keychains/System.keychain
	@[ "$(shell uname -s)" != "Darwin" ] || sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./assets/traefik/dev/certs/dev.crt

.PHONY: network
network:
	@docker network create $(PROJECT_NAME) || true

.PHONY: network-stop
network-stop:
	@docker network rm $(PROJECT_NAME) || true

.PHONY: clean
clean:
	@git clean -Xdf
