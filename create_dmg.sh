#!/bin/bash

# === Configuration: PLEASE UPDATE THESE VALUES ===

APP_NAME="oioi"
SOURCE_APP_PATH="/Users/visheshyadav/Desktop/${APP_NAME}.app"
FINAL_DMG_NAME="${APP_NAME}_Installer.dmg"
VOLUME_NAME="${APP_NAME}"
VOLUME_ICON_PATH="./oioi_AppIcon.icns"
DMG_SIZE="250m"

# --- Enhanced Window and Icon Layout ---
WINDOW_BOUNDS="{200, 100, 1100, 600}" # Clean centered layout
ICON_SIZE="128"
APP_ICON_POS="300 260"
APPLICATIONS_LINK_POS="700 260"

# === Script Starts ===
echo "🚀 Starting DMG creation for ${APP_NAME}..."

APP_FILE="${APP_NAME}.app"
TEMP_DMG_NAME="temp_${FINAL_DMG_NAME}"
SOURCE_APP_DIR=$(dirname "$SOURCE_APP_PATH")

# --- Pre-checks ---
if [ ! -d "$SOURCE_APP_PATH" ]; then
  echo "❌ Error: Source app not found at '$SOURCE_APP_PATH'"
  exit 1
fi

codesign -dv --verbose=2 "$SOURCE_APP_PATH" > /dev/null 2>&1 || echo "⚠️ App might not be code-signed."

USE_VOLUME_ICON=false
if [ -n "$VOLUME_ICON_PATH" ] && [ -f "$VOLUME_ICON_PATH" ]; then
  USE_VOLUME_ICON=true
  echo "📌 Using volume icon: $VOLUME_ICON_PATH"
fi

if ! command -v SetFile &> /dev/null; then
  echo "⚠️ 'SetFile' not found. Install Xcode CLI tools: xcode-select --install"
fi

# --- Staging ---
echo "📁 Creating temp dir..."
TEMP_DIR=$(mktemp -d)
trap 'echo "🧹 Cleaning..."; rm -rf "$TEMP_DIR"; hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1 || true; rm -f "$TEMP_DMG_NAME"; exit' INT TERM EXIT
trap 'echo "❌ Error occurred."; exit 1' ERR

cp -Rp "$SOURCE_APP_PATH" "$TEMP_DIR/"
ln -s /Applications "$TEMP_DIR/Applications"

# --- Create Temp DMG ---
echo "📦 Creating temp DMG..."
hdiutil create -srcfolder "$TEMP_DIR" -volname "$VOLUME_NAME" -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" -format UDRW -size $DMG_SIZE "$TEMP_DMG_NAME"

MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG_NAME")
MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/.*' | head -n 1)
if [ -z "$MOUNT_POINT" ]; then
  echo "❌ Could not mount DMG."
  echo "$MOUNT_OUTPUT"
  exit 1
fi
echo "✅ Mounted at: $MOUNT_POINT"

# --- Customization ---
if $USE_VOLUME_ICON && command -v SetFile &> /dev/null; then
  echo "🎨 Applying volume icon..."
  cp "$VOLUME_ICON_PATH" "$MOUNT_POINT/.VolumeIcon.icns"
  SetFile -a C "$MOUNT_POINT"
fi

echo "🎨 Setting Finder layout..."
osascript <<EOT
  tell application "Finder"
    tell disk "${VOLUME_NAME}"
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to ${WINDOW_BOUNDS}
      set viewOptions to the icon view options of container window
      set arrangement of viewOptions to not arranged
      set icon size of viewOptions to ${ICON_SIZE}
      set position of item "${APP_FILE}" of container window to {${APP_ICON_POS}}
      set position of item "Applications" of container window to {${APPLICATIONS_LINK_POS}}
      delay 1
      update without registering applications
      delay 1
      close
    end tell
  end tell
EOT

echo "📦 Blessing folder..."
bless --folder "$MOUNT_POINT"

sync; sync

# --- Finalize ---
echo "📤 Unmounting..."
hdiutil detach "$MOUNT_POINT" -force

echo "🗜️ Compressing to final DMG..."
hdiutil convert "$TEMP_DMG_NAME" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG_NAME"

rm -f "$TEMP_DMG_NAME"
trap - INT TERM EXIT ERR
rm -rf "$TEMP_DIR"

echo "🎉 Done! DMG created: ${FINAL_DMG_NAME}"
echo "💡 Test on another machine to verify."

exit 0