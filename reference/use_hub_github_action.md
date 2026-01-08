# Hubverse GitHub Action setup

Sets up common continuous integration (CI) workflows for a hub that is
hosted on GitHub using [GitHub
Actions](https://github.com/features/actions). Available actions are
hosted in repository
[hubverse-org/hubverse-actions](https://github.com/hubverse-org/hubverse-actions)
The function creates the necessary directories and downloads the
requested GitHub Action yaml file.

## Usage

``` r
use_hub_github_action(name, ref = NULL)
```

## Arguments

- name:

  Name of workflow, i.e. the name of one of the [action
  repository](https://github.com/hubverse-org/hubverse-actions)
  directories containing a GitHub Action workflow `.yaml` file.

- ref:

  Desired Git reference, usually the name of a tag (`"v0.1.0"`) or
  branch (`"main"`). Other possibilities include a commit SHA
  (`"d1c516d"`) or `"HEAD"` (meaning "tip of remote's default branch").
  If not specified, defaults to the latest published release of
  `hubverse-org/hubverse-actions`
  (<https://github.com/hubverse-org/hubverse-actions/releases>)

## Examples

``` r
if (FALSE) { # \dontrun{
use_hub_github_action(name = "validate-submission")
} # }
```
