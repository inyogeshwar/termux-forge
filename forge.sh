#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  ⚒️  TERMUX-FORGE — Ultimate Setup & CLI v6.5.0          ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

readonly FORGE_VERSION="6.5.0"
readonly GRADLE_VER="8.9"
readonly AGP_VER="8.7.3"
readonly KOTLIN_VER="2.0.21"
readonly SDK_PLATFORM="android-35"
readonly BUILD_TOOLS_VER="35.0.0"
readonly CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

FORGE_DIR="${FORGE_DIR:-$HOME/.forge}"
ANDROID_SDK="${ANDROID_SDK:-$HOME/android-sdk}"
TEST_APP="$HOME/hello-forge"

FORGE_NAME="${FORGE_NAME:-${FORGE_YES:+Forge}}"
FORGE_YES="${FORGE_YES:-0}"
SKIP_ANDROID="${SKIP_ANDROID:-0}"
SKIP_TEST_APK="${SKIP_TEST_APK:-0}"

if [[ -t 1 ]]; then
  R=$'\033[0m'; B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'
  BL=$'\033[34m'; RE=$'\033[31m'; CY=$'\033[36m'; MG=$'\033[35m'
else
  R=''; B=''; G=''; Y=''; BL=''; RE=''; CY=''; MG=''
fi

log()  { printf '%s➜%s %s\n' "$BL$B" "$R" "$*"; }
ok()   { printf '%s✓%s %s\n' "$G" "$R" "$*"; }
warn() { printf '%s⚠%s %s\n' "$Y" "$R" "$*" >&2; }
die()  { printf '%s✗%s %s\n' "$RE" "$R" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

banner() {
  clear
  cat <<EOF
${CY}┌────────────────────────────────────┐${R}
${CY}│${R}  ${MG}${B}⚒️  T E R M U X - F O R G E${R}${CY}│${R}${CY}├────────────────────────────────────┤${R}${CY}│${R}${G}🎯 v${FORGE_VERSION}${R}  ${CY}│${R}  ${Y}🤖 OpenCode${R}  ${CY}│${R}  ${BL}⚙️ SDK${R} ${CY}│${R}
${CY}│${R}  ${BL}👤 github.com/inyogeshwar${R}          ${CY}│${R}
${CY}└────────────────────────────────────┘${R}
EOF
}

ask_name() {
  local name
  if [[ -n "$FORGE_NAME" ]]; then
    name="$FORGE_NAME"
  elif [[ "$FORGE_YES" == "1" ]]; then
    name="Forge"
  else
    printf '\n%s┌──────────────────────────────────────────────┐%s\n' "$CY" "$R"
    printf '%s│%s  🖊️  Apna naam likho (banner ke liye)          %s│%s\n' "$CY" "$R" "$CY" "$R"
    printf '%s└──────────────────────────────────────────────┘%s\n' "$CY" "$R"
    printf '➜ Your Name: '
    read -r name </dev/tty || name="Forge"
    name="${name:-Forge}"
  fi
  name="${name// /}"
  mkdir -p "$FORGE_DIR"
  echo "$name" > "$FORGE_DIR/.name"
  ok "🎨 Banner set: $name"
  printf '\n'
}

pkg_install() {
  local pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  local missing=()
  local p
  for p in "${pkgs[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 \vert{}\vert{} missing+=("$p")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  log "📦 Installing: ${missing[*]}"
  mkdir -p "$FORGE_DIR"
  local log_file="$FORGE_DIR/pkg_install.log"
  local attempt

  for attempt in {1..3}; do
    if pkg install -y --no-install-recommends "${missing[@]}" 2>&1 \vert{} tee "$log_file"; then
      ok "✓ Packages installed."
      return 0
    fi
    if [[ $attempt -lt 3 ]]; then
      warn "⚠ Install fail (Attempt $attempt/3). Retrying in 3s..."
      sleep 3
    fi
  done

  warn "❌ pkg install failed."
  tail -n 15 "$log_file" >&2
  die "Check internet or run 'termux-change-repo'."
}

has_storage() { [[ -d "$HOME/storage" ]]; }

step_speedtest() {
  clear
  log "▰▱▱▱▱▱▱▱  [0/9] 🚀 Internet Speed Test..."
  if ! have speedtest-cli; then
    pkg_install python || true
    pip install speedtest-cli --quiet 2>/dev/null || true
    if ! have speedtest-cli; then
      curl -fsSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py \
        -o "$PREFIX/bin/speedtest-cli" && chmod +x "$PREFIX/bin/speedtest-cli" || true
    fi
  fi
  if have speedtest-cli || [[ -x "$PREFIX/bin/speedtest-cli" ]]; then
    log "⏳ Testing your network speed..."
    echo "--------------------------------------------------"
    speedtest-cli --simple || warn "🔔 Speedtest fail ho gaya, par setup continue rahega."
    echo "--------------------------------------------------"
    if [[ "$FORGE_YES" == "0" ]]; then
      printf '\n➜ Network theek lag raha hai? Setup start karne ke liye Enter dabao...'
      read -r _ </dev/tty || true
    fi
  fi
  sleep 1
}

step_storage() {
  clear
  log "▰▱▱▱▱▱▱▱  [1/9] 🔐 Storage access..."
  if has_storage; then ok "✅ Storage mil gaya"; return; fi
  termux-setup-storage >/dev/null 2>&1 || true
  local i
  for i in {1..15}; do has_storage && break; sleep 1; done
  has_storage && ok "✅ Storage mil gaya" || warn "🔔 Storage permission nahi mila"
  sleep 1
}

step_update() {
  clear
  log "▰▰▱▱▱▱▱▱  [2/9] 🔄 System update..."
  pkg update -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  pkg upgrade -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  ok "✅ System upgrade"
  sleep 1
}

step_packages() {
  clear
  log "▰▰▰▱▱▱▱▱  [3/9] 📦 Base packages (Optimized)..."
  pkg_install \
    git curl wget unzip zsh toilet \
    nodejs openjdk-17 gradle python \
    aapt aapt2 apksigner glibc-repo

  pkg update -y >/dev/null 2>&1 || true
  pkg_install glibc-runner
  ok "✅ Packages ready"
  sleep 1
}

step_shell() {
  clear
  log "▰▰▰▰▱▱▱▱  [4/9] 🐚 Oh My Zsh + Powerlevel10k..."

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 \
      || warn "🔔 Oh My Zsh install fail"
  fi

  local zc="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [[ -d "$zc/themes/powerlevel10k" ]] \
    || git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$zc/themes/powerlevel10k" >/dev/null 2>&1 || true
  [[ -d "$zc/plugins/zsh-autosuggestions" ]] \
    || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$zc/plugins/zsh-autosuggestions" >/dev/null 2>&1 || true

  echo "" > "$PREFIX/etc/motd"
  if [ -f "$HOME/.bashrc" ]; then
    grep -vE "PS1=|Welcome to Termux|termux-welcome" "$HOME/.bashrc" > "$HOME/.bashrc.tmp" || true
    mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
  fi

  if ! grep -q 'FORGE_ZSHRC' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'ZSHRC'

# ── FORGE_ZSHRC ──────────────────────────────────────────
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

export ANDROID_SDK_ROOT="$HOME/android-sdk"
export ANDROID_HOME="$HOME/android-sdk"
export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
export PATH="$PATH:$HOME/.opencode/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/35.0.0"

_forge_banner() {
  local name w out l max=0
  name=$(cat ~/.forge/.name 2>/dev/null || echo Forge)
  w=${COLUMNS:-49}
  out=$(toilet -w 1000 -f smblock -F border "$name" 2>/dev/null)
  while IFS= read -r l; do (( ${#l} > max )) && max=${#l}; done <<< "$out"
  (( max > w )) && out=$(toilet -w "$w" -f smblock "$name" 2>/dev/null)
  echo
  echo -e "\e[36m$out\e[0m"
}
[[ -o interactive ]] && _forge_banner
# ── END FORGE_ZSHRC ──────────────────────────────────────
ZSHRC
  fi

  if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
    chsh -s zsh 2>/dev/null || warn "🔔 chsh fail"
  fi
  ok "✅ zsh + p10k ready"
  sleep 1
}

step_opencode() {
  clear
  log "▰▰▰▰▰▱▱▱  [5/9] 🤖 OpenCode..."
  if have opencode; then ok "✅ OpenCode already installed"; return; fi

  local OC_DIR="$HOME/.opencode/bin"
  local OC_VER
  OC_VER=$(npm view opencode-linux-arm64 version 2>/dev/null) || OC_VER="1.19.5"

  mkdir -p "$OC_DIR"
  rm -rf "$TMPDIR/oc" && mkdir -p "$TMPDIR/oc" && cd "$TMPDIR/oc"

  if npm pack --silent "opencode-linux-arm64@$OC_VER" >/dev/null 2>&1; then
    tar xzf "opencode-linux-arm64-$OC_VER.tgz"
    mv -f package/bin/opencode "$OC_DIR/opencode-linux"
    chmod +x "$OC_DIR/opencode-linux"
    cat > "$PREFIX/bin/opencode" << 'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec grun "$HOME/.opencode/bin/opencode-linux" "$@"
EOF
    chmod +x "$PREFIX/bin/opencode"
    cd "$HOME"; rm -rf "$TMPDIR/oc"
    ok "✅ OpenCode installed"
  else
    warn "🔔 OpenCode install fail."
  fi
  sleep 1
}

step_android_sdk() {
  clear
  log "▰▰▰▰▰▰▱▱  [6/9] ⚙️  Android SDK..."
  [[ "$SKIP_ANDROID" == "1" ]] && { warn "⏭️  Android SDK skipped"; return; }

  export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
  mkdir -p "$ANDROID_SDK"
  local sdkmanager="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"

  if [[ ! -x "$sdkmanager" ]]; then
    log "📥 Downloading cmdline-tools (~100 MB)..."
    local zip="$TMPDIR/cmdline-tools.zip"
    curl -# -L "$CMDLINE_TOOLS_URL" -o "$zip" || die "❌ cmdline-tools download fail"
    rm -rf "$ANDROID_SDK/cmdline-tools"
    mkdir -p "$ANDROID_SDK/cmdline-tools"
    unzip -q "$zip" -d "$ANDROID_SDK/cmdline-tools"
    mv "$ANDROID_SDK/cmdline-tools/cmdline-tools" "$ANDROID_SDK/cmdline-tools/latest"
    rm -f "$zip"
  fi

  yes | "$sdkmanager" --sdk_root="$ANDROID_SDK" --licenses >/dev/null 2>&1 || true

  if [[ ! -d "$ANDROID_SDK/platforms/$SDK_PLATFORM" ]] || [[ ! -d "$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER" ]]; then
    log "📦 Downloading SDK components (~200 MB)..."
    "$sdkmanager" --sdk_root="$ANDROID_SDK" "platform-tools" "platforms;$SDK_PLATFORM" "build-tools;$BUILD_TOOLS_VER" \
      2>&1 | tee "$FORGE_DIR/sdk_download.log" || die "❌ sdkmanager install fail"
  fi

  log "🔗 Patching build-tools with Termux ARM binaries..."
  local BT="$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER"
  for t in aapt aapt2 aidl zipalign apksigner; do
    if [ -e "$BT/$t" ] && command -v "$t" >/dev/null; then
      local cmd_path=$(command -v "$t")
      if [ "$cmd_path" != "$BT/$t" ]; then
        ln -sf "$cmd_path" "$BT/$t" 2>/dev/null || true
      fi
    fi
  done

  mkdir -p "$HOME/.gradle"
  local GP="$HOME/.gradle/gradle.properties"
  touch "$GP"
  sed -i '/^android.aapt2FromMavenOverride=/d;/^org.gradle.jvmargs=/d;/^org.gradle.vfs.watch=/d;/^kotlin.daemon.jvmargs=/d' "$GP"
  cat >> "$GP" << EOF
android.aapt2FromMavenOverride=${PREFIX}/bin/aapt2
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.vfs.watch=false
kotlin.daemon.jvmargs=-Xmx1024m
EOF

  log "⚙️  Generating Gradle Wrapper ($GRADLE_VER) template..."
  local WR="$FORGE_DIR/wrapper-gen"
  rm -rf "$WR"; mkdir -p "$WR" && cd "$WR"
  touch settings.gradle
  gradle -q wrapper --gradle-version "$GRADLE_VER" --no-daemon >/dev/null 2>&1 || true
  if [ -f "$WR/gradlew" ]; then
    rm -rf "$FORGE_DIR/wrapper" && mkdir -p "$FORGE_DIR/wrapper"
    cp -r "$WR/gradlew" "$WR/gradle" "$FORGE_DIR/wrapper/"
  fi
  cd "$HOME"

  if [ ! -f "$FORGE_DIR/release.keystore" ]; then
    log "🔐 Generating Release Keystore for signed APKs..."
    keytool -genkey -v -keystore "$FORGE_DIR/release.keystore" -alias forgekey -keyalg RSA -keysize 2048 -validity 10000 -storepass forgerelease -keypass forgerelease -dname "CN=Forge, OU=Dev, O=Forge, L=City, ST=State, C=IN" >/dev/null 2>&1 || true
  fi

  ok "✅ Android SDK ready (Patched)"
  sleep 1
}

step_test_apk() {
  clear
  log "▰▰▰▰▰▰▰▱  [7/9] 🎯 Creating base template..."
  [[ "$SKIP_ANDROID" == "1" || "$SKIP_TEST_APK" == "1" ]] && { warn "⏭️  Test APK skipped"; return; }

  if [[ ! -f "$TEST_APP/settings.gradle" ]]; then
    mkdir -p "$TEST_APP/app/src/main/java/com/forge/hello"
    cat > "$TEST_APP/settings.gradle" <<'EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "hello-forge"
include ":app"
EOF
    cat > "$TEST_APP/build.gradle" <<EOF
plugins {
    id 'com.android.application' version '$AGP_VER' apply false
    id 'org.jetbrains.kotlin.android' version '$KOTLIN_VER' apply false
}
EOF
    cat > "$TEST_APP/app/build.gradle" <<'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}
android {
    namespace 'com.forge.hello'
    compileSdk 35
    defaultConfig {
        applicationId "com.forge.hello"
        minSdk 24
        targetSdk 35
        versionCode 1
        versionName "1.0"
    }
    signingConfigs {
        release {
            storeFile file(System.getenv("HOME") + "/.forge/release.keystore")
            storePassword "forgerelease"
            keyAlias "forgekey"
            keyPassword "forgerelease"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = '17' }
}
EOF
    cat > "$TEST_APP/app/src/main/AndroidManifest.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="Hello Forge" android:theme="@android:style/Theme.Material.Light">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
    cat > "$TEST_APP/app/src/main/java/com/forge/hello/MainActivity.kt" <<'EOF'
package com.forge.hello
import android.app.Activity
import android.os.Bundle
import android.widget.TextView
class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(TextView(this).apply {
            text = "Hello Forge! ⚒️🔥"
            textSize = 24f
        })
    }
}
EOF
  fi

  local lp="$TEST_APP/local.properties"
  if [[ ! -f "$lp" ]] || ! grep -q "sdk.dir=" "$lp" 2>/dev/null; then
    echo "sdk.dir=$ANDROID_SDK" > "$lp"
  fi

  if [ -f "$FORGE_DIR/wrapper/gradlew" ]; then
    cp -r "$FORGE_DIR/wrapper/gradlew" "$FORGE_DIR/wrapper/gradle" "$TEST_APP/"
  fi
  ok "✅ Base template ready"
  sleep 1
}

step_finalize() {
  clear
  log "▰▰▰▰▰▰▰▰  [8/9] 🏁 Finalizing CLI..."
  mkdir -p "$FORGE_DIR" "$HOME/.local/share/termux-forge"

  # Copy self to local share if running via curl/git
  local self_path
  self_path="$(readlink -f "$0" 2>/dev/null || echo "$0")"
  if [[ -f "$self_path" && "$self_path" != "$PREFIX/share/termux-forge/forge.sh" ]]; then
    cp -f "$self_path" "$HOME/.local/share/termux-forge/forge.sh"
    chmod 755 "$HOME/.local/share/termux-forge/forge.sh"
  fi

  # Create wrapper only if not already installed via .deb
  if ! dpkg -s termux-forge >/dev/null 2>&1; then
    cat > "${PREFIX}/bin/forge" <<'CLI'
#!/data/data/com.termux/files/usr/bin/bash
exec bash "$HOME/.local/share/termux-forge/forge.sh" --cli "$@"
CLI
    chmod +x "${PREFIX}/bin/forge"
  fi
  ok "✅ forge CLI v${FORGE_VERSION} installed"
}

doctor() {
  log "🩺 Health check (v${FORGE_VERSION})..."
  local fails=0
  check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else warn "$1"; fails=$((fails+1)); fi; }

  check "✓ Termux"                '[[ -n "${TERMUX_VERSION:-}" ]]'
  check "✓ Storage"               '[[ -d "$HOME/storage" ]]'
  check "✓ zsh"                   'command -v zsh'
  check "✓ git"                   'command -v git'
  check "✓ curl"                  'command -v curl'
  check "✓ java"                  'command -v java'
  check "✓ gradle"                'command -v gradle'
  check "✓ aapt2"                 'command -v aapt2'
  check "✓ OpenCode"              'command -v opencode'
  check "✓ Android SDK"           '[[ -d "$ANDROID_SDK" ]]'
  check "✓ platforms/android-35"  '[[ -d "$ANDROID_SDK/platforms/android-35" ]]'
  check "✓ build-tools/35.0.0"    '[[ -d "$ANDROID_SDK/build-tools/35.0.0" ]]'
  check "✓ Keystore"              '[[ -f "$HOME/.forge/release.keystore" ]]'
  check "✓ Base Template"         '[[ -f "$HOME/hello-forge/settings.gradle" ]]'

  [[ "$fails" -eq 0 ]] && ok "🎯 Sab theek hai! 🚀" || warn "⚠ $fails check(s) fail — 'forge setup' chalayein."
  return "$fails"
}

run_cli() {
  export ANDROID_HOME="$HOME/android-sdk"
  export JAVA_HOME="${PREFIX:-/data/data/com.termux/files/usr}/lib/jvm/java-17-openjdk"

  case "${1:-help}" in
    setup)
      shift
      run_full_setup "$@"
      ;;

    create)
      local proj_name="${2:-myapp}"
      local target="$HOME/$proj_name"
      if [ ! -d "$HOME/hello-forge" ]; then echo "✗ Pehle 'forge setup' chalayein!"; exit 1; fi
      if [ -d "$target" ]; then echo "✗ Folder '$proj_name' pehle se hai!"; exit 1; fi
      echo "🏗️  Creating new project: $proj_name"
      cp -r "$HOME/hello-forge" "$target"
      rm -rf "$target/app/build" "$target/build" "$target/.gradle"
      echo -n "➜ App ka Display Name (e.g. My Notes): "
      read -r custom_name
      custom_name="${custom_name:-$proj_name}"
      echo -n "➜ Package Name (e.g. com.yogesh.notes): "
      read -r custom_pkg
      custom_pkg="${custom_pkg:-com.forge.$(echo "$proj_name" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')}"
      local safe_dir=$(echo "$custom_pkg" | tr '.' '/')
      sed -i "s/com\.forge\.hello/$custom_pkg/g" "$target/app/build.gradle"
      sed -i "s/com\.forge\.hello/$custom_pkg/g" "$target/app/src/main/AndroidManifest.xml"
      sed -i "s/android:label=\"Hello Forge\"/android:label=\"$custom_name\"/g" "$target/app/src/main/AndroidManifest.xml"
      sed -i "s/package com\.forge\.hello/package $custom_pkg/g" "$target/app/src/main/java/com/forge/hello/MainActivity.kt"
      mkdir -p "$target/app/src/main/java/$safe_dir"
      mv "$target/app/src/main/java/com/forge/hello/MainActivity.kt" "$target/app/src/main/java/$safe_dir/MainActivity.kt"
      rm -rf "$target/app/src/main/java/com/forge/hello"
      echo "✅ Project created successfully!"
      echo "➜ App Name: $custom_name"
      echo "➜ Package: $custom_pkg"
      echo "➜ Ab chalao: cd ~/$proj_name && opencode"
      ;;

    import)
      local src_path="${2:-}"
      if [ -z "$src_path" ] || [ ! -d "$src_path" ]; then
        echo "❌ Usage: forge import <path_to_project_in_storage>"
        exit 1
      fi
      local proj_name=$(basename "$src_path")
      local target="$HOME/$proj_name"
      if [ -d "$target" ]; then echo "✗ Project '$proj_name' pehle se Termux ke home me hai!"; exit 1; fi
      echo "📥 Importing project from $src_path to ~/$proj_name..."
      cp -r "$src_path" "$target"
      echo "sdk.dir=$ANDROID_HOME" > "$target/local.properties"
      rm -rf "$target/app/build" "$target/build" "$target/.gradle"
      if [ ! -f "$target/gradlew" ] && [ -f "$HOME/.forge/wrapper/gradlew" ]; then
        cp -r "$HOME/.forge/wrapper/gradlew" "$HOME/.forge/wrapper/gradle" "$target/"
        chmod +x "$target/gradlew"
      fi
      echo "✅ Import successful! Ab chalao: cd ~/$proj_name"
      ;;

    package)
      local proj_dir="${2:-$HOME/hello-forge}"
      local new_pkg="${3:-}"
      if [ ! -d "$proj_dir" ]; then echo "✗ Project folder nahi mila: $proj_dir"; exit 1; fi
      cd "$proj_dir"
      local gradle_file="app/build.gradle"
      if [ ! -f "$gradle_file" ]; then echo "✗ app/build.gradle nahi mila."; exit 1; fi
      local old_pkg=$(grep 'namespace' "$gradle_file" | awk -F"'" '{print $2}' | head -n 1)
      if [ -z "$new_pkg" ]; then
        echo "➜ Purana Package: $old_pkg"
        echo -n "➜ Naya Package Name likho: "
        read -r new_pkg
      fi
      if [[ ! "$new_pkg" =~ ^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$ ]]; then
        echo "✗ Invalid package name format!"; exit 1
      fi
      echo "🔄 Changing package: $old_pkg ➜ $new_pkg"
      sed -i "s/namespace '$old_pkg'/namespace '$new_pkg'/g" "$gradle_file"
      sed -i "s/applicationId \"$old_pkg\"/applicationId \"$new_pkg\"/g" "$gradle_file"
      sed -i "s/applicationId '$old_pkg'/applicationId '$new_pkg'/g" "$gradle_file"
      [ -f "app/src/main/AndroidManifest.xml" ] && sed -i "s/$old_pkg/$new_pkg/g" "app/src/main/AndroidManifest.xml"
      find app/src/main -type f \( -name "*.kt" -o -name "*.java" \) -exec sed -i "s/$old_pkg/$new_pkg/g" {} + 2>/dev/null || true
      local old_dir=$(echo "$old_pkg" | tr '.' '/')
      local new_dir=$(echo "$new_pkg" | tr '.' '/')
      if [ -d "app/src/main/java/$old_dir" ]; then
        mkdir -p "app/src/main/java/$new_dir"
        find "app/src/main/java/$old_dir" -type f -exec mv {} "app/src/main/java/$new_dir/" \; 2>/dev/null || true
        rm -rf "app/src/main/java/$old_dir"
      fi
      echo "✅ Package name updated to: $new_pkg"
      ;;

    icon)
      local proj_dir="${2:-$HOME/hello-forge}"
      local icon_path="${3:-}"
      if [ -z "$icon_path" ] || [ ! -f "$icon_path" ]; then
        echo "❌ Usage: forge icon <project_folder> <path_to_image>"; exit 1
      fi
      if ! command -v convert >/dev/null 2>&1; then
        echo "📦 Installing ImageMagick (needed for icons)..."
        pkg install -y --no-install-recommends imagemagick >/dev/null 2>&1 || true
      fi
      echo "🎨 Generating App Icons from $icon_path..."
      local res_dir="$proj_dir/app/src/main/res"
      mkdir -p "$res_dir/mipmap-mdpi" "$res_dir/mipmap-hdpi" "$res_dir/mipmap-xhdpi" "$res_dir/mipmap-xxhdpi" "$res_dir/mipmap-xxxhdpi"
      convert "$icon_path" -resize 48x48 "$res_dir/mipmap-mdpi/ic_launcher.png" 2>/dev/null || true
      convert "$icon_path" -resize 72x72 "$res_dir/mipmap-hdpi/ic_launcher.png" 2>/dev/null || true
      convert "$icon_path" -resize 96x96 "$res_dir/mipmap-xhdpi/ic_launcher.png" 2>/dev/null || true
      convert "$icon_path" -resize 144x144 "$res_dir/mipmap-xxhdpi/ic_launcher.png" 2>/dev/null || true
      convert "$icon_path" -resize 192x192 "$res_dir/mipmap-xxxhdpi/ic_launcher.png" 2>/dev/null || true
      echo "✅ App icons updated successfully!"
      ;;

    export)
      local proj_dir="${2:-$HOME/hello-forge}"
      local build_type="${3:-all}"
      local dest_dir="$HOME/storage/downloads/ForgeApps"
      local proj_name=$(basename "$proj_dir")
      mkdir -p "$dest_dir"
      local found=0
      if [[ "$build_type" == "debug" || "$build_type" == "all" ]]; then
        local apk="$proj_dir/app/build/outputs/apk/debug/app-debug.apk"
        if [ -f "$apk" ]; then cp "$apk" "$dest_dir/${proj_name}-debug.apk"; echo "✅ Debug APK copied."; found=1; fi
      fi
      if [[ "$build_type" == "release" || "$build_type" == "all" ]]; then
        local apk_rel="$proj_dir/app/build/outputs/apk/release/app-release.apk"
        if [ -f "$apk_rel" ]; then cp "$apk_rel" "$dest_dir/${proj_name}-release.apk"; echo "✅ Release APK copied."; termux-open "$dest_dir/${proj_name}-release.apk" & found=1; fi
      fi
      if [[ "$build_type" == "aab" || "$build_type" == "all" ]]; then
        local aab="$proj_dir/app/build/outputs/bundle/release/app-release.aab"
        if [ -f "$aab" ]; then cp "$aab" "$dest_dir/${proj_name}-release.aab"; echo "✅ AAB Bundle copied."; found=1; fi
      fi
      if [ "$found" -eq 0 ]; then echo "✗ Koi file nahi mili."; else echo "🎉 Files saved in: Download/ForgeApps/"; fi
      ;;

    repair)
      local proj_dir="${2:-$HOME/hello-forge}"
      echo "🔧 Repairing project: $proj_dir"
      echo "sdk.dir=$ANDROID_HOME" > "$proj_dir/local.properties"
      if [ -f "$HOME/.forge/wrapper/gradlew" ]; then
        cp -r "$HOME/.forge/wrapper/gradlew" "$HOME/.forge/wrapper/gradle" "$proj_dir/"
        chmod +x "$proj_dir/gradlew"
      fi
      echo "✅ Project repaired!"
      ;;

    build)
      local build_type="debug"
      local proj_dir=""
      if [ "${2:-}" == "release" ] || [ "${2:-}" == "debug" ]; then
        build_type="$2"; proj_dir="${3:-$HOME/hello-forge}"
      else
        proj_dir="${2:-$HOME/hello-forge}"
      fi
      cd "$proj_dir"
      echo "🔨 Building $build_type APK for $(basename "$proj_dir")..."
      if [ -f "./gradlew" ]; then exec ./gradlew "assemble$(echo ${build_type^})" --no-daemon
      else exec gradle "assemble$(echo ${build_type^})" --no-daemon; fi
      ;;

    bundle)
      local proj_dir="${2:-$HOME/hello-forge}"
      cd "$proj_dir"
      echo "📦 Building Release Bundle (AAB) for $(basename "$proj_dir")..."
      if [ -f "./gradlew" ]; then exec ./gradlew bundleRelease --no-daemon
      else exec gradle bundleRelease --no-daemon; fi
      ;;

    sdk) exec sdkmanager --sdk_root="$ANDROID_HOME" "${@:2}" ;;
    ai) exec opencode ;;
    doctor) doctor ;;
    version|-v|--version) echo "termux-forge v${FORGE_VERSION}" ;;

    *) cat <<EOF
╔════════════════════════════════════════════╗
║  ⚒️  FORGE CLI v${FORGE_VERSION}                      ║
╠════════════════════════════════════════════╣
║  ➜ forge setup            Run full setup   ║
║  ➜ forge create <name>    New project      ║
║  ➜ forge import <path>    Import project   ║
║  ➜ forge build [release]  Build APK        ║
║  ➜ forge bundle [dir]     Build AAB        ║
║  ➜ forge icon <proj> <img>Set App Icon     ║
║  ➜ forge package <proj>   Set Package Name ║
║  ➜ forge export [dir]     Copy to Storage  ║
║  ➜ forge repair [dir]     Fix build errors ║
║  ➜ forge ai               OpenCode         ║
║  ➜ forge doctor           Health check     ║
╚════════════════════════════════════════════╝
EOF
    ;;
  esac
}

run_full_setup() {
  mkdir -p "$FORGE_DIR"
  export TMPDIR="${TMPDIR:-${PREFIX}/tmp}"
  mkdir -p "$TMPDIR"

  banner
  ask_name

  step_speedtest
  step_storage
  step_update
  step_packages
  step_shell
  step_opencode
  step_android_sdk
  step_test_apk
  step_finalize

  clear
  printf '\n%s╔══════════════════════════════════════════════════════════╗%s\n' "$G$B" "$R"
  printf '%s║%s  ✅ SETUP COMPLETE!  ⚒️  🎯                            %s║%s\n' "$G$B" "$R" "$G$B" "$R"
  printf '%s╚══════════════════════════════════════════════════════════╝%s\n\n' "$G$B" "$R"

  cat <<EOF
${CY}➜ Termux ko ek baar restart karo (Zsh load karne ke liye):${R}
  ${G}▸${R} exit

  Ya phir ${Y}exec zsh${R} chalao.

${CY}➜ Try these commands:${R}
  ${G}▸${R} forge create my-app    ${Y}Create New Project${R}
  ${G}▸${R} forge build release    ${Y}Build Release APK${R}
  ${G}▸${R} forge bundle ~/my-app  ${Y}Build Play Store AAB${R}

${MG}👤 github.com/inyogeshwar${R}
EOF
}

main() {
  if [[ "${1:-}" == "--cli" ]]; then
    shift
    run_cli "$@"
  elif [[ "${1:-}" == "--doctor" ]]; then
    doctor
  else
    run_full_setup "$@"
  fi
}

main "$@"