requirements.txt:
	curl -sLo $@ https://raw.githubusercontent.com/getsentry/sentry/3ca31eee26246450d20501764993fc89eb9547ff/requirements-base.txt
	# 2.0.20 is the first version that builds on 3.10
	sed -i 's/uWSGI==2.0.19.1/uWSGI==2.0.20/' $@

PACKAGE := goodconf

.PHONY: pip-clean
pip-clean:
	rm -rf ~/.cache/pip

.PHONY: poetry-tooling
poetry-tooling:
	curl -sSL https://install.python-poetry.org | python3 -
.PHONY: poetry-import
poetry-import:
	cd poetry; poetry add $$(sed -e 's/#.*//' -e '/^$$/ d' < ../requirements.txt)
.PHONY: poetry-clean-cache
poetry-clean-cache: pip-clean
	cd poetry; poetry cache clear --all --no-interaction pypi
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