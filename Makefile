SHELL=/bin/bash -eu -o pipefail


requirements.txt:
	curl -sL $@ https://raw.githubusercontent.com/getsentry/sentry/f1e1642d46ee4ee3a74cbce961a3e47406a68f0b/requirements-base.txt | grep -v -- --index-url > $@
	# fix bad version string
	sed -i 's/pyuwsgi==2.0.20.0/pyuwsgi==2.0.20/' $@

.github/workflows/benchmark.yml: Makefile bin/build_workflow.sh templates/workflow_start.yml templates/workflow_tool.yml templates/workflow_end.yml
	./bin/build_workflow.sh > $@

.PHONY: github-workflow
github-workflow: .github/workflows/benchmark.yml

# random package to benchmark adding a new dependency
PACKAGE := goodconf

.PHONY: pip-clean
pip-clean:
	rm -rf ~/.cache/pip

TOOLS := poetry
.PHONY: poetry-tooling poetry-import poetry-clean-cache poetry-clean-venv poetry-clean-lock poetry-lock poetry-install poetry-add-package poetry-version
poetry-tooling:
	curl -sSL https://install.python-poetry.org | python3 -
poetry-import:
	cd poetry; poetry add $$(sed -e 's/#.*//' -e '/^$$/ d' < ../requirements.txt)
poetry-clean-cache: pip-clean
	rm -rf ~/.cache/pypoetry
poetry-clean-venv:
	cd poetry; poetry env remove python || true
poetry-clean-lock:
	rm -f poetry/poetry.lock
poetry-lock:
	cd poetry; poetry lock
poetry-install:
	cd poetry; poetry install
poetry-update:
	cd poetry; poetry update
poetry-add-package:
	cd poetry; poetry add $(PACKAGE)
poetry-version:
	@poetry --version | awk '{print $$3}' | tr -d ')'

TOOLS := "$(TOOLS) pdm"
.PHONY: pdm-tooling pdm-import pdm-clean-cache pdm-clean-venv pdm-clean-lock pdm-lock pdm-install pdm-add-package pdm-version
pdm-tooling:
	curl -sSL https://raw.githubusercontent.com/pdm-project/pdm/main/install-pdm.py | python3 -
pdm-import:
	cd pdm; pdm import -f requirements ../requirements.txt
pdm-clean-cache: pip-clean
	rm -rf ~/.cache/pdm
pdm-clean-venv:
	rm -rf pdm/__pypackages__
	mkdir -p pdm/__pypackages__
pdm-clean-lock:
	rm -f pdm/pdm.lock
pdm-lock:
	cd pdm; pdm lock
pdm-install:
	cd pdm; pdm install
pdm-update:
	cd pdm; pdm update
pdm-add-package:
	cd pdm; pdm add $(PACKAGE)
pdm-version:
	@pdm --version | awk '{print $$3}'


TOOLS := "$(TOOLS) pipenv"
.PHONY: pipenv-tooling pipenv-import pipenv-clean-cache pipenv-clean-venv pipenv-clean-lock pipenv-lock pipenv-install pipenv-add-package pipenv-version
pipenv-tooling:
	pip install --user pipenv
pipenv-import:
	cd pipenv; pipenv install -r ../requirements.txt
pipenv-clean-cache: pip-clean
	rm -rf ~/.cache/pipenv
pipenv-clean-venv:
	cd pipenv; rm -rf $$(pipenv --venv || echo "./does-not-exist")
pipenv-clean-lock:
	rm -f pipenv/Pipfile.lock
pipenv-lock:
	cd pipenv; pipenv lock
pipenv-install:
	cd pipenv; pipenv sync
pipenv-update:
	cd pipenv; pipenv update
pipenv-add-package:
	cd pipenv; pipenv install $(PACKAGE)
pipenv-version:
	@pipenv --version | awk '{print $$3}'


TOOLS := "$(TOOLS) pip-tools"
.PHONY: pip-tools-tooling pip-tools-import pip-tools-clean-cache pip-tools-clean-venv pip-tools-clean-lock pip-tools-lock pip-tools-install pip-tools-add-package pip-tools-version
pip-tools-tooling:
	pip install --user pip-tools
pip-tools-import:
	cat requirements.txt
pip-tools-clean-cache: pip-clean
	rm -rf ~/.cache/pip-tools
pip-tools-clean-venv:
	rm -rf pip-tools/.venv
pip-tools-clean-lock:
	rm -f pip-tools/requirements.txt
pip-tools-lock:
	pip-compile --generate-hashes --resolver=backtracking --output-file=pip-tools/requirements.txt requirements.txt
pip-tools-install:
	test -f pip-tools/.venv/bin/python || python -m venv --upgrade-deps pip-tools/.venv
	test -f pip-tools/.venv/bin/wheel || ./pip-tools/.venv/bin/python -m pip install -U wheel
	pip-sync --python-executable=./pip-tools/.venv/bin/python pip-tools/requirements.txt
pip-tools-update:
	pip-compile --generate-hashes --resolver=backtracking --output-file=pip-tools/requirements.txt requirements.txt
	pip-sync --python-executable=./pip-tools/.venv/bin/python pip-tools/requirements.txt
pip-tools-add-package:
	echo $(PACKAGE) >> requirements.txt
	$(MAKE) pip-tools-lock pip-tools-install
pip-tools-version:
	@pip-compile --version | awk '{print $$3}'


TOOLS := "$(TOOLS) rye"
.PHONY: rye-tooling rye-import rye-clean-cache rye-clean-venv rye-clean-lock rye-lock rye-install rye-add-package rye-version
rye-tooling:
	curl -sSf https://rye-up.com/get -o /tmp/install.sh
	sed -i 's/self install/self install --yes/' /tmp/install.sh
	bash /tmp/install.sh
	source "$HOME/.rye/env"
rye-import:
	cd rye; rye add $$(sed -e 's/#.*//' -e '/^$$/ d' < ../requirements.txt)
rye-clean-cache: pip-clean
rye-clean-venv:
	cd rye; rm -rf .venv
rye-clean-lock:
	rm -f rye/requirements.lock
rye-lock:
	cd rye; rye lock
rye-install:
	cd rye; rye sync
rye-update:
	cd rye; rye lock --update-all
rye-add-package:
	cd rye; rye add $(PACKAGE)
rye-version:
	@rye --version 2>&1 | grep commit | cut -d' ' -f3-

.PHONY: tools
tools:
	@echo $(TOOLS)
