
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

------------------------------------------------------------------------

## Code of Conduct

Please note that the hubCI package is released with a [Contributor Code
of Conduct](.github/CODE_OF_CONDUCT.md). By contributing to this
project, you agree to abide by its terms.

## Contributing

Interested in contributing back to the open-source Hubverse project?
Learn more about how to [get involved in the Hubverse
Community](https://docs.hubverse.io/en/latest/overview/contribute.html) or
[how to contribute to the hubCI package](.github/CONTRIBUTING.md).
