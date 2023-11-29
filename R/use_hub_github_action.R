#' Hubverse GitHub Action setup
#'
#' Sets up common continuous integration (CI) workflows for a hub
#' that is hosted on GitHub using
#' [GitHub Actions](https://github.com/features/actions).
#' Available actions are hosted in repository [Infectious-Disease-Modeling-Hubs/hubverse-actions](https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions)
#' The function creates the necessary directories and downloads the requested GitHub Action yaml file.
#' @param name Name of workflow, i.e. the name of one of the [action repository](https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions) directories containing a GitHub Action workflow `.yaml` file.
#' @param ref Desired Git reference, usually the name of a tag (`"v0.1.0"`) or
#'   branch (`"main"`). Other possibilities include a commit SHA (`"d1c516d"`)
#'   or `"HEAD"` (meaning "tip of remote's default branch"). If not specified,
#'   defaults to the latest published release of `Infectious-Disease-Modeling-Hubs/hubverse-actions`
#'   (<https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions/releases>)
#'
#' @export
#' @importFrom rlang "%||%"
#'
#' @examples
#' \dontrun{
#' use_hub_github_action(name = "validate-submission")
#' }
use_hub_github_action <- function(name, ref = NULL) {
  ref <- ref %||% latest_release()
  url <- paste(
    "https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions/blob",
    ref,
    name,
    paste0(name, ".yaml"),
    sep = "/"
  )

  usethis::use_github_action(
    url = url,
    ignore = FALSE
  )
}

# Get latest hubverse action release. Function largely sourced from
# usethis internal utilities:
# https://github.com/r-lib/usethis/blob/9ac020dbf6b7d42e4f7915fec567184acd671826/R/github-actions.R#L259-L283
latest_release <- function() {

  raw_releases <- gh::gh("/repos/{owner}/{repo}/releases",
    owner = "Infectious-Disease-Modeling-Hubs",
    repo = "hubverse-actions",
    .api_url = "https://github.com", .limit = Inf
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
