# BugPet Handoff

This file is for continuing the BugPet MVP in TraeSolo.

## Current Status

Completed steps:

- Step 1: Tauri + React + TypeScript baseline is running
- Step 2: Floating window shell is working
- Step 3: Basic pet UI and speech bubble are implemented

## What Was Changed

### Project structure

- Removed the old Electron leftovers and aligned the project to pure Tauri
- Moved Tauri config to `src-tauri/tauri.conf.json`
- Added `src-tauri/build.rs`
- Added working scripts in `package.json`:
  - `npm run dev`
  - `npm run build`
  - `npm run tauri:dev`
  - `npm run tauri:build`

### Window behavior

- Window is frameless
- Window is always on top
- Window is transparent
- Window is non-resizable
- Enabled `macOSPrivateApi` for transparent window support on macOS

### Pet UI

- The first pet body uses `src/assets/bugpet-pet.png`
- The image provided by the user is treated as the pet itself, not as the app logo
- Added:
  - pet image
  - pet shadow
  - speech bubble

### Interaction fixes

- Removed the unwanted green glow in the top-left corner by making the root background fully transparent
- Bubble now appears on hover
- Dragging now uses `appWindow.startDragging()` on the pet container instead of relying only on drag-region markup

### TypeScript fix

- Added `src/vite-env.d.ts` so PNG imports compile correctly

## Important Files

- `package.json`
- `src-tauri/tauri.conf.json`
- `src/App.tsx`
- `src/App.css`
- `src/index.css`
- `src/assets/bugpet-pet.png`

## Verified Working

- `npm run build`
- `cargo check --manifest-path src-tauri/Cargo.toml`
- `npm run tauri:dev`

## MVP TODO

### Step 4: Behavior monitoring

- Detect current active app/window name
- Specifically identify:
  - TRAE SOLO
  - Codex
- Detect idle vs active state

Suggested MVP direction:

- Prefer Tauri-side commands for system integration
- Keep the frontend as a thin renderer
- Return simple structured data to React

### Step 5: State engine

- Implement only 3 states:
  - `idle`
  - `focused`
  - `chaotic`

Suggested simple rules:

- idle: no input for more than 60s
- focused: active input continues for more than 30s
- chaotic: more than 5 app/window switches within 60s

### Step 6: Text feedback

- Map state to random text

Initial copy:

- idle:
  - `你又消失了`
  - `是在思考还是发呆？`
- focused:
  - `这波状态不错`
  - `继续保持`
- chaotic:
  - `你现在有点乱`
  - `你到底在干嘛？`

## Constraints To Keep

- Do not over-engineer
- Keep it MVP-only
- Do not add AI integration
- Do not add complex animation systems
- Do not add cloud or account features
- Do not introduce Redux or heavy state management
- Prefer small hooks and simple functions

## Notes

- The Tauri app icon currently reuses the same image only as a temporary technical placeholder because Tauri requires an icon file to start
- If a proper app icon is added later, replace `src-tauri/icons/icon.png`
