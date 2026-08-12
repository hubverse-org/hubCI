# Which workflows a hub can add, and which of them belong together, both derived
# from the hubverse-actions repository at the requested ref rather than recorded
# here, so that adding a workflow there needs no change in hubCI.
#
# A directory holding `<dir>/<dir>.yaml` is an installable workflow. Composite
# actions such as pr-comment ship an `action.yaml` and no workflow of their own,
# so they are not offered. A workflow that names another in its `workflow_run`
# trigger reports on that workflow's runs, and the two are added together: one
# posts what the other found, and a hub wants both or neither.

# The workflow files to write for `name`, as a named list of raw contents keyed
# by workflow name. Errors if `name` is not an installable workflow at `ref`.
#
# Every workflow in the repository is downloaded, because which of them reports
# on `name` can only be read from their contents. They are small, and the ones
# that are not written are discarded.
resolve_workflows <- function(name, ref, call = rlang::caller_env()) {
  available <- installable_workflows(ref, call = call)
  if (!name %in% available) {
    rlang::abort(
      c(
        sprintf("'%s' is not a workflow you can add to a hub.", name),
        i = sprintf(
          "Available at '%s@%s': %s.",
          actions_slug,
          ref,
          paste(available, collapse = ", ")
        )
      ),
      call = call
    )
  }

  files <- purrr::map(
    rlang::set_names(available),
    fetch_workflow_yaml,
    ref = ref,
    call = call
  )
  files[paired_with(name, files)]
}

# Directories in the repository at `ref` that hold a workflow of the same name.
installable_workflows <- function(ref, call = rlang::caller_env()) {
  paths <- repo_paths(ref, call = call)
  dirs <- unique(sub("/.*", "", paths))
  sort(dirs[workflow_yaml_path(dirs) %in% paths])
}

# Every path in the repository at `ref`. The ref reaches the API as a query
# parameter and the tree as a commit SHA, so refs containing slashes work.
repo_paths <- function(ref, call = rlang::caller_env()) {
  commit <- rlang::try_fetch(
    gh(
      "/repos/{owner}/{repo}/commits",
      owner = actions_owner,
      repo = actions_repo,
      sha = ref,
      per_page = 1
    ),
    http_error_404 = function(cnd) {
      rlang::abort(
        c(
          sprintf("Could not find ref '%s' in '%s'.", ref, actions_slug),
          i = "`ref` should be a tag, branch, commit SHA or \"HEAD\"."
        ),
        parent = cnd,
        call = call
      )
    }
  )
  tree <- gh(
    "/repos/{owner}/{repo}/git/trees/{tree_sha}",
    owner = actions_owner,
    repo = actions_repo,
    tree_sha = commit[[1]]$sha,
    recursive = 1
  )
  if (isTRUE(tree$truncated)) {
    rlang::abort(
      sprintf(
        "Could not list '%s@%s': the repository tree is too large.",
        actions_slug,
        ref
      ),
      call = call
    )
  }
  purrr::map_chr(tree$tree, "path")
}

# `name` together with the workflows it is paired with: those it is triggered
# by, and those triggered by it, since only the reporting workflow names the
# other.
paired_with <- function(name, files) {
  links <- workflow_links(files)
  union(
    name,
    c(
      links[[name]],
      names(links)[purrr::map_lgl(links, function(x) name %in% x)]
    )
  )
}

# For each workflow, the workflows it is triggered by, as directory names. Two
# workflows sharing a `name:` both match, rather than the first one silently
# winning.
workflow_links <- function(files) {
  meta <- purrr::map(files, workflow_meta)
  workflow_names <- purrr::map_chr(meta, "name")
  purrr::map(meta, function(x) names(meta)[workflow_names %in% x$triggered_by])
}

# A workflow's `name:`, and the names of the workflows whose runs trigger it.
# `on:` takes a bare event or a list of them as well as a mapping, and neither
# of those can hold a `workflow_run`. The handlers keep YAML 1.1 from reading
# the `on:` key as a boolean, and from warning about large numbers elsewhere in
# a file whose other fields are never read.
workflow_meta <- function(contents) {
  yaml <- yaml::yaml.load(
    rawToChar(contents),
    handlers = list(`bool#yes` = function(x) x, int = function(x) x)
  )
  events <- yaml[["on"]]
  workflow_run <- if (is.list(events)) events[["workflow_run"]]
  triggered_by <- if (is.list(workflow_run)) workflow_run[["workflows"]]
  list(
    name = yaml$name %||% "",
    triggered_by = as.character(triggered_by %||% character())
  )
}

# Download the contents of a workflow file from hubverse-actions. Uses the
# contents endpoint, which takes the ref as a query parameter and therefore
# handles refs containing slashes, unlike a `/blob/<ref>/<path>` URL, which
# cannot be split into ref and path unambiguously.
fetch_workflow_yaml <- function(name, ref, call = rlang::caller_env()) {
  contents <- rlang::try_fetch(
    gh(
      "/repos/{owner}/{repo}/contents/{path}",
      owner = actions_owner,
      repo = actions_repo,
      path = workflow_yaml_path(name),
      ref = ref,
      .accept = "application/vnd.github.raw"
    ),
    http_error_404 = function(cnd) {
      rlang::abort(
        c(
          sprintf("Could not download '%s'.", workflow_source(name, ref)),
          i = sprintf(
            "Check that '%s' exists at that ref in <https://github.com/%s>.",
            workflow_yaml_path(name),
            actions_slug
          )
        ),
        parent = cnd,
        call = call
      )
    }
  )
  # gh returns the raw response with its own class attached, which writeBin
  # rejects.
  as.vector(contents)
}

workflow_yaml_path <- function(name) {
  paste0(name, "/", name, ".yaml")
}

workflow_source <- function(name, ref) {
  sprintf("%s@%s/%s", actions_slug, ref, workflow_yaml_path(name))
}
