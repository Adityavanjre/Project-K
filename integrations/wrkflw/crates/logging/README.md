## wrkflw-logging

Lightweight in-memory logging with simple levels for TUI/CLI output.

- Thread-safe, timestamped messages
- Level filtering (Debug/Info/Warning/Error)
- Pluggable into UI for live log views

### Example

```rust
use wrkflw_logging::{info, warning, error, LogLevel, set_log_level, get_logs};

set_log_level(LogLevel::Info);
info("starting");
warning("be careful");
error("boom");

for line in get_logs() {
    println!("{}", line);
}
```
