requirements.txt:
	curl -sLo $@ https://raw.githubusercontent.com/getsentry/sentry/3ca31eee26246450d20501764993fc89eb9547ff/requirements-base.txt
	# 2.0.20 is the first version that builds on 3.10
	sed -i 's/uWSGI==2.0.19.1/uWSGI==2.0.20/' $@

.github/workflows/benchmark.yml: Makefile templates/workflow_preamble.yml templates/workflow_tool.yml
	./bin/build_workflow.sh > $@

PACKAGE := goodconf

.PHONY: pip-clean
pip-clean:
	rm -rf ~/.cache/pip

TOOLS := poetry
.PHONY: poetry-tooling
poetry-tooling:
	curl -sSL https://install.python-poetry.org | python3 -
.PHONY: poetry-import
poetry-import:
	cd poetry; poetry add $$(sed -e 's/#.*//' -e '/^$$/ d' < ../requirements.txt)
.PHONY: poetry-clean-cache
poetry-clean-cache: pip-clean
	cd poetry; poetry cache clear --all --no-interaction .
.PHONY: poetry-clean-venv
poetry-clean-venv:
	cd poetry; poetry env remove python || true
.PHONY: poetry-clean-lock
poetry-clean-lock:
	cd poetry; rm -f poetry.lock
.PHONY: poetry-lock
poetry-lock:
	cd poetry; poetry lock
.PHONY: poetry-install
poetry-install:
	cd poetry; poetry install
.PHONY: poetry-add-package
poetry-add-package:
	cd poetry; poetry add $(PACKAGE)
.PHONY: poetry-version
poetry-version:
	@poetry --version | awk '{print $$3}'

TOOLS := "$(TOOLS) pdm"
.PHONY: pdm-tooling
pdm-tooling:
	curl -sSL https://raw.githubusercontent.com/pdm-project/pdm/main/install-pdm.py | python3 -
	pdm config python.use_venv false
.PHONY: pdm-import
pdm-import:
	cd pdm; pdm import -f requirements ../requirements.txt
.PHONY: pdm-clean-cache
pdm-clean-cache: pip-clean
	rm -rf ~/.cache/pdm
.PHONY: pdm-clean-venv
pdm-clean-venv:
	rm -rf pdm/__pypackages__
.PHONY: pdm-clean-lock
pdm-clean-lock:
	rm -f pdm/pdm.lock
.PHONY: pdm-lock
pdm-lock:
	cd pdm; pdm lock
.PHONY: pdm-install
pdm-install:
	cd pdm; pdm install
.PHONY: pdm-add-package
pdm-add-package:
	cd pdm; pdm add $(PACKAGE)
.PHONY: pdm-version
pdm-version:
	@pdm --version | awk '{print $$3}'


TOOLS := "$(TOOLS) pipenv"
.PHONY: pipenv-tooling
pipenv-tooling:
	pip install --user pipenv
.PHONY: pipenv-import
pipenv-import:
	cd pipenv; pipenv install -r ../requirements.txt
.PHONY: pipenv-clean-cache
pipenv-clean-cache: pip-clean
	rm -rf ~/.cache/pipenv
.PHONY: pipenv-clean-venv
pipenv-clean-venv:
	cd pipenv; rm -rf $$(pipenv --venv || echo "./does-not-exist")
.PHONY: pipenv-clean-lock
pipenv-clean-lock:
	rm -f pipenv/Pipfile.lock
.PHONY: pipenv-lock
pipenv-lock:
	cd pipenv; pipenv lock
.PHONY: pipenv-install
pipenv-install:
	cd pipenv; pipenv sync
.PHONY: pipenv-add-package
pipenv-add-package:
	cd pipenv; pipenv install $(PACKAGE)
.PHONY: pipenv-version
pipenv-version:
	@pipenv --version | awk '{print $$3}'

.PHONY: tools
tools:
	@echo $(TOOLS)