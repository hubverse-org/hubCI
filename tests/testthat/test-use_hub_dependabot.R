# A stand-in for the configuration in hubverse-actions. The real one updates
# weekly, so a file holding this cannot have come from the network.
mock_dependabot <- paste0(
  "version: 2\n",
  "updates:\n",
  "  - package-ecosystem: github-actions\n",
  "    directory: \"/\"\n",
  "    schedule:\n",
  "      interval: monthly\n"
)

# Stub the download of the Dependabot configuration from hubverse-actions,
# serving the fixture above. Returns an environment whose `calls` element
# holds every stubbed gh() call, as local_mocked_actions_repo() does.
local_mocked_dependabot <- function(env = parent.frame()) {
  recorder <- new.env(parent = emptyenv())
  recorder$calls <- list()

  testthat::local_mocked_bindings(
    gh = function(endpoint, ...) {
      args <- list(...)
      recorder$calls <- c(
        recorder$calls,
        list(c(list(endpoint = endpoint), args))
      )
      if (
        grepl("/contents/", endpoint) &&
          identical(args$path, "dependabot/dependabot.yml")
      ) {
        return(charToRaw(mock_dependabot))
      }
      rlang::abort(
        "GitHub API error (404): Not Found",
        class = "http_error_404"
      )
    },
    .env = env
  )
  recorder
}

test_that("use_hub_dependabot works", {
  skip_if_offline()
  withr::local_dir(withr::local_tempdir())

  # The configuration is not in a release yet.
  path <- use_hub_dependabot(ref = "main")

  expect_equal(path, file.path(getwd(), ".github/dependabot.yml"))
  config <- yaml::read_yaml(".github/dependabot.yml")
  expect_equal(config$version, 2)
  expect_equal(config$updates[[1]]$`package-ecosystem`, "github-actions")

  # Compares the bytes real gh() returns against the file just written from
  # them, which the tests using the stubbed gh() cannot check.
  expect_message(
    use_hub_dependabot(ref = "main"),
    "Leaving '.github/dependabot.yml' unchanged"
  )
})

test_that("use_hub_dependabot reports what it writes", {
  withr::local_dir(withr::local_tempdir())
  recorder <- local_mocked_dependabot()
  ref <- "ak/dependabot-template/48"

  msgs <- capture_messages(path <- use_hub_dependabot(ref = ref))

  expect_match(msgs, "Creating '.github/'", all = FALSE, fixed = TRUE)
  expect_match(
    msgs,
    paste0(
      "Saving '.github/dependabot.yml' from ",
      "'hubverse-org/hubverse-actions@ak/dependabot-template/48/",
      "dependabot/dependabot.yml'"
    ),
    all = FALSE,
    fixed = TRUE
  )
  expect_equal(path, file.path(getwd(), ".github/dependabot.yml"))
  expect_equal(readLines(path), strsplit(mock_dependabot, "\n")[[1]])
  # The ref is passed separately from the path, so slashes in a branch name
  # survive instead of being truncated at the first segment.
  expect_equal(recorder$calls[[1]]$ref, ref)
  # Only the configuration is downloaded; nothing here depends on the
  # repository layout.
  expect_length(recorder$calls, 1)
})

test_that("use_hub_dependabot writes to the hub root", {
  hub <- withr::local_tempdir()
  fs::dir_create(fs::path(hub, "hub-config"))
  fs::dir_create(fs::path(hub, "model-output", "team-model"))
  withr::local_dir(fs::path(hub, "model-output", "team-model"))
  local_mocked_dependabot()

  expect_message(use_hub_dependabot(ref = "main"), "Using hub root")

  expect_true(fs::file_exists(fs::path(hub, ".github/dependabot.yml")))
  expect_false(fs::dir_exists(".github"))
})

test_that("use_hub_dependabot leaves an identical configuration unchanged", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_dependabot()

  use_hub_dependabot(ref = "main")

  expect_message(
    use_hub_dependabot(ref = "main"),
    "Leaving '.github/dependabot.yml' unchanged"
  )
})

test_that("use_hub_dependabot overwrites a differing configuration", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_dependabot()
  fs::dir_create(".github")
  writeLines("stale", ".github/dependabot.yml")

  expect_message(
    use_hub_dependabot(ref = "main"),
    "Overwriting '.github/dependabot.yml'"
  )
  expect_match(readLines(".github/dependabot.yml"), "monthly", all = FALSE)
})

test_that("use_hub_dependabot leaves a configuration alone when asked not to", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_dependabot()
  # Stands in for an interactive session where the prompt is declined.
  local_mocked_bindings(
    confirm_overwrite = function(path, unattended) FALSE
  )
  fs::dir_create(".github")
  writeLines("version: 2 # customised", ".github/dependabot.yml")

  path <- NULL
  expect_message(
    path <- use_hub_dependabot(ref = "main"),
    "Not overwriting '.github/dependabot.yml'"
  )

  expect_equal(readLines(".github/dependabot.yml"), "version: 2 # customised")
  expect_length(path, 0)
})

test_that("use_hub_dependabot errors informatively on a failed download", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_bindings(
    gh = function(...) {
      rlang::abort(
        "GitHub API error (404): Not Found",
        class = "http_error_404"
      )
    }
  )

  err <- expect_error(
    use_hub_dependabot(ref = "v1.1.0"),
    paste0(
      "Could not download ",
      "'hubverse-org/hubverse-actions@v1.1.0/dependabot/dependabot.yml'"
    )
  )
  expect_match(
    conditionMessage(err),
    "Check that 'dependabot/dependabot.yml' exists at that ref"
  )
  expect_false(fs::dir_exists(".github"))
})
