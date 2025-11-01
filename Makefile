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
	rm -rf build lambda_ingest/lambda.zip
	mkdir -p build/python
	# Install runtime deps into build/ (root of the zip)
	pip install -r requirements.txt -t build >/dev/null
	# Add your package under the correct folder name
	mkdir -p build/lambda_ingest
	cp -r lambda_ingest/*.py build/lambda_ingest/
	# Ensure it's a package
	touch build/lambda_ingest/__init__.py
	# Zip everything from build/ as the root of the zip
	cd build && zip -qr ../lambda_ingest/lambda.zip .
	@echo "Built lambda_ingest/lambda.zip"