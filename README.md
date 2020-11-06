# Template repo setup
To get started with the template repo, run
```bash
./setup_repo.sh
```
Follow the prompts given to choose your configuration(s) and do any initialization steps for said configuration(s).
If a configuration has customization steps or prompts, they are run automatically when choosing that configuration.

# Available configurations
## `generic`
A configuration not tied to any language with some standard workflow and config files for things like Docker, Make, and Jenkins.
## `python`
A configuration setup for Python development. Includes a full Jenkins, Docker, and Make workflow with linting, testing, and coverage all setup and configured.
## `python-package`
Like the `python` configuration, but setup specifically for developing an installable Python package. Includes steps for publishing the package internally.
## `react`
An "addon" configuration meant to be used alongside another configuration. Includes setup for creating React apps and integration with our internal `parker` repo. If using this config, make sure when running `setup_repo.sh` that you first install one of the other configurations first, then this one, as it makes changes to some files that are present in the other configurations but not in this one.

# Creating new configurations
If you would like to add a new configuration option to Pennyworth, it needs to have a `.config` file. This is just an empty file, so you don't need to have anything in it. You may optionally include an `init_config.sh` file. If this is present in the configuration directory, it will be called and run if the configuration is chosen when running `setup_repo.sh`. 
