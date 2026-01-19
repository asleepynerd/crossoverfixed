#!/bin/bash
set -e

CROSSOVER_MACOS_PATH="/Users/r.fink29/Downloads/Apps/CrossOver.app"
CONTENTS="$CROSSOVER_MACOS_PATH/Contents"
MACOS="$CONTENTS/MacOS"

REPO_URL="https://github.com/RavNut2/crossoverfixed.git"
RAW_URL="https://raw.githubusercontent.com/RavNut2/crossoverfixed/main"
RELEASE_URL="https://github.com/RavNut2/crossoverfixed/releases/latest/download/hook.dylib"

WORKDIR="$(mktemp -d)"

if [ ! -d "$CROSSOVER_MACOS_PATH" ]; then
    echo "CrossOver.app not found at $CROSSOVER_MACOS_PATH"
    exit 1
fi

cd "$WORKDIR"

# ---------- fetch sources ----------
if command -v git >/dev/null; then
    git clone "$REPO_URL" src
else
    mkdir src
    curl -L -o src/pco.sh "$RAW_URL/pco.sh"
    curl -L -o src/hook.m "$RAW_URL/hook.m"
fi

cd src

# ---------- build or download ----------
if command -v clang >/dev/null && [ -f hook.m ]; then
    clang -dynamiclib \
        -framework Foundation \
        -framework AppKit \
        -o hook.dylib hook.m \
    || curl -L -o hook.dylib "$RELEASE_URL"
else
    curl -L -o hook.dylib "$RELEASE_URL"
fi

if [ ! -f hook.dylib ]; then
    echo "hook.dylib missing"
    exit 1
fi

# ---------- install ----------
cp hook.dylib "$MACOS/"
cp pco.sh "$MACOS/CrossOver"

chmod +x "$MACOS/CrossOver"

# ---------- sign ----------
codesign -f -s - "$MACOS/hook.dylib"
codesign --deep --force --sign - "$CROSSOVER_MACOS_PATH"

# ---------- cleanup ----------
rm -rf "$WORKDIR"

echo "Done. Launch CrossOver normally."
