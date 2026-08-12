# The download-and-write flow follows usethis::use_github_file() and
# usethis::write_over() (MIT licensed, © Posit Software, PBC), reimplemented
# against the gh API. Unlike write_over(), a non-interactive session overwrites
# a differing file rather than refusing to.

#' Hubverse GitHub Action setup
#'
#' Sets up common continuous integration (CI) workflows for a hub
#' that is hosted on GitHub using
#' [GitHub Actions](https://github.com/features/actions).
#' Available actions are hosted in repository [hubverse-org/hubverse-actions](
#' https://github.com/hubverse-org/hubverse-actions)
#' The function creates the necessary directories and downloads the requested GitHub Action yaml file.
#' @param name Name of workflow, i.e. the name of one of the [action repository](
#' https://github.com/hubverse-org/hubverse-actions)
#' directories containing a GitHub Action workflow `.yaml` file.
#' @param ref Desired Git reference, usually the name of a tag (`"v0.1.0"`) or
#'   branch (`"main"`, including branch names containing slashes such as
#'   `"ak/my-feature/27"`). Other possibilities include a commit SHA (`"d1c516d"`)
#'   or `"HEAD"` (meaning "tip of remote's default branch"). If not specified,
#'   defaults to the latest published release of `hubverse-org/hubverse-actions`
#'   (<https://github.com/hubverse-org/hubverse-actions/releases>)
#'
#' @returns The path of the workflow file, invisibly. Called for the side
#'   effect of writing `.github/workflows/<name>.yaml`.
#'
#' @details
#' The workflow is written to the root of the hub, i.e. the closest enclosing
#' directory containing a `hub-config/` directory, falling back to the working
#' directory if there is none.
#'
#' If the workflow file already exists, it is left alone when its contents match
#' what is being downloaded. Otherwise, an interactive session asks before
#' overwriting it, while a non-interactive one overwrites it and reports that it
#' has done so.
#'
#' Inspired by `usethis::use_github_action()`, and additionally accepts branch
#' names containing slashes, which that function truncates at the first slash.
#' @export
#' @importFrom rlang "%||%"
#' @importFrom gh gh
#'
#' @examples
#' \dontrun{
#' use_hub_github_action(name = "validate-submission")
#' }
use_hub_github_action <- function(name, ref = NULL) {
  ref <- ref %||% latest_release()
  contents <- fetch_action_yaml(name, ref)

  wd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  root <- hub_root(wd)
  if (!identical(root, wd)) {
    rlang::inform(c(i = sprintf("Using hub root '%s'", root)))
  }
  rel_dir <- file.path(".github", "workflows")
  rel_path <- file.path(rel_dir, paste0(name, ".yaml"))
  path <- file.path(root, rel_path)

  existing <- file.exists(path)
  if (existing) {
    if (identical(readBin(path, "raw", n = file.size(path)), contents)) {
      rlang::inform(c(v = sprintf("Leaving '%s' unchanged", rel_path)))
      return(invisible(path))
    }
    if (!confirm_overwrite(rel_path)) {
      rlang::inform(c(x = sprintf("Not overwriting '%s'", rel_path)))
      return(invisible(path))
    }
  }

  dir <- file.path(root, rel_dir)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    rlang::inform(c(v = sprintf("Creating '%s/'", rel_dir)))
  }
  writeBin(contents, path)
  rlang::inform(c(
    v = sprintf(
      "%s '%s' from '%s'",
      if (existing) "Overwriting" else "Saving",
      rel_path,
      action_source(name, ref)
    )
  ))

  invisible(path)
}

# Download the contents of a workflow file from hubverse-actions. Uses the
# contents endpoint, which takes the ref as a query parameter and therefore
# handles refs containing slashes, unlike a `/blob/<ref>/<path>` URL, which
# cannot be split into ref and path unambiguously.
fetch_action_yaml <- function(name, ref, call = rlang::caller_env()) {
  contents <- rlang::try_fetch(
    gh(
      "/repos/{owner}/{repo}/contents/{path}",
      owner = actions_owner,
      repo = actions_repo,
      path = action_yaml_path(name),
      ref = ref,
      .accept = "application/vnd.github.raw"
    ),
    http_error_404 = function(cnd) {
      rlang::abort(
        c(
          sprintf("Could not download '%s'.", action_source(name, ref)),
          i = sprintf(
            "Check that '%s' exists at that ref in <https://github.com/%s/%s>.",
            action_yaml_path(name),
            actions_owner,
            actions_repo
          )
        ),
        parent = cnd,
        call = call
      )
    }
  )
  # gh returns the raw response with its own class attached, which writeBin
  # rejects.
  as.vector(contents)
}

# Locate the root of the hub containing `dir` (an already normalised path), i.e.
# where the workflow directory belongs. usethis::use_github_action() used to
# resolve this via the active project.
hub_root <- function(dir) {
  start <- dir
  repeat {
    if (dir.exists(file.path(dir, "hub-config"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      return(start)
    }
    dir <- parent
  }
}

confirm_overwrite <- function(path) {
  if (!interactive()) {
    return(TRUE)
  }
  isTRUE(utils::askYesNo(sprintf("Overwrite pre-existing file '%s'?", path)))
}

action_yaml_path <- function(name) {
  paste0(name, "/", name, ".yaml")
}

action_source <- function(name, ref) {
  sprintf(
    "%s/%s@%s/%s",
    actions_owner,
    actions_repo,
    ref,
    action_yaml_path(name)
  )
}

# Get latest hubverse action release. Function largely sourced from
# usethis internal utilities:
# https://github.com/r-lib/usethis/blob/9ac020dbf6b7d42e4f7915fec567184acd671826/R/github-actions.R#L259-L283
latest_release <- function() {
  raw_releases <- gh(
    "/repos/{owner}/{repo}/releases",
    owner = actions_owner,
    repo = actions_repo,
    .api_url = "https://github.com",
    .limit = Inf
  )

  tag_names <- purrr::discard(
    purrr::map_chr(raw_releases, "tag_name"),
    purrr::map_lgl(raw_releases, "prerelease")
  )
  pick_tag(tag_names)
}

# 1) filter to releases in the latest major version series
# 2) return the max, according to R's numeric_version logic
pick_tag <- function(nm) {
  dat <- data.frame(nm = nm, stringsAsFactors = FALSE)
  dat$version <- numeric_version(sub("^[^0-9]*", "", dat$nm))
  dat <- dat[dat$version == max(dat$version), ]
  dat$nm[1]
}
