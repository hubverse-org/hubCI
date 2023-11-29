
<!-- README.md is generated from README.Rmd. Please edit that file -->

# hubCI <img src="man/figures/logo.png" align="right" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/hubCI)](https://CRAN.R-project.org/package=hubCI)
[![Codecov test
coverage](https://codecov.io/gh/Infectious-Disease-Modeling-Hubs/hubCI/branch/main/graph/badge.svg)](https://app.codecov.io/gh/Infectious-Disease-Modeling-Hubs/hubCI?branch=main)
[![R-CMD-check](https://github.com/Infectious-Disease-Modeling-Hubs/hubCI/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Infectious-Disease-Modeling-Hubs/hubCI/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of hubCI is to provide functionality for setting up hubverse
Continuous Integration workflows.

## Installation

You can install the development version of hubCI like so:

``` r
# install.packages("remotes")

remotes::install_github("Infectious-Disease-Modeling-Hubs/hubCI")
```

## Example

### Setting up a GitHub Action

For hubs hosted on GitHub, use `use_hub_github_action()` to download one
of the [hubverse GitHub
Actions](https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions).

*Note: the hub most be configured as an R project (i.e. contain a
`*.Rproj` file)*

``` r
library(hubCI)

use_hub_github_action(name = "validate-submission")
```
