
<!-- README.md is generated from README.Rmd. Please edit that file -->

# hubCI <img src="man/figures/logo.png" align="right" height="131" alt="" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/hubCI)](https://CRAN.R-project.org/package=hubCI)
[![Codecov test
coverage](https://codecov.io/gh/hubverse-org/hubCI/branch/main/graph/badge.svg)](https://app.codecov.io/gh/hubverse-org/hubCI?branch=main)
[![R-CMD-check](https://github.com/hubverse-org/hubCI/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/hubverse-org/hubCI/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

The goal of hubCI is to provide functionality for setting up hubverse
Continuous Integration workflows.

## Installation

### Latest

You can install the [latest version of hubCI from the
R-universe](https://hubverse-org.r-universe.dev/hubCI):

``` r
install.packages("hubCI", repos = c("https://hubverse-org.r-universe.dev", "https://cloud.r-project.org"))
```

### Development

If you want to test out new features that have not yet been released,
you can install the development version of hubCI from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")

remotes::install_github("hubverse-org/hubCI")
```

## Example

### Setting up a GitHub Action

For hubs hosted on GitHub, use `use_hub_github_action()` to download one
of the [hubverse GitHub
Actions](https://github.com/hubverse-org/hubverse-actions).

*Note: the hub most be configured as an R project (i.e. contain a
`*.Rproj` file)*

``` r
library(hubCI)

use_hub_github_action(name = "validate-submission")
```

### Keeping the workflows’ actions up to date

The workflows depend on other GitHub Actions, both third-party actions
such as `actions/checkout` and the hubverse actions themselves. An
action referenced by major version picks up minor and patch releases
automatically, but a new major release does not reach the hub until the
workflow is edited.

`use_hub_dependabot()` installs a configuration file at
`.github/dependabot.yml`. This file configures
[Dependabot](https://docs.github.com/en/code-security/dependabot),
GitHub’s dependency update service, to check the actions the hub’s
workflows depend on once a week. For each action with a new major
version, Dependabot opens a pull request in the hub that updates the
workflow to it. This keeps the hub’s workflow dependencies current, with
each update reviewed rather than discovered when an old version stops
working.

``` r
use_hub_dependabot()
```

------------------------------------------------------------------------

## Code of Conduct

Please note that the hubCI package is released with a [Contributor Code
of Conduct](.github/CODE_OF_CONDUCT.md). By contributing to this
project, you agree to abide by its terms.

## Contributing

Interested in contributing back to the open-source Hubverse project?
Learn more about how to [get involved in the Hubverse
Community](https://hubverse.io/community/) or [how to contribute to the
hubCI package](.github/CONTRIBUTING.md).
