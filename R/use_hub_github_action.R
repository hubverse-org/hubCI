#' Hubverse GitHub Action setup
#'
#' Sets up common continuous integration (CI) workflows for a hub
#' that is hosted on GitHub using
#' [GitHub Actions](https://github.com/features/actions).
#' Available actions are hosted in repository [Infectious-Disease-Modeling-Hubs/hubverse-actions](https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions)
#' The function creates the necessary directories and downloads the requested GitHub Action yaml file.
#' @param name Name of workflow, i.e. the name of one of the [action repository](https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions) directories containing a GitHub Action workflow `.yaml` file.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' use_hub_github_action(name = "validate-submission")
#' }
use_hub_github_action <- function(name) {
  url <- paste(
    "https://github.com/Infectious-Disease-Modeling-Hubs/hubverse-actions/blob/main/",
    name,
    paste0(name, ".yaml"),
    sep = "/"
  )

  usethis::use_github_action(
    url = url,
    ignore = FALSE
  )
}
