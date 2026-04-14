#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="BugPet"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"
DMG_STAGING_DIR="$ROOT_DIR/dist/.dmg-staging"
NOTES_FILE="$DMG_STAGING_DIR/Install Notes.txt"

"$ROOT_DIR/scripts/package_app.sh"

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  exit 1
fi

rm -rf "$DMG_STAGING_DIR" "$DMG_PATH"
mkdir -p "$DMG_STAGING_DIR"

cp -R "$APP_DIR" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

cat > "$NOTES_FILE" <<'EOF'
BugPet Install Notes

1. Drag BugPet.app into Applications.
2. Open BugPet from Applications.
3. If macOS blocks the app on first launch:
   System Settings -> Privacy & Security -> allow BugPet / Open Anyway.

BugPet 安装说明

1. 将 BugPet.app 拖到 Applications。
2. 从 Applications 打开 BugPet。
3. 如果首次打开被 macOS 拦截：
   前往 系统设置 -> 隐私与安全性 -> 允许 BugPet / 仍要打开。
EOF

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGING_DIR"

echo "Packaged dmg:"
echo "$DMG_PATH"
