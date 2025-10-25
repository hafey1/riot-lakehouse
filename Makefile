SHELL := /bin/bash
PY := python
PIP := pip

.PHONY: install hooks lint lint-fix check clean-py freeze

# One-shot: install deps & git hooks
install:
	$(PIP) install -r requirements.txt
	pre-commit install
	@echo "✅ Python deps + pre-commit hooks installed"

# Run pre-commit across repo (same checks that fire on commit)
hooks:
	pre-commit run --all-files

clean-ruff:
	rm -rf .ruff_cache

# Fast linter
lint:
	ruff check .

# Auto-fix with ruff (safe for imports/formatting)
lint-fix:
	ruff check --fix .

# Quick sanity: lint, then pre-commit checks
check: lint
	pre-commit run --all-files

# Clean typical Python artifacts
clean-py:
	find . -type d -name "__pycache__" -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

# (Optional) snapshot resolved versions for reproducibility
freeze:
	$(PIP) freeze > requirements-lock.txt && echo "Wrote requirements-lock.txt"

test:
	pytest -q

lambda-zip:
	cd lambda_ingest && mkdir -p package && \
		pip install -r requirements.txt -t package >/dev/null && \
		cp -r *.py package/ && \
		cd package && zip -qr ../lambda.zip .
	@echo "Built lambda_ingest/lambda.zip"