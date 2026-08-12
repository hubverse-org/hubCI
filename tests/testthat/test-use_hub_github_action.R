mock_workflow <- "name: mock workflow\n"

# Stub the workflow download: the fake gh() records the arguments it was given
# and returns `mock_workflow` as raw bytes, the shape of a real raw contents
# response.
#
# Use it when a test is about our own behaviour around the download (the
# messages, where the file lands, how an existing file is treated) rather than
# about the contents of a real workflow, so the test neither hits the network
# nor depends on what a given ref happens to contain, or on a branch that will
# eventually be deleted.
#
# Returns an environment whose `call` element holds the arguments of the last
# stubbed gh() call, for tests that assert on the request itself; tests that
# only care about the side effects can ignore it. `env` is the calling test's
# frame, because local_mocked_bindings() would otherwise undo the mock as soon
# as this helper returned.
local_mocked_action <- function(env = parent.frame()) {
  args <- new.env(parent = emptyenv())
  testthat::local_mocked_bindings(
    gh = function(endpoint, ...) {
      args$call <- list(endpoint = endpoint, ...)
      charToRaw(mock_workflow)
    },
    .env = env
  )
  args
}

test_that("use_hub_github_action works", {
  skip_if_offline()
  withr::local_dir(withr::local_tempdir())

  use_hub_github_action(name = "validate-submission")

  ga_path <- ".github/workflows/validate-submission.yaml"
  expect_true(fs::dir_exists(".github/workflows"))
  expect_true(fs::file_exists(ga_path))
  workflow <- readLines(ga_path)
  expect_true(any(grepl(
    "hubValidations::validate_pr(",
    workflow,
    fixed = TRUE
  )))
  # Releases up to v0.0.1 installed hubValidations with remotes, later ones from
  # r-universe, so this marks which version of the workflow was downloaded.
  expect_false(any(grepl("remotes::install_github", workflow)))

  fs::file_delete(ga_path)
  expect_false(fs::file_exists(ga_path))

  use_hub_github_action(name = "validate-submission", ref = "v0.0.1")

  expect_true(fs::file_exists(ga_path))
  workflow <- readLines(ga_path)
  expect_true(any(grepl(
    "hubValidations::validate_pr(",
    workflow,
    fixed = TRUE
  )))
  expect_true(any(grepl("remotes::install_github", workflow)))
})

test_that("use_hub_github_action reports what it writes", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_action()

  msgs <- capture_messages(
    use_hub_github_action(name = "validate-submission", ref = "v0.0.1")
  )

  expect_match(msgs, "Creating '.github/workflows/'", all = FALSE, fixed = TRUE)
  expect_match(
    msgs,
    paste0(
      "Saving '.github/workflows/validate-submission.yaml' from ",
      "'hubverse-org/hubverse-actions@v0.0.1/",
      "validate-submission/validate-submission.yaml'"
    ),
    all = FALSE,
    fixed = TRUE
  )
})

test_that("use_hub_github_action handles refs containing slashes", {
  withr::local_dir(withr::local_tempdir())
  args <- local_mocked_action()

  use_hub_github_action(
    name = "validate-submission",
    ref = "ak/post-validation-results-to-pr/53"
  )

  # The ref is passed separately from the path, so slashes in a branch name
  # survive instead of being truncated at the first segment.
  expect_equal(args$call$ref, "ak/post-validation-results-to-pr/53")
  expect_equal(
    args$call$path,
    "validate-submission/validate-submission.yaml"
  )
  expect_equal(
    readLines(".github/workflows/validate-submission.yaml"),
    "name: mock workflow"
  )
})

test_that("use_hub_github_action writes to the hub root", {
  hub <- withr::local_tempdir()
  fs::dir_create(fs::path(hub, "hub-config"))
  fs::dir_create(fs::path(hub, "model-output", "team-model"))
  withr::local_dir(fs::path(hub, "model-output", "team-model"))
  local_mocked_action()

  expect_message(
    use_hub_github_action(name = "validate-submission", ref = "main"),
    "Using hub root"
  )

  expect_true(fs::file_exists(fs::path(
    hub,
    ".github/workflows/validate-submission.yaml"
  )))
  expect_false(fs::dir_exists(".github"))
})

test_that("use_hub_github_action leaves an identical workflow unchanged", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_action()

  use_hub_github_action(name = "validate-submission", ref = "main")

  expect_message(
    use_hub_github_action(name = "validate-submission", ref = "main"),
    "Leaving '.github/workflows/validate-submission.yaml' unchanged"
  )
})

test_that("use_hub_github_action overwrites a differing workflow", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_action()
  ga_path <- ".github/workflows/validate-submission.yaml"
  fs::dir_create(".github/workflows")
  writeLines("stale", ga_path)

  expect_message(
    use_hub_github_action(name = "validate-submission", ref = "main"),
    "Overwriting '.github/workflows/validate-submission.yaml'"
  )
  expect_equal(readLines(ga_path), "name: mock workflow")
})

test_that("use_hub_github_action errors informatively on an unknown workflow", {
  withr::local_dir(withr::local_tempdir())

  local_mocked_bindings(
    gh = function(...) {
      rlang::abort(
        "GitHub API error (404): Not Found",
        class = "http_error_404"
      )
    }
  )

  expect_error(
    use_hub_github_action(name = "no-such-workflow", ref = "main"),
    "Could not download 'hubverse-org/hubverse-actions@main/no-such-workflow"
  )
  expect_false(fs::file_exists(".github/workflows/no-such-workflow.yaml"))
})
