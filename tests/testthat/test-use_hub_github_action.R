test_that("use_hub_github_action works", {
    orig_wd <- getwd()
    on.exit(setwd(orig_wd))

    proj_path <- paste0(tempdir(), "/test_proj")
    usethis::create_project(proj_path,
                            rstudio = FALSE,
                            open = FALSE)
    setwd(proj_path)
    use_hub_github_action(name = "validate-submission")

    ga_path <- ".github/workflows/validate-submission.yaml"
    expect_true(".github" %in% fs::path_file(fs::dir_ls(proj_path, all = TRUE)))
    expect_true(fs::file_exists(ga_path))
    expect_gt(length(readLines(ga_path)), 0)
})
