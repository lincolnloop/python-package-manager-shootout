# Python Package Manager Shootout

Benchmarking the performance of different Python package managers via GitHub Actions.

The list of packages comes from [Sentry's `requirements.txt file`](https://github.com/getsentry/sentry/blob/3ca31eee26246450d20501764993fc89eb9547ff/requirements-base.txt) which was chosen arbitrarily as a non-trivial real-world example.

## Package Managers

* [`pdm`](https://pdm.fming.dev/latest/)
* [`pip-tools`](https://pip-tools.readthedocs.io/)
* [`pipenv`](https://pipenv.pypa.io/)
* [`poetry`](https://python-poetry.org/) (the current `--pre` release is also tested)

Additional package managers are welcome (see _Contributing_ below). At a minimum, they should be able to generate a lock file for the dependency set and download/install the dependencies locally.

## Operations

The following operations are measured in the benchmark:

* `tooling` - Installing the package manager using its recommended method.
* `import` - Importing/converting the `requirements.txt` to the native format for the package manager. _Note: this benchmark is problematic because some tools also install the packages in this step._
* `lock` - Generating a lockfile for the packages.
* `install-cold` - Installing the packages with an empty cache.
* `install-warm` - Installing the packages with a pre-populated cache.
* `update` - Update the lock file and install updated packages.
* `add-package` - Installing a new package and updating the lock file.

## Results

Results can be seen at https://lincolnloop.github.io/python-package-manager-shootout/ and in the summary for each individual [GitHub Action run](https://github.com/lincolnloop/python-package-manager-shootout/actions/workflows/benchmark.yml). An artifact named `stats` is created which contains the results in CSV and SQLite format.

## Contributing

The `Makefile` defines all the operations used in the benchmark. Any package-manager specific code should be modified there. The workflow (`.github/workflows/benchmark.yml`) is generated programmatically and is the same for each package manager.

To add a new package manager:

1. Copy the block in the `Makefile` for one of the existing package managers and modify it to use the commands provided by the new package manager.
2. Add a directory with the same name as the package manager. Add any required files (e.g. `pyproject.toml`) to the directory *without* the dependencies. If no files are required, add an empty `.gitignore` to the directory.
3. Run `make github-workflow` to regenerate the workflow file.

## Website

The website is a static site deployed to GitHub Pages. As part of the deployment it downloads stats from the previous 6 benchmarks (run every 6 hours in GitHub Actions), calculates the average, and rebuilds the website. The code for this is in `site` and `.github/workflows/deploy.yml`. The site will automatically rebuild after the benchmarks run, but it can also be triggered by pushing to the `deploy/site` branch.