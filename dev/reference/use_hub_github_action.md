# Hubverse GitHub Actions workflow setup

Sets up common continuous integration (CI) workflows for a hub that is
hosted on GitHub using [GitHub
Actions](https://github.com/features/actions). Available workflows are
hosted in repository
[hubverse-org/hubverse-actions](https://github.com/hubverse-org/hubverse-actions)
The function creates the necessary directories and downloads the
requested workflow `.yaml` file.

## Usage

``` r
use_hub_github_action(name, ref = NULL, overwrite = FALSE)
```

## Arguments

- name:

  Name of workflow, i.e. the name of one of the [workflow
  repository](https://github.com/hubverse-org/hubverse-actions)
  directories holding a workflow `.yaml` file of the same name. Asking
  for anything else, such as a composite action, lists the workflows a
  hub can add.

- ref:

  Desired Git reference, usually the name of a tag (`"v0.1.0"`) or
  branch (`"main"`, including branch names containing slashes such as
  `"ak/my-feature/27"`). Other possibilities include a commit SHA
  (`"d1c516d"`) or `"HEAD"` (meaning "tip of remote's default branch").
  If not specified, defaults to the latest published release of
  `hubverse-org/hubverse-actions`
  (<https://github.com/hubverse-org/hubverse-actions/releases>)

- overwrite:

  Whether to replace files that already exist. If `FALSE`, an
  interactive session asks first, and a non-interactive session stops
  with an error.

## Value

The paths of the workflow files written, invisibly, or an empty
character vector if existing files were left in place. Called for the
side effect of writing `.github/workflows/<name>.yaml`.

## Details

The workflow is written to the root of the hub, i.e. the closest
enclosing directory containing a `hub-config/` directory, falling back
to the working directory if there is none within the repository you are
in.

Some workflows only work as a pair, one running the checks and another
posting their result, and are added together: asking for
`"validate-submission"` also adds `"validate-submission-comment"`.

Existing workflow files are replaced when `overwrite = TRUE`. Otherwise
an interactive session asks once, listing them, and a non-interactive
session stops with an error. Nothing is written unless every file can
be, so a pair is always replaced together.

Inspired by `usethis::use_github_action()`, and additionally accepts
branch names containing slashes, which that function truncates at the
first slash.

## Examples

``` r
if (FALSE) { # \dontrun{
use_hub_github_action(name = "validate-submission")
} # }
```
