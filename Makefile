.DEFAULT_GOAL := provision

include .env

ACTIVATE = . venv/bin/activate;
ANSIBLE = $(ACTIVATE) \
			VPS_ALIAS=$(VPS_ALIAS) \
			VPS_IP=$(VPS_IP) \
			VPS_USER=$(VPS_USER) \
			ansible-playbook -i vps/inventory/inventory.py

.git/hooks/pre-commit:
	$(ACTIVATE) pre-commit install
	@touch $@

venv: venv/.touchfile .git/hooks/pre-commit
venv/.touchfile: requirements.txt
	test -d venv || virtualenv venv
	$(ACTIVATE) pip install -Ur requirements.txt
	@touch $@

pass: venv
	@$(ACTIVATE) python -c "from passlib.hash import sha512_crypt; import getpass; print(sha512_crypt.hash(getpass.getpass()))"

bootstrap: venv
	@$(ANSIBLE) vps/bootstrap.yaml --ask-pass \
		-e "vps_alias=$(VPS_ALIAS)" \
		-e "vps_ip=$(VPS_IP)" \
		-e "vps_user=$(VPS_USER)" \
		-e "vps_key_file=$(VPS_KEY_FILE)"

provision: venv
	@$(ANSIBLE) vps/provision.yaml --ask-pass

check: venv
	@$(ACTIVATE) pre-commit run --all

clean:
	@git clean -Xdf

.PHONY: setup check clean
