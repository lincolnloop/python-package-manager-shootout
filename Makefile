SHELL=/bin/bash -eu -o pipefail


requirements.txt:
	curl -sL $@ https://raw.githubusercontent.com/getsentry/sentry/51281a6abd8ff4a93d2cebc04e1d5fc7aa9c4c11/requirements-base.txt | grep -v -- --index-url > $@

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
	pipx install poetry
	poetry config virtualenvs.in-project true
poetry-import:
	cd poetry; poetry add $$(sed -e 's/#.*//' -e '/^$$/ d' < ../requirements.txt)
poetry-clean-cache: pip-clean
	rm -rf ~/.cache/pypoetry
poetry-clean-venv:
	cd poetry; poetry env remove --all || true
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
	rm -rf pdm/.venv pdm/__pypackages__
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

TOOLS := "$(TOOLS) pdm-uv"
.PHONY: pdm-uv-tooling pdm-uv-import pdm-uv-clean-cache pdm-uv-clean-venv pdm-uv-clean-lock pdm-uv-lock pdm-uv-install pdm-uv-add-package pdm-uv-version
pdm-uv-tooling:
	pipx install pdm
	pipx install uv
	pdm config use_uv true
	pdm config python.use_venv True
pdm-uv-import:
	cd pdm-uv; pdm import -f requirements ../requirements.txt
pdm-uv-clean-cache: pip-clean
	rm -rf ~/.cache/pdm
	rm -rf ~/.cache/uv
pdm-uv-clean-venv:
	rm -rf pdm/.venv pdm/__pypackages__
pdm-uv-clean-lock:
	rm -f pdm/pdm.lock
pdm-uv-lock:
	cd pdm-uv; pdm lock
pdm-uv-install:
	cd pdm-uv; pdm install
pdm-uv-update:
	cd pdm-uv; pdm update
pdm-uv-add-package:
	cd pdm-uv; pdm add $(PACKAGE)
pdm-uv-version:
	@echo "PDM ${pdm --version | awk '{print $$3}'} - UV ${uv --version | awk '{print $$2}}"

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
	pip-sync --python-executable=./pip-tools/.venv/bin/python --pip-args '--no-deps' pip-tools/requirements.txt
pip-tools-update:
	pip-compile --generate-hashes --resolver=backtracking --output-file=pip-tools/requirements.txt requirements.txt
	pip-sync --python-executable=./pip-tools/.venv/bin/python --pip-args '--no-deps' pip-tools/requirements.txt
pip-tools-add-package:
	echo $(PACKAGE) >> requirements.txt
	$(MAKE) pip-tools-lock pip-tools-install
pip-tools-version:
	@pip-compile --version | awk '{print $$3}'

TOOLS := "$(TOOLS) uv"
.PHONY: uv-tooling uv-import uv-clean-cache uv-clean-venv uv-clean-lock uv-lock uv-install uv-add-package uv-version
uv-tooling:
	pip install --user uv
uv-import:
	cd uv; uv add --frozen -r ../requirements.txt
uv-clean-cache:
	rm -rf ~/.cache/uv
uv-clean-venv:
	rm -rf uv/.venv
uv-clean-lock:
	rm -f uv/uv.lock
uv-lock:
	cd uv; uv lock
uv-install:
	cd uv; uv sync
uv-update:
	cd uv; uv sync --upgrade
uv-add-package:
	cd uv; uv add $(PACKAGE)
uv-version:
	@uv --version | awk '{print $$2}'

.PHONY: tools
tools:
	@echo $(TOOLS)
