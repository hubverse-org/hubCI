#' Hubverse Dependabot configuration setup
#'
#' Sets up [Dependabot](https://docs.github.com/en/code-security/dependabot)
#' for a hub that is hosted on GitHub, so that the actions used by the hub's
#' GitHub Actions workflows are kept up to date. The configuration is hosted in
#' repository [hubverse-org/hubverse-actions](
#' https://github.com/hubverse-org/hubverse-actions) under `dependabot/`.
#' The function creates the `.github/` directory if necessary and downloads the
#' configuration to `.github/dependabot.yml`.
#' @inheritParams use_hub_github_action
#'
#' @returns The path of the configuration file, invisibly, or an empty
#'   character vector if an existing file was left in place. Called for the
#'   side effect of writing `.github/dependabot.yml`.
#'
#' @details
#' The workflows added by [use_hub_github_action()] reference the actions they
#' use by major version, such as `actions/checkout@v4`. Minor and patch
#' releases of those actions reach the hub with no change to the workflow. A
#' new major version does not, so the hub stays on the old one until the
#' workflow is edited by hand. With this configuration in place, Dependabot
#' opens a pull request in the hub for each new major version, once a week.
#' Dependabot reads the file from the hub's default branch, so it takes effect
#' once committed there.
#'
#' The file is written to the root of the hub, located as described in
#' [use_hub_github_action()].
#'
#' An existing `.github/dependabot.yml` is replaced when `overwrite = TRUE`.
#' Otherwise an interactive session asks first, and a non-interactive session
#' stops with an error. A hub that already uses Dependabot for another
#' ecosystem should add the `github-actions` entry from the downloaded
#' configuration to its existing file instead of replacing the file.
#' @export
#'
#' @examples
#' \dontrun{
#' use_hub_dependabot()
#' }
use_hub_dependabot <- function(ref = NULL, overwrite = FALSE) {
  ref <- ref %||% latest_release()
  dependabot_path <- "dependabot/dependabot.yml"
  contents <- fetch_file(dependabot_path, ref)
  root <- locate_hub_root()
  rel_path <- file.path(".github", "dependabot.yml")

  path <- write_github_files(
    rlang::set_names(list(contents), rel_path),
    root = root,
    sources = file_source(dependabot_path, ref),
    overwrite = overwrite
  )
  invisible(path)
}
