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
use_hub_github_action(name, ref = NULL)
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

## Value

The paths of the workflow files added, invisibly. Called for the side
effect of writing `.github/workflows/<name>.yaml`.

## Details

The workflow is written to the root of the hub, i.e. the closest
enclosing directory containing a `hub-config/` directory, falling back
to the working directory if there is none within the repository you are
in.

Some workflows only work as a pair, one running the checks and another
posting their result, and are added together: asking for
`"validate-submission"` also adds `"validate-submission-comment"`.

If the workflow file already exists, it is left alone when its contents
match what is being downloaded. Otherwise, an interactive session asks
before overwriting it, while a non-interactive one overwrites it and
reports that it has done so, so that an unattended run leaves the hub on
the requested ref. Local edits to a workflow you asked for will not
survive such a run. A paired workflow you did not ask for is the
exception: local changes to it stand unless you confirm the overwrite,
or ask for it by name.

Inspired by
[`usethis::use_github_action()`](https://usethis.r-lib.org/reference/use_github_action.html),
and additionally accepts branch names containing slashes, which that
function truncates at the first slash.

## Examples

``` r
if (FALSE) { # \dontrun{
use_hub_github_action(name = "validate-submission")
} # }
```
