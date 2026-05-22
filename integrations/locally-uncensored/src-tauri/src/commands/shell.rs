use std::io::Read;
use std::process::{Command, Stdio};

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

#[cfg(target_os = "windows")]
const CREATE_NO_WINDOW: u32 = 0x08000000;

#[tauri::command]
pub async fn shell_execute(
    command: String,
    args: Option<Vec<String>>,
    cwd: Option<String>,
    timeout: Option<u64>,
    shell: Option<String>,
) -> Result<serde_json::Value, String> {
    tokio::task::spawn_blocking(move || {
        shell_execute_sync(command, args, cwd, timeout, shell)
    })
    .await
    .map_err(|e| format!("Task join error: {}", e))?
}

fn shell_execute_sync(
    command: String,
    args: Option<Vec<String>>,
    cwd: Option<String>,
    timeout: Option<u64>,
    shell: Option<String>,
) -> Result<serde_json::Value, String> {
    let timeout_ms = timeout.unwrap_or(120_000);
    let shell_bin = shell.unwrap_or_else(|| {
        if cfg!(target_os = "windows") {
            "powershell".to_string()
        } else {
            "bash".to_string()
        }
    });

    let mut cmd = Command::new(&shell_bin);

    // Build shell command
    if cfg!(target_os = "windows") && shell_bin.to_lowercase().contains("powershell") {
        cmd.arg("-NoProfile").arg("-NonInteractive").arg("-Command").arg(&command);
    } else if cfg!(target_os = "windows") && shell_bin.to_lowercase().contains("cmd") {
        cmd.arg("/C").arg(&command);
    } else {
        cmd.arg("-c").arg(&command);
    }

    // Append extra args
    if let Some(extra_args) = args {
        for a in extra_args {
            cmd.arg(&a);
        }
    }

    // Working directory — validate it exists
    if let Some(ref dir) = cwd {
        let path = std::path::Path::new(dir);
        if path.is_dir() {
            cmd.current_dir(path);
        }
    }

    cmd.stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());

    #[cfg(target_os = "windows")]
    cmd.creation_flags(CREATE_NO_WINDOW);

    let mut child = cmd.spawn().map_err(|e| format!("Spawn shell: {}", e))?;

    let start = std::time::Instant::now();
    let timeout_dur = std::time::Duration::from_millis(timeout_ms);

    loop {
        match child.try_wait() {
            Ok(Some(status)) => {
                let mut stdout_str = String::new();
                let mut stderr_str = String::new();
                if let Some(mut stdout) = child.stdout.take() {
                    let _ = stdout.read_to_string(&mut stdout_str);
                }
                if let Some(mut stderr) = child.stderr.take() {
                    let _ = stderr.read_to_string(&mut stderr_str);
                }
                return Ok(serde_json::json!({
                    "stdout": stdout_str,
                    "stderr": stderr_str,
                    "exitCode": status.code().unwrap_or(-1),
                    "timedOut": false,
                }));
            }
            Ok(None) => {
                if start.elapsed() > timeout_dur {
                    let _ = child.kill();
                    return Ok(serde_json::json!({
                        "stdout": "",
                        "stderr": format!("Execution timed out after {}ms", timeout_ms),
                        "exitCode": -1,
                        "timedOut": true,
                    }));
                }
                std::thread::sleep(std::time::Duration::from_millis(50));
            }
            Err(e) => return Err(format!("Wait error: {}", e)),
        }
    }
}
