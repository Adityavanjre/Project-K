## wrkflw-gitlab

GitLab integration helpers used by `wrkflw` to trigger pipelines.

- Reads repo info from local git remote
- Triggers pipelines via GitLab API

### Example

```rust
use wrkflw_gitlab::{get_repo_info, trigger_pipeline};

# tokio_test::block_on(async {
let info = get_repo_info()?;
println!("{}/{} (default branch: {})", info.namespace, info.project, info.default_branch);

// Requires GITLAB_TOKEN in env (api scope)
trigger_pipeline(Some("main"), None).await?;
# Ok::<_, Box<dyn std::error::Error>>(())
# })?;
```

Notes: looks for `.gitlab-ci.yml` in the repo root when listing pipelines.
