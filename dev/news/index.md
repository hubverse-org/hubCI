# Changelog

## hubCI 0.0.1.9000

- [`use_hub_github_action()`](https://hubverse-org.github.io/hubCI/dev/reference/use_hub_github_action.md)
  now fails with the list of workflows a hub can add when asked for
  anything else, such as the `pr-comment` composite action, instead of
  reporting a download error.

- Workflows that only work as a pair are now added together: asking for
  `validate-submission` also adds `validate-submission-comment`, which
  posts the validation result on the submitter’s pull request.

- [`use_hub_github_action()`](https://hubverse-org.github.io/hubCI/dev/reference/use_hub_github_action.md)
  now accepts any git reference GitHub recognises, including branch
  names containing slashes such as `"ak/my-feature/27"`, which
  previously failed with a 404 error.

- [`use_hub_github_action()`](https://hubverse-org.github.io/hubCI/dev/reference/use_hub_github_action.md)
  now leaves an existing workflow file untouched when it already matches
  the version being downloaded, and asks before overwriting one that
  differs (in a non-interactive session it overwrites and says so).

## hubCI 0.0.1

- Release first stable version of `hubCI` package.
- Use new `hubverse-org` organisation name as source for `hubverse`
  actions.

## hubCI 0.0.0.9001

- Added a `NEWS.md` file to track changes to the package.
- Added `ref` parameter to `use_hub_github_action` to allow for
  downloading specific git references of hubverse action files. Now
  defaults to latest release.
