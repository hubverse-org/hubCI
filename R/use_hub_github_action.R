# The download-and-write flow follows usethis::use_github_file() and
# usethis::write_over() (MIT licensed, © Posit Software, PBC), reimplemented
# against the gh API.

#' Hubverse GitHub Actions workflow setup
#'
#' Sets up common continuous integration (CI) workflows for a hub
#' that is hosted on GitHub using
#' [GitHub Actions](https://github.com/features/actions).
#' Available workflows are hosted in repository [hubverse-org/hubverse-actions](
#' https://github.com/hubverse-org/hubverse-actions)
#' The function creates the necessary directories and downloads the requested workflow `.yaml` file.
#' @param name Name of workflow, i.e. the name of one of the [workflow repository](
#' https://github.com/hubverse-org/hubverse-actions)
#' directories holding a workflow `.yaml` file of the same name. Asking for
#' anything else, such as a composite action, lists the workflows a hub can add.
#' @param ref Desired Git reference, usually the name of a tag (`"v0.1.0"`) or
#'   branch (`"main"`, including branch names containing slashes such as
#'   `"ak/my-feature/27"`). Other possibilities include a commit SHA (`"d1c516d"`)
#'   or `"HEAD"` (meaning "tip of remote's default branch"). If not specified,
#'   defaults to the latest published release of `hubverse-org/hubverse-actions`
#'   (<https://github.com/hubverse-org/hubverse-actions/releases>)
#' @param overwrite Whether to replace files that already exist. If `FALSE`,
#'   an interactive session asks first, and a non-interactive session stops
#'   with an error.
#'
#' @returns The paths of the workflow files written, invisibly, or an empty
#'   character vector if existing files were left in place. Called for the
#'   side effect of writing `.github/workflows/<name>.yaml`.
#'
#' @details
#' The workflow is written to the root of the hub, i.e. the closest enclosing
#' directory containing a `hub-config/` directory, falling back to the working
#' directory if there is none within the repository you are in.
#'
#' Some workflows only work as a pair, one running the checks and another
#' posting their result, and are added together: asking for
#' `"validate-submission"` also adds `"validate-submission-comment"`.
#'
#' Existing workflow files are replaced when `overwrite = TRUE`. Otherwise an
#' interactive session asks once, listing them, and a non-interactive session
#' stops with an error. Nothing is written unless every file can be, so a
#' pair is always replaced together.
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
use_hub_github_action <- function(name, ref = NULL, overwrite = FALSE) {
  ref <- ref %||% latest_release()
  files <- resolve_workflows(name, ref)

  root <- locate_hub_root()
  paired <- setdiff(names(files), name)
  if (length(paired) > 0L) {
    cli::cli_inform(c(
      i = "{.val {name}} works as a pair with {.val {paired}}, so both are added."
    ))
  }

  rel_paths <- file.path(".github", "workflows", paste0(names(files), ".yaml"))
  paths <- write_github_files(
    rlang::set_names(files, rel_paths),
    root = root,
    sources = workflow_source(names(files), ref),
    overwrite = overwrite
  )
  invisible(paths)
}

# Write `files`, a list of raw contents named by path relative to `root`.
# Files that already exist are replaced when `overwrite` is TRUE, or when an
# interactive session confirms it, once for all of them. Otherwise nothing is
# written: a non-interactive session errors and an interactive one reports the
# refusal. `sources` names where each file came from. Returns the paths
# written.
write_github_files <- function(
  files,
  root,
  sources,
  overwrite,
  call = rlang::caller_env()
) {
  rel_paths <- names(files)
  paths <- file.path(root, rel_paths)
  existing <- rel_paths[file.exists(paths)]
  if (length(existing) > 0L && !overwrite) {
    if (!rlang::is_interactive()) {
      cli::cli_abort(
        c(
          "{.path {existing}} already {?exists/exist}.",
          i = "Set {.code overwrite = TRUE} to replace existing files."
        ),
        call = call
      )
    }
    if (!confirm_overwrite(existing)) {
      cli::cli_inform(c(x = "Not overwriting {.path {existing}}"))
      return(character())
    }
  }
  purrr::pwalk(list(files, rel_paths, sources), write_github_file, root = root)
  paths
}

# Write `contents` to `rel_path` under `root`, creating the directory if
# needed, and report it. `source` names where the contents came from.
write_github_file <- function(contents, rel_path, source, root) {
  path <- file.path(root, rel_path)
  existing <- file.exists(path)
  rel_dir <- dirname(rel_path)
  dir <- file.path(root, rel_dir)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    cli::cli_inform(c(v = "Creating {.path {rel_dir}/}"))
  }
  writeBin(contents, path)
  if (existing) {
    cli::cli_inform(c(
      v = "Overwriting {.path {rel_path}} from {.val {source}}"
    ))
  } else {
    cli::cli_inform(c(v = "Saving {.path {rel_path}} from {.val {source}}"))
  }
}

# The hub root to write into, reporting it when it is not the working
# directory.
locate_hub_root <- function() {
  wd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  root <- hub_root(wd)
  if (!identical(root, wd)) {
    cli::cli_inform(c(i = "Using hub root {.path {root}}"))
  }
  root
}

# Locate the root of the hub containing `dir` (an already normalised path), i.e.
# where the `.github/` directory belongs. usethis::use_github_action() used to
# resolve this via the active project.
hub_root <- function(dir) {
  start <- dir
  repeat {
    if (dir.exists(file.path(dir, "hub-config"))) {
      return(dir)
    }
    # Stop at a repository boundary: a hub further up the tree is not the hub
    # whose checkout we are standing in.
    parent <- dirname(dir)
    if (file.exists(file.path(dir, ".git")) || identical(parent, dir)) {
      return(start)
    }
    dir <- parent
  }
}

# Ask whether to replace the files at `rel_paths`.
confirm_overwrite <- function(rel_paths) {
  isTRUE(utils::askYesNo(cli::format_inline(
    "Overwrite pre-existing {?file/files} {.path {rel_paths}}?"
  )))
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
