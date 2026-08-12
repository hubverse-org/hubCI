# A stand-in for hubverse-actions: three workflow directories, one of which
# reports on another, plus a composite action that a hub cannot add.
mock_workflows <- list(
  "validate-config" = "name: Hub Config Validation (R)\non:\n  push:\n",
  "validate-submission" = "name: Hub Submission Validation (R)\non:\n  pull_request:\n",
  "validate-submission-comment" = paste0(
    "name: Post Submission Validation Result\n",
    "on:\n  workflow_run:\n",
    "    workflows: [\"Hub Submission Validation (R)\"]\n",
    "    types: [completed]\n"
  )
)
mock_actions <- "pr-comment"

# Stub the calls to hubverse-actions, serving the fixture above: the commit and
# tree that give the repository layout, and the raw contents of each workflow.
#
# Use it when a test is about our own behaviour around the download (the
# messages, where files land, how an existing file is treated) rather than about
# the contents of a real workflow, so the test neither hits the network nor
# depends on what a given ref happens to contain, or on a branch that will
# eventually be deleted.
#
# Returns an environment whose `calls` element holds every stubbed gh() call, in
# order, for tests that assert on the requests themselves; tests that only care
# about the side effects can ignore it. `env` is the calling test's frame,
# because local_mocked_bindings() would otherwise undo the mock as soon as this
# helper returned.
local_mocked_actions_repo <- function(
  dirs = names(mock_workflows),
  env = parent.frame()
) {
  recorder <- new.env(parent = emptyenv())
  recorder$calls <- list()
  paths <- c(
    "README.md",
    paste0(mock_actions, "/action.yaml"),
    unlist(lapply(dirs, function(d) {
      c(paste0(d, "/README.md"), paste0(d, "/", d, ".yaml"))
    }))
  )

  testthat::local_mocked_bindings(
    gh = function(endpoint, ...) {
      args <- list(...)
      recorder$calls <- c(
        recorder$calls,
        list(c(list(endpoint = endpoint), args))
      )
      if (grepl("/commits$", endpoint)) {
        return(list(list(sha = "0f1e2d3")))
      }
      if (grepl("/git/trees/", endpoint)) {
        return(list(
          truncated = FALSE,
          tree = lapply(paths, function(p) list(path = p))
        ))
      }
      if (grepl("/contents/", endpoint)) {
        dir <- sub("/.*", "", args$path)
        if (!dir %in% names(mock_workflows)) {
          rlang::abort(
            "GitHub API error (404): Not Found",
            class = "http_error_404"
          )
        }
        return(charToRaw(mock_workflows[[dir]]))
      }
      rlang::abort(paste("Unexpected endpoint:", endpoint))
    },
    .env = env
  )
  recorder
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

  # Start clean: the default ref may pair this workflow with another.
  fs::dir_delete(".github")

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
  local_mocked_actions_repo()

  msgs <- capture_messages(
    use_hub_github_action(name = "validate-config", ref = "v0.0.1")
  )

  expect_match(msgs, "Creating '.github/workflows/'", all = FALSE, fixed = TRUE)
  expect_match(
    msgs,
    paste0(
      "Saving '.github/workflows/validate-config.yaml' from ",
      "'hubverse-org/hubverse-actions@v0.0.1/validate-config/validate-config.yaml'"
    ),
    all = FALSE,
    fixed = TRUE
  )
})

test_that("use_hub_github_action handles refs containing slashes", {
  withr::local_dir(withr::local_tempdir())
  ref <- "ak/post-validation-results-to-pr/53"
  recorder <- local_mocked_actions_repo()

  use_hub_github_action(name = "validate-config", ref = ref)

  # The ref is passed separately from the path, so slashes in a branch name
  # survive instead of being truncated at the first segment.
  download <- Filter(
    function(x) grepl("/contents/", x$endpoint),
    recorder$calls
  )[[1]]
  expect_equal(download$ref, ref)
  expect_equal(download$path, "validate-config/validate-config.yaml")
  # The repository layout is read at the same ref, which the commits endpoint
  # takes as a query parameter for the same reason.
  expect_equal(recorder$calls[[1]]$sha, ref)
  expect_equal(
    readLines(".github/workflows/validate-config.yaml"),
    c("name: Hub Config Validation (R)", "on:", "  push:")
  )
})

test_that("use_hub_github_action rejects anything but a workflow", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()

  err <- expect_error(
    use_hub_github_action(name = "pr-comment", ref = "main"),
    "'pr-comment' is not a workflow you can add to a hub"
  )
  expect_match(
    conditionMessage(err),
    "validate-config, validate-submission, validate-submission-comment"
  )
  expect_error(
    use_hub_github_action(name = "no-such-thing", ref = "main"),
    "is not a workflow you can add to a hub"
  )
  expect_false(fs::dir_exists(".github"))
})

test_that("use_hub_github_action adds paired workflows together", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()

  expect_message(
    paths <- use_hub_github_action(name = "validate-submission", ref = "main"),
    "works as a pair with 'validate-submission-comment'"
  )

  expect_true(fs::file_exists(".github/workflows/validate-submission.yaml"))
  expect_true(fs::file_exists(
    ".github/workflows/validate-submission-comment.yaml"
  ))
  expect_length(paths, 2)
})

test_that("use_hub_github_action adds a workflow its companion reports on", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()

  use_hub_github_action(name = "validate-submission-comment", ref = "main")

  # The comment workflow is useless without the one whose runs trigger it.
  expect_true(fs::file_exists(".github/workflows/validate-submission.yaml"))
  expect_true(fs::file_exists(
    ".github/workflows/validate-submission-comment.yaml"
  ))
})

test_that("use_hub_github_action keeps local edits to a paired workflow", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()
  customised <- ".github/workflows/validate-submission.yaml"
  fs::dir_create(".github/workflows")
  writeLines("name: Hub Submission Validation (R) # customised", customised)

  # The hub asked for the comment workflow, so its own edits to the workflow
  # that comes with it are not silently replaced.
  paths <- NULL
  expect_message(
    paths <- use_hub_github_action(
      name = "validate-submission-comment",
      ref = "main"
    ),
    "Not overwriting '.github/workflows/validate-submission.yaml'"
  )

  expect_equal(
    readLines(customised),
    "name: Hub Submission Validation (R) # customised"
  )
  expect_true(fs::file_exists(
    ".github/workflows/validate-submission-comment.yaml"
  ))
  expect_length(paths, 1)
})

test_that("use_hub_github_action replaces a workflow asked for by name", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()
  customised <- ".github/workflows/validate-submission.yaml"
  fs::dir_create(".github/workflows")
  writeLines("name: Hub Submission Validation (R) # customised", customised)

  use_hub_github_action(name = "validate-submission", ref = "main")

  expect_equal(readLines(customised)[1], "name: Hub Submission Validation (R)")
})

test_that("use_hub_github_action reports an unknown ref", {
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
    use_hub_github_action(name = "validate-config", ref = "mian"),
    "Could not find ref 'mian' in 'hubverse-org/hubverse-actions'"
  )
})

test_that("workflow_links reads every form of `on:`", {
  files <- purrr::map(
    list(
      shorthand = "name: A\non: [push, pull_request]\n",
      single = "name: B\non: push\n",
      mapping = "name: C\non:\n  push:\n    branches: main\n",
      # Two workflows share the name "A", so both are linked, not just one.
      listener = "name: D\non:\n  workflow_run:\n    workflows: [\"A\"]\n",
      twin = "name: A\non: [push]\n"
    ),
    charToRaw
  )

  expect_equal(
    workflow_links(files),
    list(
      shorthand = character(),
      single = character(),
      mapping = character(),
      listener = c("shorthand", "twin"),
      twin = character()
    )
  )
})

test_that("use_hub_github_action leaves unpaired workflows alone", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()

  use_hub_github_action(name = "validate-config", ref = "main")

  expect_equal(
    fs::path_file(fs::dir_ls(".github/workflows")),
    "validate-config.yaml"
  )
})

test_that("use_hub_github_action writes to the hub root", {
  hub <- withr::local_tempdir()
  fs::dir_create(fs::path(hub, "hub-config"))
  fs::dir_create(fs::path(hub, "model-output", "team-model"))
  withr::local_dir(fs::path(hub, "model-output", "team-model"))
  local_mocked_actions_repo()

  expect_message(
    use_hub_github_action(name = "validate-config", ref = "main"),
    "Using hub root"
  )

  expect_true(fs::file_exists(fs::path(
    hub,
    ".github/workflows/validate-config.yaml"
  )))
  expect_false(fs::dir_exists(".github"))
})

test_that("use_hub_github_action leaves an identical workflow unchanged", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()

  use_hub_github_action(name = "validate-config", ref = "main")

  expect_message(
    use_hub_github_action(name = "validate-config", ref = "main"),
    "Leaving '.github/workflows/validate-config.yaml' unchanged"
  )
})

test_that("use_hub_github_action overwrites a differing workflow", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_actions_repo()
  ga_path <- ".github/workflows/validate-config.yaml"
  fs::dir_create(".github/workflows")
  writeLines("stale", ga_path)

  expect_message(
    use_hub_github_action(name = "validate-config", ref = "main"),
    "Overwriting '.github/workflows/validate-config.yaml'"
  )
  expect_equal(readLines(ga_path)[1], "name: Hub Config Validation (R)")
})

test_that("use_hub_github_action errors informatively on a failed download", {
  withr::local_dir(withr::local_tempdir())
  # Listed in the repository, but its contents cannot be fetched.
  local_mocked_actions_repo(dirs = c(names(mock_workflows), "ghost"))

  expect_error(
    use_hub_github_action(name = "ghost", ref = "main"),
    "Could not download 'hubverse-org/hubverse-actions@main/ghost"
  )
  expect_false(fs::file_exists(".github/workflows/ghost.yaml"))
})

test_that("use_hub_github_action stops looking for a hub at the repository", {
  repo <- withr::local_tempdir()
  # A hub above the repository we are standing in is a different project.
  fs::dir_create(fs::path(repo, "hub-config"))
  fs::dir_create(fs::path(repo, "pkg", ".git"))
  withr::local_dir(fs::path(repo, "pkg"))
  local_mocked_actions_repo()

  use_hub_github_action(name = "validate-config", ref = "main")

  expect_true(fs::file_exists(".github/workflows/validate-config.yaml"))
  expect_false(fs::dir_exists(fs::path(repo, ".github")))
})
