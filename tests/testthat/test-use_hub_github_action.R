test_that("use_hub_github_action works", {
  proj_path <- paste0(tempdir(), "/test_proj")
  orig_wd <- getwd()
  on.exit(setwd(orig_wd))

  usethis::create_project(proj_path,
    rstudio = FALSE,
    open = FALSE
  )
  setwd(proj_path)
  use_hub_github_action(name = "validate-submission")

  ga_path <- ".github/workflows/validate-submission.yaml"
  expect_true(".github" %in% fs::path_file(
    fs::dir_ls(proj_path, all = TRUE)
  ))
  expect_true(fs::file_exists(ga_path))
  expect_gt(length(readLines(ga_path)), 0)
  expect_false(any(grepl("remotes::install_github", readLines(ga_path))))

  fs::file_delete(ga_path)
  expect_false(ga_path %in% fs::path_file(
    fs::dir_ls(proj_path, all = TRUE)
  ))

  use_hub_github_action(name = "validate-submission", ref = "v0.0.1")

  ga_path <- ".github/workflows/validate-submission.yaml"
  expect_true(".github" %in% fs::path_file(fs::dir_ls(proj_path, all = TRUE)))
  expect_true(fs::file_exists(ga_path))
  expect_gt(length(readLines(ga_path)), 0)
  expect_true(any(grepl("remotes::install_github", readLines(ga_path))))
})
