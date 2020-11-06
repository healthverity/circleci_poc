COVERAGE_THRESHOLD ?= 70
LINT_THRESHOLD ?= 9
REPO_NAME=$(shell basename `git rev-parse --show-toplevel`)

create-venv:
	virtualenv --python=3 $(REPO_NAME)_venv
	$(REPO_NAME)_venv/bin/pip3 install .
	$(REPO_NAME)_venv/bin/pip3 install -r test/test-requirements.txt

clean-venv:
	rm -rf $(REPO_NAME)_venv

clean-docker:
	docker-compose down --rmi all --remove-orphans -v

clean: clean-venv clean-docker

build:
	docker-compose build --no-cache cli

localstack-up:
	docker-compose up -d pennyworth-localstack

localstack-down:
	docker-compose down pennyworth-localstack

test: lint coverage

unit-test:
	docker-compose run --name "$(BUILD_ID)" --rm cli \
		python -m pytest test/unit --junitxml=./unit_test.xml

system-test:
	docker-compose run --name "$(BUILD_ID)" --rm cli \
		python -m pytest test/system --junitxml=./system_test.xml

coverage:
	docker-compose run --name "$(BUILD_ID)" --rm cli \
		python -m pytest test --junitxml=./test.xml --cov=. --cov-report xml

unit-coverage:
	docker-compose run --name "$(BUILD_ID)" --rm cli \
		python -m pytest test/unit --junitxml=./unit_test.xml --cov=. --cov-report xml:./unit_coverage.xml

system-coverage:
	docker-compose run --name "$(BUILD_ID)" --rm cli \
		python -m pytest test/system --junitxml=./system_test.xml --cov=. --cov-report xml:./system_coverage.xml

lint:
	docker-compose run --name "$(BUILD_ID)" --rm cli \
		python -m pylint --fail-under=$(LINT_THRESHOLD)

inject-package-version:
	echo "__version__ = '$(VERSION)'" >> package_name/__init__.py

dist-package:
	./bin/dist-package.sh
