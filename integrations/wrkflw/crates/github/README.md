## wrkflw-github

GitHub integration helpers used by `wrkflw` to list/trigger workflows.

- **List workflows** in `.github/workflows`
- **Trigger workflow_dispatch** events over the GitHub API

### Example

```rust
use wrkflw_github::{get_repo_info, trigger_workflow};

# tokio_test::block_on(async {
let info = get_repo_info()?;
println!("{}/{} (default branch: {})", info.owner, info.repo, info.default_branch);

// Requires GITHUB_TOKEN in env
trigger_workflow("ci", Some("main"), None).await?;
# Ok::<_, Box<dyn std::error::Error>>(())
# })?;
```

Notes: set `GITHUB_TOKEN` with the `workflow` scope; only public repos are supported out-of-the-box.
