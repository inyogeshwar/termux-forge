#!/usr/bin/env bash
# Smoke tests for termux-forge — Termux ke bina chalte hain (stubs ke saath).
# Run:  bash tests/smoke.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE="$ROOT/forge.sh"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

export HOME="$T/home" PREFIX="$T/prefix" TMPDIR="$T/prefix/tmp" TERM=dumb
export TERMUX_VERSION=1 ANDROID_SDK="$T/home/android-sdk"
mkdir -p "$HOME" "$PREFIX/bin" "$TMPDIR" "$T/stubs" "$HOME/storage/downloads" "$HOME/.forge/wrapper/gradle"

# ── stubs ──
mk() { printf '%s\n' "#!/bin/sh" "$2" > "$T/stubs/$1"; chmod +x "$T/stubs/$1"; }
mk pkg 'echo "[stub pkg] $*"'
mk dpkg 'exit 1'
mk termux-open 'echo "$1" > "$HOME/.opened"'
mk gradle 'echo "[stub gradle] $*"'
mk convert 'for a; do o="$a"; done; echo img > "$o"'
mk keytool 'while [ $# -gt 0 ]; do [ "$1" = "-keystore" ] && ks="$2"; shift; done; [ -n "$ks" ] && echo ks > "$ks"'
export PATH="$T/stubs:$PATH"
# stub gradle wrapper: APK/AAB banata hai
cat > "$HOME/.forge/wrapper/gradlew" <<'EOF'
#!/bin/sh
case "$1" in
  assembleDebug)   mkdir -p app/build/outputs/apk/debug;   echo apk > app/build/outputs/apk/debug/app-debug.apk ;;
  assembleRelease) mkdir -p app/build/outputs/apk/release; echo apk > app/build/outputs/apk/release/app-release.apk ;;
  bundleRelease)   mkdir -p app/build/outputs/bundle/release; echo aab > app/build/outputs/bundle/release/app-release.aab ;;
  *) exit 2 ;;
esac
echo "[stub gradlew] $*"
EOF

PASS=0; FAIL=0
t() { # t "name" command...
  local name=$1; shift
  if "$@" >"$T/out.log" 2>&1; then PASS=$((PASS + 1)); printf '  ✓ %s\n' "$name"
  else FAIL=$((FAIL + 1)); printf '  ✗ %s\n' "$name"; sed 's/^/      /' "$T/out.log" | head -15; fi
}
forge() { bash "$FORGE" --cli "$@"; }
has()   { grep -qF -- "$2" "$1"; }
nothas() { ! grep -qF -- "$2" "$1"; }

echo "== syntax =="
t "bash -n forge.sh"     bash -n "$FORGE"
t "bash -n install.sh"   bash -n "$ROOT/install.sh"
t "bash -n uninstall.sh" bash -n "$ROOT/uninstall.sh"

echo "== basic =="
t "version"     bash -c "out=\$(bash '$FORGE' --cli version); [[ \$out == 'termux-forge v7'* ]]"
t "help"        bash -c "out=\$(bash '$FORGE' --cli help); [[ \$out == *'create <name>'* ]]"
t "unknown cmd fails" bash -c "! bash '$FORGE' --cli nonsense"
t "create before setup is refused" bash -c "! bash '$FORGE' --cli create x"

echo "== base template + keystore =="
t "make_base_template" bash -c "source '$FORGE'; make_base_template"
t "template files"     bash -c "test -f \$HOME/hello-forge/app/build.gradle && test -x \$HOME/hello-forge/gradlew"
t "ensure_keystore (random pass)" bash -c "source '$FORGE'; ensure_keystore"
t "keystore.properties written"  bash -c "grep -q FORGE_STORE_PASS \$HOME/.forge/keystore.properties"
t "password is not default"      bash -c "! grep -q forgerelease \$HOME/.forge/keystore.properties"
t "gradle.properties has pass"   bash -c "grep -q FORGE_STORE_PASS \$HOME/.gradle/gradle.properties"
t "keystore re-run is idempotent" bash -c "source '$FORGE'; ensure_keystore; test \$(grep -c FORGE_STORE_PASS \$HOME/.gradle/gradle.properties) -eq 1"

echo "== create =="
t "create kotlin (flags, special label)" forge create notes --name 'My Notes & <Pro>' --package com.yogesh.notes
M="$HOME/notes/app/src/main/AndroidManifest.xml"
t "label is XML-escaped"        has "$M" 'My Notes &amp; &lt;Pro&gt;'
t "package in gradle"           has "$HOME/notes/app/build.gradle" "com.yogesh.notes"
t "kt moved to new package dir" test -f "$HOME/notes/app/src/main/java/com/yogesh/notes/MainActivity.kt"
t "old package dir removed"     test ! -d "$HOME/notes/app/src/main/java/com/forge"
t "rootProject.name updated"    has "$HOME/notes/settings.gradle" 'rootProject.name = "notes"'
t "create duplicate refused"    bash -c "! bash '$FORGE' --cli create notes --package com.a.b"
t "invalid package refused"     bash -c "! bash '$FORGE' --cli create bad --package 'bad pkg'"
t "invalid name refused"        bash -c "! bash '$FORGE' --cli create 'a/b'"
t "default package generated"   forge create 9lives
t "default pkg starts w/ letter" has "$HOME/9lives/app/build.gradle" "com.forge.app9lives"

echo "== webview template =="
t "webview needs url"  bash -c "! bash '$FORGE' --cli create web --template webview --package com.a.web"
t "webview rejects bad url" bash -c "! bash '$FORGE' --cli create web --template webview --package com.a.web --url 'javascript:alert(1)'"
t "webview create (url has &)" forge create web --template webview --package com.yogesh.web --url 'https://example.com/?a=1&b=2'
WK="$HOME/web/app/src/main/java/com/yogesh/web/MainActivity.kt"
t "url written verbatim"   has "$WK" 'loadUrl("https://example.com/?a=1&b=2")'
t "package in kt"          has "$WK" "package com.yogesh.web"
t "INTERNET permission"    has "$HOME/web/app/src/main/AndroidManifest.xml" "android.permission.INTERNET"
t "unknown template refused" bash -c "! bash '$FORGE' --cli create z --template compose"

echo "== project commands =="
t "list shows projects"  bash -c "out=\$(bash '$FORGE' --cli list); [[ \$out == *notes* ]]"
t "package (nested subpkg kept)" bash -c "
  mkdir -p \$HOME/notes/app/src/main/java/com/yogesh/notes/ui
  echo 'package com.yogesh.notes.ui' > \$HOME/notes/app/src/main/java/com/yogesh/notes/ui/Screen.kt
  bash '$FORGE' --cli package notes com.new.app
  test -f \$HOME/notes/app/src/main/java/com/new/app/ui/Screen.kt &&
  grep -q 'package com.new.app.ui' \$HOME/notes/app/src/main/java/com/new/app/ui/Screen.kt &&
  test ! -d \$HOME/notes/app/src/main/java/com/yogesh"
t "rename"   forge rename notes 'Super "Notes"'
t "rename escaped" has "$M" 'Super &quot;Notes&quot;'
t "bump patch" bash -c "bash '$FORGE' --cli bump notes && grep -q 'versionName \"1.0.1\"' \$HOME/notes/app/build.gradle && grep -q 'versionCode 2' \$HOME/notes/app/build.gradle"
t "bump minor" bash -c "bash '$FORGE' --cli bump minor notes && grep -q 'versionName \"1.1.0\"' \$HOME/notes/app/build.gradle"
t "bump major" bash -c "bash '$FORGE' --cli bump major notes && grep -q 'versionName \"2.0.0\"' \$HOME/notes/app/build.gradle"
echo img > "$T/logo.png"
t "icon"          forge icon notes "$T/logo.png"
t "icon mipmaps"  test -f "$HOME/notes/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
t "icon in manifest" has "$M" 'android:icon="@mipmap/ic_launcher"'
t "icon twice no dup" bash -c "bash '$FORGE' --cli icon notes '$T/logo.png' && test \$(grep -o 'android:icon=' '$M' | wc -l) -eq 1"
t "repair"  forge repair notes
t "import"  bash -c "mkdir -p '$T/ext/OldApp/app' && touch '$T/ext/OldApp/settings.gradle' && bash '$FORGE' --cli import '$T/ext/OldApp' && test -f \$HOME/OldApp/local.properties"

echo "== build / export / install =="
t "build debug"   bash -c "cd \$HOME/notes && bash '$FORGE' --cli build"
t "debug apk exists" test -f "$HOME/notes/app/build/outputs/apk/debug/app-debug.apk"
t "build release" forge build release notes
t "bundle"        forge bundle notes
t "export all"    forge export notes
t "export naming" bash -c "ls \$HOME/storage/downloads/ForgeApps | grep -q 'notes-2.0.0-release.aab'"
t "install opens apk" bash -c "bash '$FORGE' --cli install notes && grep -q app-debug.apk \$HOME/.opened"
t "build without project fails" bash -c "cd / && ! HOME=/nonexistent-home bash '$FORGE' --cli build"

echo "== keystore / backup / clean =="
t "keystore info"   forge keystore info
t "keystore backup" bash -c "bash '$FORGE' --cli keystore backup && ls \$HOME/storage/downloads/ForgeBackups | grep -q keystore-"
t "project backup"  bash -c "bash '$FORGE' --cli backup notes && ls \$HOME/storage/downloads/ForgeBackups | grep -q '^notes-'"
t "backup excludes build" bash -c "! tar tzf \$HOME/storage/downloads/ForgeBackups/notes-*.tar.gz | grep -q '/build/'"
t "clean"           bash -c "bash '$FORGE' --cli clean notes && test ! -d \$HOME/notes/app/build"
t "doctor runs"     bash -c "bash '$FORGE' --cli doctor >/dev/null 2>&1; test \$? -ne 127"

echo "== setup helpers =="
t "zshrc block replaced, not duplicated" bash -c "
  source '$FORGE'; write_zshrc_block; write_zshrc_block
  test \$(grep -c '# ── FORGE_ZSHRC' \$HOME/.zshrc) -eq 1 && grep -q 'compdef _forge forge' \$HOME/.zshrc && grep -q 'build-tools/35.0.0' \$HOME/.zshrc"
t "step_finalize survives same-file" bash -c "
  mkdir -p \$HOME/.local/share/termux-forge; cp '$FORGE' \$HOME/.local/share/termux-forge/forge.sh
  bash -c 'source \$HOME/.local/share/termux-forge/forge.sh; step_finalize' && test -x \$PREFIX/bin/forge"
t "pkg_install (stub)" bash -c "source '$FORGE'; pkg_install git curl"
t "uninstall keeps keystore" bash -c "bash '$ROOT/uninstall.sh' --yes --keep-sdk >/dev/null 2>&1; test -f \$HOME/.forge/release.keystore && test ! -d \$HOME/hello-forge"
t "uninstall --purge removes keystore" bash -c "bash '$ROOT/uninstall.sh' --yes --purge >/dev/null 2>&1; test ! -d \$HOME/.forge"

echo
echo "Passed: $PASS   Failed: $FAIL"
[[ "$FAIL" -eq 0 ]]
