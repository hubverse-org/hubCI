# The download-and-write flow follows usethis::use_github_file() and
# usethis::write_over() (MIT licensed, © Posit Software, PBC), reimplemented
# against the gh API. Unlike write_over(), a non-interactive session overwrites
# a differing file rather than refusing to.

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
#'
#' @returns The paths of the workflow files added, invisibly. Called for the
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
#' If the workflow file already exists, it is left alone when its contents match
#' what is being downloaded. Otherwise, an interactive session asks before
#' overwriting it, while a non-interactive one overwrites it and reports that it
#' has done so. A paired workflow you did not ask for is the exception: local
#' changes to it stand unless you confirm the overwrite, or ask for it by name.
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
  files <- resolve_workflows(name, ref)

  wd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  root <- hub_root(wd)
  if (!identical(root, wd)) {
    rlang::inform(c(i = sprintf("Using hub root '%s'", root)))
  }
  paired <- setdiff(names(files), name)
  if (length(paired) > 0L) {
    rlang::inform(c(
      i = sprintf(
        "'%s' works as a pair with %s, so both are added.",
        name,
        paste0("'", paired, "'", collapse = " and ")
      )
    ))
  }

  paths <- purrr::imap_chr(
    files,
    write_workflow,
    ref = ref,
    root = root,
    requested = name
  )
  invisible(unname(paths[!is.na(paths)]))
}

# Write one workflow file, reporting what happened to it. Returns the path of
# the file now holding the workflow, or NA if an existing file was kept in its
# place instead.
write_workflow <- function(contents, name, ref, root, requested) {
  rel_dir <- file.path(".github", "workflows")
  rel_path <- file.path(rel_dir, paste0(name, ".yaml"))
  path <- file.path(root, rel_path)

  existing <- file.exists(path)
  if (existing) {
    if (identical(readBin(path, "raw", n = file.size(path)), contents)) {
      rlang::inform(c(v = sprintf("Leaving '%s' unchanged", rel_path)))
      return(path)
    }
    # A workflow the hub did not ask for keeps its local edits unattended; ask
    # for it by name to replace it.
    unattended <- identical(name, requested)
    if (!confirm_overwrite(rel_path, unattended = unattended)) {
      rlang::inform(c(x = sprintf("Not overwriting '%s'", rel_path)))
      return(NA_character_)
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
      workflow_source(name, ref)
    )
  ))

  path
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
    # Stop at a repository boundary: a hub further up the tree is not the hub
    # whose checkout we are standing in.
    parent <- dirname(dir)
    if (file.exists(file.path(dir, ".git")) || identical(parent, dir)) {
      return(start)
    }
    dir <- parent
  }
}

# Ask before replacing a file, if there is anyone to ask. `unattended` is the
# answer when there is not.
confirm_overwrite <- function(path, unattended) {
  if (!interactive()) {
    return(unattended)
  }
  isTRUE(utils::askYesNo(sprintf("Overwrite pre-existing file '%s'?", path)))
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
