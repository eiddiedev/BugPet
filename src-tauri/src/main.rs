#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::Serialize;
use std::process::Command;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct ActivitySnapshot {
  app_name: String,
  window_title: String,
  idle_seconds: f64,
}

#[tauri::command]
fn get_activity_snapshot() -> Result<ActivitySnapshot, String> {
  let (app_name, window_title) = frontmost_window_context()?;

  Ok(ActivitySnapshot {
    app_name,
    window_title,
    idle_seconds: idle_seconds(),
  })
}

#[cfg(target_os = "macos")]
fn frontmost_window_context() -> Result<(String, String), String> {
  let script = r#"
tell application "System Events"
  set frontApp to first application process whose frontmost is true
  set appName to name of frontApp
  set windowTitle to ""
  try
    set windowTitle to name of front window of frontApp
  end try
  return appName & linefeed & windowTitle
end tell
"#;

  let output = Command::new("osascript")
    .arg("-e")
    .arg(script)
    .output()
    .map_err(|error| format!("failed to query frontmost app: {error}"))?;

  if !output.status.success() {
    return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
  }

  let stdout = String::from_utf8_lossy(&output.stdout);
  let mut lines = stdout.lines();
  let app_name = lines.next().unwrap_or_default().trim().to_string();
  let window_title = lines.collect::<Vec<_>>().join(" ").trim().to_string();

  Ok((app_name, window_title))
}

#[cfg(not(target_os = "macos"))]
fn frontmost_window_context() -> Result<(String, String), String> {
  Err("activity monitoring is currently only implemented for macOS".into())
}

#[cfg(target_os = "macos")]
fn idle_seconds() -> f64 {
  unsafe { CGEventSourceSecondsSinceLastEventType(0, u32::MAX) }
}

#[cfg(not(target_os = "macos"))]
fn idle_seconds() -> f64 {
  0.0
}

#[cfg(target_os = "macos")]
#[link(name = "CoreGraphics", kind = "framework")]
extern "C" {
  fn CGEventSourceSecondsSinceLastEventType(state_id: i32, event_type: u32) -> f64;
}

fn main() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![get_activity_snapshot])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
