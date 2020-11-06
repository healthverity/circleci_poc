<img src="https://vignette.wikia.nocookie.net/batman/images/e/ec/BD-3487.jpg/revision/latest?cb=20080418033124" height=150px>

# Pennyworth
Like the stalwart butler, this template repo is here to help make sure you're prepared for whatever you set off to do.
Replace this header with the name of the repo. This section should have a brief description of what this service does.

## Software prerequisites
- Python
- Docker

## Local development
You can create your own virtualenvironment or use
```bash
make create-venv
```
to make one with the projects requirements and test requirements installed.

## Deployment
Describe how to deploy this software to one of our environments (dev, sandbox, staging, prod).

### Run locally
This section should describe how to build and run the service locally.
```bash
make build
make deploy
```
You can start and stop localstack with
```bash
make start-localstack
make stop-localstack
```

## Test
This section should describe how to test the code. You can run linting with 
```bash
make lint
```
You can run unit tests, system tests, and all tests with
```bash
make unit-test
make system-test
make test
```
Coverage can be similarly be run with
```bash
make unit-coverage
make system-coverage
make coverage
```
Running tests and coverage produces XML reports (separately for both tests and coverage). These are automatically published to Jenkins when run there.

## Monitoring
Include any details surrounding monitoring here, including health checks, datadog/graylog monitoring, test results, static analysis results (linting and coverage), etc.
A graph of test results over builds will be visible when viewing the job on Jenkins. To view coverage results, click on "Coverage results" on the job's page. To learn more about the coverage report publishing/plugin, [take a look at these slides.](https://docs.google.com/presentation/d/1qrh6qJRxlVKwK6VgwvAd9V7mBCnE1qbmPF8CWMgpwWY/edit?usp=sharing)

## Further reading
This section should have/point to any more detailed information regarding how the service functions and the tools it uses.
You should also use the repo's wiki pages to document the extra information and explanations into how things work and
why they're designed the way they are. Leave the README simple and succinct.
