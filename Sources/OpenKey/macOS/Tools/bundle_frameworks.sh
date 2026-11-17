#!/bin/bash
set -e

APP_PATH="${1:-/Users/viethoavnm/Library/Developer/Xcode/DerivedData/OpenKey-covjkzubqnuuseappavscqftpjbv/Build/Products/Release/LibreKey.app}"
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    exit 1
fi

BIN_PATH="$APP_PATH/Contents/MacOS/LibreKey"
FW_DIR="$APP_PATH/Contents/Frameworks"
mkdir -p "$FW_DIR"

DEPS=(
    "/opt/homebrew/opt/librime/lib/librime.1.dylib"
    "/opt/homebrew/opt/glog/lib/libglog.2.dylib"
    "/opt/homebrew/opt/yaml-cpp/lib/libyaml-cpp.0.9.dylib"
    "/opt/homebrew/opt/gflags/lib/libgflags.2.3.dylib"
    "/opt/homebrew/opt/leveldb/lib/libleveldb.1.dylib"
    "/opt/homebrew/opt/marisa/lib/libmarisa.0.dylib"
    "/opt/homebrew/opt/opencc/lib/libopencc.1.4.dylib"
    "/opt/homebrew/opt/snappy/lib/libsnappy.1.dylib"
)

echo "Copying dylibs to $FW_DIR..."
for dep in "${DEPS[@]}"; do
    base="$(basename "$dep")"
    cp -f "$dep" "$FW_DIR/$base"
    chmod 755 "$FW_DIR/$base"
done

echo "Fixing install names..."
# Fix main binary
install_name_tool -change "/opt/homebrew/opt/librime/lib/librime.1.dylib" "@rpath/librime.1.dylib" "$BIN_PATH" 2>/dev/null || true

# Fix librime
RIME_DYLIB="$FW_DIR/librime.1.dylib"
install_name_tool -id "@rpath/librime.1.dylib" "$RIME_DYLIB" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/glog/lib/libglog.2.dylib" "@rpath/libglog.2.dylib" "$RIME_DYLIB" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/yaml-cpp/lib/libyaml-cpp.0.9.dylib" "@rpath/libyaml-cpp.0.9.dylib" "$RIME_DYLIB" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/gflags/lib/libgflags.2.3.dylib" "@rpath/libgflags.2.3.dylib" "$RIME_DYLIB" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/leveldb/lib/libleveldb.1.dylib" "@rpath/libleveldb.1.dylib" "$RIME_DYLIB" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/marisa/lib/libmarisa.0.dylib" "@rpath/libmarisa.0.dylib" "$RIME_DYLIB" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/opencc/lib/libopencc.1.4.dylib" "@rpath/libopencc.1.4.dylib" "$RIME_DYLIB" 2>/dev/null || true

# Fix internal dependencies among secondary dylibs (prevents double-loading of gflags/snappy/marisa)
install_name_tool -change "/opt/homebrew/opt/gflags/lib/libgflags.2.3.dylib" "@rpath/libgflags.2.3.dylib" "$FW_DIR/libglog.2.dylib" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/marisa/lib/libmarisa.0.dylib" "@rpath/libmarisa.0.dylib" "$FW_DIR/libopencc.1.4.dylib" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/snappy/lib/libsnappy.1.dylib" "@rpath/libsnappy.1.dylib" "$FW_DIR/libleveldb.1.dylib" 2>/dev/null || true

# Fix IDs and re-sign each framework
for f in "$FW_DIR"/*.dylib; do
    base="$(basename "$f")"
    install_name_tool -id "@rpath/$base" "$f" 2>/dev/null || true
    codesign --force --sign - "$f"
done

# Re-sign the app bundle
codesign --force --sign - --deep "$APP_PATH"

echo "Framework bundling completed successfully."
