# github-status-resource

A [Concourse](http://concourse.ci/) [resource](http://concourse.ci/resources.html) to interact with the [GitHub Status](https://developer.github.com/v3/repos/statuses/) type.

## Configuration

 * **`repository`** - the owner and repository name, slash delimited (e.g. `dpb587/github-status-resource`)
 * **`access_token`** - GitHub API access token from a user with write access to the repository (minimum token scope of `repo:status`)
 * `branch` - the branch currently being monitored (default: `master`)
 * `base_context` - prefix for the context label (default: `concourse-ci`)
 * `context` - a label to differentiate this status from the status of other systems (default: `default`)
 * `endpoint` - GitHub API endpoint (default: `https://api.github.com`)
 * `skip_ssl_verification` - Disable certificate validation for GitHub API calls (default: `false`)

## Behavior

### `check`

Triggers when the status of the branch for the configured context has been updated.

### `in`

Lookup the state of a status.

 * `/commit` - the commit reference of the status
 * `/description` - a short description of the status
 * `/state` - the state of the status
 * `/target_url` - the target URL associated with the status
 * `/updated_at` - when the status was last updated

### `out`

Update the status of a commit. Optionally include a description and target URL which will be referenced from GitHub.

Parameters:

 * **`commit`** - specific commit sha affiliated with the status. Value must be either: path to an input git directory whose detached `HEAD` will be used; or path to an input file whose contents is the sha
 * **`state`** - the state of the status. Must be one of `pending`, `success`, `error`, or `failure`
 * `description` - a short description of the status
 * `description_path` - path to an input file whose data is the value of `description`
 * `target_url` - the target URL to associate with the status (default: concourse build link)
 * `context` - overrides the source context value (default: `""`)

## Example

A typical use case is to update the status of a commit as it traverses your pipeline. The following example marks the commit as pending before unit tests start. Once unit tests finish, the status is updated to either success or failure depending on how the task completes.

```yaml
jobs:
  - name: "unit-tests"
    plan:
      - get: "repo"
        trigger: true
      - put: "repo-status"                               # +
        params: { state: "pending", commit: "repo" }     # +
      - task: "unit-tests"
        file: "repo/ci/unit-tests/task.yml"
        on_failure:
          - put: "repo-status"                           # +
            params: { state: "failure", commit: "repo" } # +
      - put: "repo-status"                               # +
        params: { state: "success", commit: "repo" }     # +
resources:
  - name: "repo"
    type: "git"
    source:
      uri: {{repo_uri}}
      branch: {{repo_branch}}
  - name: "repo-status"                                  # +
    type: "github-status"                                # +
    source:                                              # +
      repository: {{repo_github_path}}                   # +
      access_token: {{repo_github_token}}                # +
```

When testing pull requests, use the PR ref as the `branch`. For example, if testing PR #12345 to your repository, your resource might look like...

```yaml
name: "pr-status"
type: "github-status"
source:
  repository: {{repo_github_path}}
  access_token: {{repo_github_token}}
  branch: "pull/12345/head"           # +
```

For another pipeline example, see [`ci/pipelines/main.yml`](ci/pipelines/main.yml) which operates against this repository.

## Installation

This resource is not included with the standard Concourse release. Add it to your pipeline's `resource_types` definition.

```yaml
resource_types:
  - name: "github-status"
    type: "docker-image"
    source:
      repository: "dpb587/github-status-resource"
      tag: "master"
```

## References

 * [Resources (concourse.ci)](https://concourse.ci/resources.html)
 * [Statuses | GitHub Developer Guide (developer.github.com)](https://developer.github.com/v3/repos/statuses/)
 * [Enabling required status checks (help.github.com)](https://help.github.com/articles/enabling-required-status-checks/)
 * [Personal Access Tokens (github.com)](https://github.com/settings/tokens)

## License

[MIT License](./LICENSE)
