#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  ⚒️  TERMUX-FORGE — Setup & CLI  v7.0.0                  ║
# ║  Termux → OpenCode → Android APK / AAB                   ║
# ║  https://github.com/inyogeshwar/termux-forge             ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

readonly FORGE_VERSION="7.0.1"
readonly REPO_SLUG="inyogeshwar/termux-forge"
readonly GRADLE_VER="8.9"
readonly AGP_VER="8.7.3"
readonly KOTLIN_VER="2.0.21"
readonly SDK_PLATFORM="android-35"
readonly BUILD_TOOLS_VER="35.0.0"
readonly CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
readonly OPENCODE_FALLBACK_VER="1.19.5"
readonly PKG_RE='^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$'

: "${PREFIX:=/data/data/com.termux/files/usr}"
FORGE_DIR="${FORGE_DIR:-$HOME/.forge}"
ANDROID_SDK="${ANDROID_SDK:-$HOME/android-sdk}"
TEST_APP="$HOME/hello-forge"
SHARE_DIR="$HOME/.local/share/termux-forge"
export TMPDIR="${TMPDIR:-$PREFIX/tmp}"

FORGE_NAME="${FORGE_NAME:-}"
FORGE_YES="${FORGE_YES:-0}"
SKIP_ANDROID="${SKIP_ANDROID:-0}"
SKIP_TEST_APK="${SKIP_TEST_APK:-0}"
SKIP_SHELL="${SKIP_SHELL:-0}"
SKIP_OPENCODE="${SKIP_OPENCODE:-0}"
FORGE_SPEEDTEST="${FORGE_SPEEDTEST:-0}"
FORGE_GRADLE_MEM="${FORGE_GRADLE_MEM:-2048m}"

# ──────────────────────────── UI helpers ────────────────────────────
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

ui_clear() { if [[ -t 1 ]]; then clear; fi; }
pause()    { if [[ -t 1 ]]; then sleep 1; fi; }

bar() {
  local n=$1 i out=""
  for ((i = 0; i < 8; i++)); do
    if ((i < n)); then out+="▰"; else out+="▱"; fi
  done
  printf '%s' "$out"
}
step_header() { ui_clear; log "$(bar "$1")  [$1/8] $2"; }

confirm() {
  [[ "$FORGE_YES" == "1" ]] && return 0
  local ans
  printf '%s [y/N]: ' "$1"
  read -r ans 2>/dev/null </dev/tty || ans="n"
  [[ "$ans" =~ ^[Yy]$ ]]
}

# Leave one column free so terminals do not wrap at the right edge.
ui_width() {
  local cols="${COLUMNS:-}"
  if [[ ! "$cols" =~ ^[0-9]+$ ]] || (( cols < 2 )); then
    cols=$(tput cols 2>/dev/null) || cols=40
  fi
  [[ "$cols" =~ ^[0-9]+$ ]] && (( cols > 1 )) || cols=40
  printf '%s\n' "$((cols - 1))"
}

ui_text() { printf '%s\n' "$*" | fold -s -w "$(ui_width)"; }

ui_rule() {
  local width line
  width=$(ui_width)
  (( width > 38 )) && width=38
  printf -v line '%*s' "$width" ''
  printf '%s%s%s\n' "$CY" "${line// /─}" "$R"
}

banner() {
  ui_clear
  ui_rule
  printf '%s%s' "$MG" "$B"
  ui_text 'TERMUX FORGE'
  printf '%s' "$R"
  ui_text "v${FORGE_VERSION} / Android + AI"
  ui_rule
}

# ──────────────────────────── generic helpers ────────────────────────────
# set_prop <file> <key> <value>  — idempotent key=value writer
set_prop() {
  local f=$1 k=$2 v=$3
  mkdir -p "$(dirname "$f")"
  touch "$f"
  sed -i "/^${k//./\\.}=/d" "$f"
  printf '%s=%s\n' "$k" "$v" >> "$f"
}

has_storage() { [[ -d "$HOME/storage" ]]; }

is_project() { [[ -f "$1/settings.gradle" || -f "$1/settings.gradle.kts" ]]; }

# resolve_proj [path-or-name]  — arg → $PWD (if project) → ~/hello-forge
resolve_proj() {
  local arg="${1:-}"
  if [[ -n "$arg" ]]; then
    if [[ -d "$arg" ]]; then readlink -f "$arg"; return 0; fi
    if [[ -d "$HOME/$arg" ]]; then readlink -f "$HOME/$arg"; return 0; fi
    die "Project nahi mila: $arg"
  fi
  if is_project "$PWD"; then printf '%s\n' "$PWD"; return 0; fi
  if is_project "$TEST_APP"; then printf '%s\n' "$TEST_APP"; return 0; fi
  die "Koi project nahi mila. Project folder me jao ya path/naam do."
}

get_version_name() {
  grep -Eo 'versionName[[:space:]]*=?[[:space:]]*"[^"]+"' "$1/app/build.gradle" 2>/dev/null \
    | head -1 | sed -E 's/.*"([^"]+)"/\1/' || true
}

get_namespace() {
  sed -nE "s/.*namespace[[:space:]]*=?[[:space:]]*['\"]([^'\"]+)['\"].*/\1/p" "$1/app/build.gradle" 2>/dev/null \
    | head -1 || true
}

pkg_install() {
  local pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  local missing=() p
  for p in "${pkgs[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  log "📦 Installing: ${missing[*]}"
  mkdir -p "$FORGE_DIR"
  local log_file="$FORGE_DIR/pkg_install.log" attempt
  for attempt in 1 2 3; do
    if pkg install -y --no-install-recommends "${missing[@]}" 2>&1 | tee "$log_file"; then
      ok "Packages installed."
      return 0
    fi
    if [[ $attempt -lt 3 ]]; then
      warn "Install fail (attempt $attempt/3). 3s me retry..."
      sleep 3
    fi
  done
  warn "pkg install failed."
  tail -n 15 "$log_file" >&2
  die "Internet check karo ya 'termux-change-repo' chalao."
}

# ──────────────────────────── keystore ────────────────────────────
ks_file()  { printf '%s\n' "$FORGE_DIR/release.keystore"; }
ks_props() { printf '%s\n' "$FORGE_DIR/keystore.properties"; }

random_pass() {
  local p
  p=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 || true)
  printf '%s' "${p:-forgeRelease$RANDOM$RANDOM}"
}

# Writes keystore passwords where Gradle can read them (~/.gradle/gradle.properties)
publish_keystore_props() {
  local props sp kp
  props="$(ks_props)"
  [[ -f "$props" ]] || return 0
  sp=$(sed -n 's/^FORGE_STORE_PASS=//p' "$props" | head -1)
  kp=$(sed -n 's/^FORGE_KEY_PASS=//p' "$props" | head -1)
  set_prop "$HOME/.gradle/gradle.properties" FORGE_STORE_PASS "$sp"
  set_prop "$HOME/.gradle/gradle.properties" FORGE_KEY_PASS "${kp:-$sp}"
}

ensure_keystore() {
  mkdir -p "$FORGE_DIR"
  local ks props pass
  ks="$(ks_file)"; props="$(ks_props)"

  if [[ -f "$ks" ]]; then
    # Purani install (v6.x) ka keystore: password 'forgerelease' tha
    if [[ ! -f "$props" ]]; then
      printf 'FORGE_STORE_PASS=forgerelease\nFORGE_KEY_PASS=forgerelease\n' > "$props"
      chmod 600 "$props"
    fi
    publish_keystore_props
    return 0
  fi

  have keytool || { warn "keytool nahi mila (openjdk-17 install hai?)"; return 1; }
  log "🔐 Naya release keystore ban raha hai (random password)..."
  pass="$(random_pass)"
  keytool -genkeypair -keystore "$ks" -alias forgekey -keyalg RSA -keysize 2048 \
    -validity 10000 -storepass "$pass" -keypass "$pass" \
    -dname "CN=Forge, OU=Dev, O=Forge, L=City, ST=State, C=IN" >/dev/null 2>&1 \
    || { warn "Keystore generate fail"; return 1; }
  printf 'FORGE_STORE_PASS=%s\nFORGE_KEY_PASS=%s\n' "$pass" "$pass" > "$props"
  chmod 600 "$props" "$ks" 2>/dev/null || true
  publish_keystore_props
  ok "Keystore ready → $ks"
  warn "⚠️  Is keystore ka BACKUP lo: 'forge keystore backup' (kho gaya to Play Store app update nahi hoga)"
}

# ──────────────────────────── setup steps ────────────────────────────
ask_name() {
  local name
  if [[ -n "$FORGE_NAME" ]]; then
    name="$FORGE_NAME"
  elif [[ "$FORGE_YES" == "1" ]]; then
    name="Forge"
  else
    printf '\n'
    ui_text 'Banner aur prompt ka naam:'
    printf '> '
    read -r name 2>/dev/null </dev/tty || name="Forge"
  fi
  name="${name//[^A-Za-z0-9_-]/}"
  name="${name:0:20}"
  name="${name:-Forge}"
  mkdir -p "$FORGE_DIR"
  printf '%s\n' "$name" > "$FORGE_DIR/.name"
  ok "🎨 Banner set: $name"
}

step_speedtest() {
  [[ "$FORGE_SPEEDTEST" == "1" ]] || return 0
  ui_clear
  log "🚀 Internet speed test (optional)..."
  if ! have speedtest-cli; then
    pkg_install python || true
    pip install speedtest-cli --quiet 2>/dev/null || true
  fi
  if have speedtest-cli; then
    speedtest-cli --simple || warn "Speedtest fail — setup continue hoga."
  fi
}

step_storage() {
  step_header 1 "🔐 Storage access..."
  if has_storage; then ok "Storage mil gaya"; return 0; fi
  termux-setup-storage >/dev/null 2>&1 || true
  local i
  for i in {1..15}; do
    if has_storage; then break; fi
    sleep 1
  done
  if has_storage; then ok "Storage mil gaya"; else warn "Storage permission nahi mila (export ke liye zaroori)"; fi
  pause
}

step_update() {
  step_header 2 "🔄 System update..."
  mkdir -p "$FORGE_DIR"
  pkg update -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  pkg upgrade -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  ok "System upgrade done"
  pause
}

step_packages() {
  step_header 3 "📦 Base packages..."
  pkg_install git curl unzip zsh toilet nodejs openjdk-17 gradle aapt aapt2 apksigner glibc-repo
  pkg update -y >/dev/null 2>&1 || true
  pkg_install glibc-runner
  ok "Packages ready"
  pause
}

write_zshrc_block() {
  local block
  block=$(cat <<'ZSHRC'
# ── FORGE_ZSHRC ──────────────────────────────────────────
# Native Zsh prompt: fits phone screens without a patched Nerd Font.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
DISABLE_AUTO_TITLE=true
plugins=(git zsh-autosuggestions)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

_forge_prompt() {
  local last_status=$? name width dir_width color=green
  (( last_status )) && color=red
  name=$(cat "$HOME/.forge/.name" 2>/dev/null) || name=Forge
  name="${name//[^A-Za-z0-9_-]/}"
  name="${name:-Forge}"
  width=$(( ${COLUMNS:-40} - 1 ))
  (( width < 12 )) && width=12
  name="${name[1,$((width / 3))]}"
  dir_width=$((width - ${#name} - 3))
  # Zsh truncates the displayed path as the terminal is resized.
  PROMPT="%F{cyan}${name}%f %F{blue}%${dir_width}<..<%~%<<%f"$'\n'"%F{${color}}>%f "
  RPROMPT=''
}
autoload -Uz add-zsh-hook
add-zsh-hook -d precmd _forge_prompt 2>/dev/null
add-zsh-hook precmd _forge_prompt

export ANDROID_SDK_ROOT="$HOME/android-sdk"
export ANDROID_HOME="$HOME/android-sdk"
export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
export PATH="$PATH:$HOME/.opencode/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/__BT__"

# forge <TAB> completion
_forge() {
  local -a cmds
  cmds=(setup create import list build bundle install export icon package rename bump keystore clean repair backup update doctor info ai sdk help version)
  _describe 'forge command' cmds
}
(( $+functions[compdef] )) && compdef _forge forge

_forge_banner() {
  local name width line
  name=$(cat "$HOME/.forge/.name" 2>/dev/null) || name=Forge
  name="${name//[^A-Za-z0-9_-]/}"
  name="${name:-Forge}"
  width=$(( ${COLUMNS:-40} - 1 ))
  (( width > 36 )) && width=36
  (( width < 12 )) && width=12
  printf -v line '%*s' "$width" ''
  line="${line// /─}"
  print -P -- "%F{cyan}${line}%f"
  print -P -- '%B%F{cyan}TERMUX FORGE%f%b'
  print -r -- "Hi, ${name[1,$((width - 4))]}"
  print -P -- "%F{cyan}${line}%f"
  print -r -- 'forge help'
  print
}
[[ -o interactive ]] && _forge_banner
# ── END FORGE_ZSHRC ──────────────────────────────────────
ZSHRC
)
  block="${block//__BT__/$BUILD_TOOLS_VER}"
  # purana block hata ke naya likho (taaki update ke baad bhi latest config mile)
  if [[ -f "$HOME/.zshrc" ]]; then
    sed -i '/# ── FORGE_ZSHRC/,/# ── END FORGE_ZSHRC/d' "$HOME/.zshrc"
  fi
  printf '\n%s\n' "$block" >> "$HOME/.zshrc"
}

step_shell() {
  step_header 4 "Mobile Zsh prompt..."
  if [[ "$SKIP_SHELL" == "1" ]]; then warn "Shell setup skipped"; return 0; fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 \
      || warn "Oh My Zsh install fail"
  fi

  local zc="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [[ -d "$zc/plugins/zsh-autosuggestions" ]] \
    || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$zc/plugins/zsh-autosuggestions" >/dev/null 2>&1 \
    || warn "zsh-autosuggestions clone fail"

  : > "$PREFIX/etc/motd"
  if [[ -f "$HOME/.bashrc" ]]; then
    grep -vE "PS1=|Welcome to Termux|termux-welcome" "$HOME/.bashrc" > "$HOME/.bashrc.tmp" || true
    mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
  fi

  write_zshrc_block

  if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
    chsh -s zsh 2>/dev/null || warn "chsh fail (manually: chsh -s zsh)"
  fi
  ok "Mobile Zsh prompt ready"
  pause
}

step_opencode() {
  step_header 5 "🤖 OpenCode..."
  if [[ "$SKIP_OPENCODE" == "1" ]]; then warn "OpenCode skipped"; return 0; fi
  if have opencode; then ok "OpenCode already installed"; return 0; fi

  local oc_dir="$HOME/.opencode/bin" ver work
  ver=$(npm view opencode-linux-arm64 version 2>/dev/null) || ver="$OPENCODE_FALLBACK_VER"
  [[ -n "$ver" ]] || ver="$OPENCODE_FALLBACK_VER"
  work="$TMPDIR/oc"
  mkdir -p "$oc_dir" "$TMPDIR"
  rm -rf "$work"; mkdir -p "$work"

  if ( cd "$work" && npm pack --silent "opencode-linux-arm64@$ver" >/dev/null 2>&1 \
       && tar xzf "opencode-linux-arm64-$ver.tgz" ) && [[ -f "$work/package/bin/opencode" ]]; then
    mv -f "$work/package/bin/opencode" "$oc_dir/opencode-linux"
    chmod +x "$oc_dir/opencode-linux"
    cat > "$PREFIX/bin/opencode" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec grun "$HOME/.opencode/bin/opencode-linux" "$@"
EOF
    chmod +x "$PREFIX/bin/opencode"
    rm -rf "$work"
    ok "OpenCode v$ver installed"
  else
    warn "OpenCode install fail (arm64 device chahiye). Baad me 'forge setup' dobara chalao."
  fi
  pause
}

sdk_install_cmdline_tools() {
  local sdkmanager="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"
  [[ -x "$sdkmanager" ]] && return 0
  log "📥 Downloading cmdline-tools (~100 MB)..."
  local zip="$TMPDIR/cmdline-tools.zip"
  mkdir -p "$TMPDIR"
  curl -# -L --fail "$CMDLINE_TOOLS_URL" -o "$zip" || die "cmdline-tools download fail"
  rm -rf "$ANDROID_SDK/cmdline-tools"
  mkdir -p "$ANDROID_SDK/cmdline-tools"
  unzip -q "$zip" -d "$ANDROID_SDK/cmdline-tools"
  mv "$ANDROID_SDK/cmdline-tools/cmdline-tools" "$ANDROID_SDK/cmdline-tools/latest"
  rm -f "$zip"
}

sdk_patch_build_tools() {
  log "🔗 Build-tools ko Termux ARM binaries se patch kar raha hu..."
  local bt="$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER" t cmd_path
  for t in aapt aapt2 aidl zipalign apksigner; do
    if [[ -e "$bt/$t" ]] && have "$t"; then
      cmd_path="$(command -v "$t")"
      if [[ "$cmd_path" != "$bt/$t" ]]; then ln -sf "$cmd_path" "$bt/$t" 2>/dev/null || true; fi
    fi
  done
}

sdk_write_gradle_props() {
  local gp="$HOME/.gradle/gradle.properties"
  set_prop "$gp" android.aapt2FromMavenOverride "$PREFIX/bin/aapt2"
  set_prop "$gp" org.gradle.jvmargs "-Xmx${FORGE_GRADLE_MEM} -Dfile.encoding=UTF-8"
  set_prop "$gp" org.gradle.vfs.watch false
  set_prop "$gp" kotlin.daemon.jvmargs "-Xmx1024m"
}

sdk_make_wrapper_template() {
  log "⚙️  Gradle Wrapper ($GRADLE_VER) template ban raha hai..."
  local wr="$FORGE_DIR/wrapper-gen"
  rm -rf "$wr"; mkdir -p "$wr"
  ( cd "$wr" && touch settings.gradle \
    && gradle -q wrapper --gradle-version "$GRADLE_VER" --no-daemon >/dev/null 2>&1 ) || true
  if [[ -f "$wr/gradlew" ]]; then
    rm -rf "$FORGE_DIR/wrapper"; mkdir -p "$FORGE_DIR/wrapper"
    cp -r "$wr/gradlew" "$wr/gradle" "$FORGE_DIR/wrapper/"
  else
    warn "Gradle wrapper generate nahi hua (builds system 'gradle' use karenge)"
  fi
  rm -rf "$wr"
}

step_android_sdk() {
  step_header 6 "⚙️  Android SDK..."
  if [[ "$SKIP_ANDROID" == "1" ]]; then warn "Android SDK skipped"; return 0; fi

  export JAVA_HOME="${JAVA_HOME:-$PREFIX/lib/jvm/java-17-openjdk}"
  mkdir -p "$ANDROID_SDK" "$FORGE_DIR"
  sdk_install_cmdline_tools
  local sdkmanager="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"

  yes | "$sdkmanager" --sdk_root="$ANDROID_SDK" --licenses >/dev/null 2>&1 || true

  if [[ ! -d "$ANDROID_SDK/platforms/$SDK_PLATFORM" || ! -d "$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER" ]]; then
    log "📦 SDK components download (~200 MB)..."
    "$sdkmanager" --sdk_root="$ANDROID_SDK" "platform-tools" "platforms;$SDK_PLATFORM" "build-tools;$BUILD_TOOLS_VER" \
      2>&1 | tee "$FORGE_DIR/sdk_download.log" || die "sdkmanager install fail (log: $FORGE_DIR/sdk_download.log)"
  fi

  sdk_patch_build_tools
  sdk_write_gradle_props
  sdk_make_wrapper_template
  ensure_keystore || warn "Keystore nahi bana — release build ke liye 'forge keystore new' chalao."
  ok "Android SDK ready"
  pause
}

# Base template (~/hello-forge) — har naya project isi se copy hota hai
write_project_gitignore() {
  cat > "$1/.gitignore" <<'EOF'
*.iml
.gradle/
/local.properties
/build/
/app/build/
.idea/
.DS_Store
*.apk
*.aab
*.keystore
*.jks
EOF
}

make_base_template() {
  local t="$TEST_APP"
  if [[ ! -f "$t/settings.gradle" ]]; then
    mkdir -p "$t/app/src/main/java/com/forge/hello"
    cat > "$t/settings.gradle" <<'EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "hello-forge"
include ":app"
EOF
    cat > "$t/build.gradle" <<EOF
plugins {
    id 'com.android.application' version '$AGP_VER' apply false
    id 'org.jetbrains.kotlin.android' version '$KOTLIN_VER' apply false
}
EOF
    cat > "$t/app/build.gradle" <<'EOF'
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
        versionName "1.0.0"
    }
    signingConfigs {
        release {
            storeFile file(System.getenv("HOME") + "/.forge/release.keystore")
            storePassword((project.findProperty("FORGE_STORE_PASS") ?: "forgerelease").toString())
            keyAlias "forgekey"
            keyPassword((project.findProperty("FORGE_KEY_PASS") ?: "forgerelease").toString())
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
    : > "$t/app/proguard-rules.pro"
    cat > "$t/app/src/main/AndroidManifest.xml" <<'EOF'
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
    cat > "$t/app/src/main/java/com/forge/hello/MainActivity.kt" <<'EOF'
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
    write_project_gitignore "$t"
  fi

  echo "sdk.dir=$ANDROID_SDK" > "$t/local.properties"
  if [[ -f "$FORGE_DIR/wrapper/gradlew" ]]; then
    cp -r "$FORGE_DIR/wrapper/gradlew" "$FORGE_DIR/wrapper/gradle" "$t/"
    chmod +x "$t/gradlew"
  fi
}

step_test_apk() {
  step_header 7 "🎯 Base template..."
  if [[ "$SKIP_ANDROID" == "1" || "$SKIP_TEST_APK" == "1" ]]; then warn "Template skipped"; return 0; fi
  make_base_template
  ok "Base template ready → ~/hello-forge"
  pause
}

step_finalize() {
  step_header 8 "🏁 Finalizing CLI..."
  mkdir -p "$FORGE_DIR" "$SHARE_DIR"

  local self_path dest_path dest_real
  self_path="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
  dest_path="$SHARE_DIR/forge.sh"
  dest_real="$(readlink -f "$dest_path" 2>/dev/null || echo "$dest_path")"
  if [[ -f "$self_path" && "$self_path" != "$PREFIX/share/termux-forge/forge.sh" && "$self_path" != "$dest_real" ]]; then
    cp -f "$self_path" "$dest_path"
    chmod 755 "$dest_path"
  fi

  # .deb se install hai to wrapper pehle se hai
  if ! dpkg -s termux-forge >/dev/null 2>&1; then
    cat > "$PREFIX/bin/forge" <<'CLI'
#!/data/data/com.termux/files/usr/bin/bash
exec bash "$HOME/.local/share/termux-forge/forge.sh" --cli "$@"
CLI
    chmod +x "$PREFIX/bin/forge"
  fi
  ok "forge CLI v${FORGE_VERSION} installed"
}

# ──────────────────────────── doctor / info ────────────────────────────
doctor() {
  log "🩺 Health check (v${FORGE_VERSION})..."
  local fails=0
  check() {
    if eval "$2" >/dev/null 2>&1; then ok "$1"; else warn "$1"; fails=$((fails + 1)); fi
  }

  check "Termux"                    '[[ -n "${TERMUX_VERSION:-}" || "$PREFIX" == *com.termux* ]]'
  check "Storage"                   '[[ -d "$HOME/storage" ]]'
  check "zsh"                       'command -v zsh'
  check "git"                       'command -v git'
  check "curl"                      'command -v curl'
  check "java"                      'command -v java'
  check "gradle"                    'command -v gradle'
  check "aapt2"                     'command -v aapt2'
  check "OpenCode"                  'command -v opencode'
  check "Android SDK"               '[[ -d "$ANDROID_SDK" ]]'
  check "platforms/$SDK_PLATFORM"   '[[ -d "$ANDROID_SDK/platforms/$SDK_PLATFORM" ]]'
  check "build-tools/$BUILD_TOOLS_VER" '[[ -d "$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER" ]]'
  check "Gradle wrapper template"   '[[ -f "$FORGE_DIR/wrapper/gradlew" ]]'
  check "Keystore"                  '[[ -f "$FORGE_DIR/release.keystore" ]]'
  check "Keystore password config"  '[[ -f "$FORGE_DIR/keystore.properties" ]]'
  check "Base Template"             '[[ -f "$TEST_APP/settings.gradle" ]]'

  if [[ "$fails" -eq 0 ]]; then
    ok "🎯 Sab theek hai! 🚀"
  else
    warn "$fails check(s) fail — 'forge setup' chalao."
  fi
  return "$fails"
}

cmd_info() {
  printf '%s⚒️  termux-forge v%s%s\n' "$B" "$FORGE_VERSION" "$R"
  printf '  %-14s %s\n' "Java"     "$(java -version 2>&1 | head -1 || echo 'not found')"
  printf '  %-14s %s\n' "Gradle"   "$(gradle --version 2>/dev/null | sed -n 's/^Gradle //p' | head -1 || true)"
  printf '  %-14s %s\n' "SDK path" "$ANDROID_SDK"
  printf '  %-14s %s / %s\n' "Platform" "$SDK_PLATFORM" "$BUILD_TOOLS_VER"
  printf '  %-14s AGP %s, Kotlin %s, Gradle %s\n' "Template" "$AGP_VER" "$KOTLIN_VER" "$GRADLE_VER"
  printf '  %-14s %s\n' "Keystore" "$( [[ -f "$(ks_file)" ]] && echo "$(ks_file)" || echo 'nahi bana (forge keystore new)' )"
  printf '  %-14s %s\n' "Free space" "$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $4}')"
}

# ──────────────────────────── project helpers ────────────────────────────
ensure_project_ready() {
  local proj=$1
  if [[ ! -f "$proj/local.properties" ]] || ! grep -q '^sdk.dir=' "$proj/local.properties" 2>/dev/null; then
    echo "sdk.dir=$ANDROID_SDK" > "$proj/local.properties"
  fi
  if [[ ! -f "$proj/gradlew" && -f "$FORGE_DIR/wrapper/gradlew" ]]; then
    cp -r "$FORGE_DIR/wrapper/gradlew" "$FORGE_DIR/wrapper/gradle" "$proj/"
  fi
  if [[ -f "$proj/gradlew" ]]; then chmod +x "$proj/gradlew"; fi
}

run_gradle() {
  local proj=$1; shift
  ( cd "$proj" || exit 1
    if [[ -f ./gradlew ]]; then sh ./gradlew "$@" --no-daemon
    else gradle "$@" --no-daemon; fi )
}

apply_package_change() {
  local proj=$1 old=$2 new=$3
  [[ "$old" != "$new" ]] || return 0
  local old_re="${old//./\\.}" old_dir="${old//.//}" new_dir="${new//.//}" f root tmp

  for f in "$proj/app/build.gradle" "$proj/app/build.gradle.kts"; do
    if [[ -f "$f" ]]; then sed -i "s/$old_re/$new/g" "$f"; fi
  done
  if [[ -d "$proj/app/src" ]]; then
    find "$proj/app/src" -type f \( -name '*.kt' -o -name '*.java' -o -name '*.xml' \) \
      -exec sed -i "s/$old_re/$new/g" {} +
  fi

  for root in "$proj"/app/src/*/java "$proj"/app/src/*/kotlin; do
    [[ -d "$root/$old_dir" ]] || continue
    tmp="$(mktemp -d "${TMPDIR}/forgepkg.XXXXXX")"
    mv "$root/$old_dir"/* "$tmp"/ 2>/dev/null || true
    rm -rf "${root:?}/$old_dir"
    mkdir -p "$root/$new_dir"
    mv "$tmp"/* "$root/$new_dir"/ 2>/dev/null || true
    rmdir "$tmp" 2>/dev/null || true
    find "$root" -mindepth 1 -type d -empty -delete 2>/dev/null || true
  done
}

set_app_label() {
  local proj=$1 label=$2 manifest esc
  manifest="$proj/app/src/main/AndroidManifest.xml"
  [[ -f "$manifest" ]] || die "AndroidManifest.xml nahi mila"
  esc=$(printf '%s' "$label" \
    | sed -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' \
    | sed -e 's/[\\&|]/\\&/g')
  sed -i -E "s|android:label=\"[^\"]*\"|android:label=\"$esc\"|" "$manifest"
}

apply_webview_template() {
  local proj=$1 url=$2 kt manifest tpl before after
  kt="$proj/app/src/main/java/com/forge/hello/MainActivity.kt"
  manifest="$proj/app/src/main/AndroidManifest.xml"
  tpl='package com.forge.hello

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient

class MainActivity : Activity() {
    private lateinit var web: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        web = WebView(this)
        web.settings.javaScriptEnabled = true
        web.settings.domStorageEnabled = true
        web.webViewClient = WebViewClient()
        web.webChromeClient = WebChromeClient()
        setContentView(web)
        web.loadUrl("__URL__")
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (web.canGoBack()) web.goBack() else super.onBackPressed()
    }
}
'
  before="${tpl%%__URL__*}"
  after="${tpl#*__URL__}"
  printf '%s%s%s' "$before" "$url" "$after" > "$kt"
  if ! grep -q 'android.permission.INTERNET' "$manifest"; then
    sed -i '/<manifest /a\    <uses-permission android:name="android.permission.INTERNET" />' "$manifest"
  fi
}

# ──────────────────────────── commands ────────────────────────────
cmd_create() {
  local name="" template="kotlin" label="" pkg="" url="" git=0
  while (($#)); do
    case "$1" in
      -t|--template) (($# >= 2)) || die "$1 ke baad value do"; template="$2"; shift 2 ;;
      -n|--name)     (($# >= 2)) || die "$1 ke baad value do"; label="$2"; shift 2 ;;
      -p|--package)  (($# >= 2)) || die "$1 ke baad value do"; pkg="$2"; shift 2 ;;
      -u|--url)      (($# >= 2)) || die "$1 ke baad value do"; url="$2"; shift 2 ;;
      --git)         git=1; shift ;;
      -*)            die "Unknown option: $1" ;;
      *)             name="$1"; shift ;;
    esac
  done
  name="${name:-myapp}"
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || die "Project folder naam sirf A-Z a-z 0-9 . _ - ho sakta hai"
  case "$template" in kotlin|webview) ;; *) die "Unknown template '$template' (kotlin | webview)" ;; esac
  is_project "$TEST_APP" || die "Pehle 'forge setup' chalao (base template nahi mila)."
  local target="$HOME/$name"
  [[ ! -e "$target" ]] || die "Folder '$name' pehle se hai!"

  if [[ -z "$label" && -t 0 ]]; then
    printf '➜ App ka Display Name (e.g. My Notes) [%s]: ' "$name"; read -r label || true
  fi
  label="${label:-$name}"
  if [[ -z "$pkg" && -t 0 ]]; then
    printf '➜ Package Name (e.g. com.yogesh.notes): '; read -r pkg || true
  fi
  if [[ -z "$pkg" ]]; then
    local slug; slug="$(printf '%s' "$name" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')"
    [[ "$slug" =~ ^[a-z] ]] || slug="app$slug"
    pkg="com.forge.$slug"
  fi
  [[ "$pkg" =~ $PKG_RE ]] || die "Invalid package name: $pkg (example: com.yogesh.notes)"

  if [[ "$template" == "webview" ]]; then
    if [[ -z "$url" && -t 0 ]]; then printf '➜ Website URL (https://...): '; read -r url || true; fi
    [[ "$url" =~ ^https?://[^[:space:]\"\$\\]+$ ]] || die "Valid http(s) URL do (--url https://example.com)"
  fi

  log "🏗️  Creating '$name' ($template template)..."
  cp -r "$TEST_APP" "$target"
  rm -rf "$target/app/build" "$target/build" "$target/.gradle"
  echo "sdk.dir=$ANDROID_SDK" > "$target/local.properties"

  if [[ "$template" == "webview" ]]; then apply_webview_template "$target" "$url"; fi
  set_app_label "$target" "$label"
  apply_package_change "$target" "com.forge.hello" "$pkg"
  sed -i -E "s/(rootProject.name[[:space:]]*=[[:space:]]*\")[^\"]*(\")/\1${name//\//_}\2/" "$target/settings.gradle" 2>/dev/null || true
  if (( git )) && have git; then git -C "$target" init -q && ok "git repo init hua"; fi

  ok "Project ready!"
  # shellcheck disable=SC2088
  printf '  %-10s %s\n  %-10s %s\n  %-10s %s\n  %-10s %s\n' \
    "Folder:" "~/$name" "App:" "$label" "Package:" "$pkg" "Template:" "$template"
  log "Ab chalao: cd ~/$name && forge ai     (ya)     forge build"
}

cmd_import() {
  local src="${1:-}"
  [[ -n "$src" && -d "$src" ]] || die "Usage: forge import <project_folder>"
  src="$(readlink -f "$src")"
  local name target; name="$(basename "$src")"; target="$HOME/$name"
  [[ ! -e "$target" ]] || die "Project '$name' pehle se Termux home me hai!"
  log "📥 Importing $src → ~/$name ..."
  cp -r "$src" "$target"
  rm -rf "$target/app/build" "$target/build" "$target/.gradle"
  echo "sdk.dir=$ANDROID_SDK" > "$target/local.properties"
  ensure_project_ready "$target"
  ok "Import done! Ab chalao: cd ~/$name && forge build"
}

cmd_list() {
  local d found=0 ver
  for d in "$HOME"/*/; do
    d="${d%/}"
    is_project "$d" || continue
    found=1
    ver="$(get_version_name "$d")"
    printf '%s' "$CY"
    ui_text "$(basename "$d")"
    printf '%s' "$R"
    ui_text "  Version: ${ver:--}"
    ui_text "  Package: $(get_namespace "$d")"
    printf '\n'
  done
  [[ "$found" == 1 ]] || log "Koi project nahi mila. 'forge create my-app' chalao."
  return 0
}

cmd_build() {
  local type="debug" proj_arg="" do_install=0 a
  for a in "$@"; do
    case "$a" in
      release|debug) type="$a" ;;
      --install|-i)  do_install=1 ;;
      *)             proj_arg="$a" ;;
    esac
  done
  local proj; proj="$(resolve_proj "$proj_arg")"
  ensure_project_ready "$proj"

  if [[ "$type" == "release" ]]; then
    [[ -f "$(ks_file)" ]] || die "Release keystore nahi mila. 'forge keystore new' chalao."
    publish_keystore_props
  fi

  log "🔨 Building $type APK for $(basename "$proj")..."
  local task; task="assemble$(printf '%s' "${type^}")"
  if ! run_gradle "$proj" "$task"; then
    warn "Build fail. Try: 'forge repair' → 'forge clean' → 'forge doctor'"
    return 1
  fi
  local apk="$proj/app/build/outputs/apk/$type/app-$type.apk"
  if [[ -f "$apk" ]]; then
    ok "APK ready: $apk ($(du -h "$apk" | cut -f1))"
    if (( do_install )); then termux-open "$apk" || true; fi
  else
    warn "Build pass hua par APK path nahi mila: $apk"
  fi
}

cmd_bundle() {
  local proj; proj="$(resolve_proj "${1:-}")"
  ensure_project_ready "$proj"
  [[ -f "$(ks_file)" ]] || die "Release keystore nahi mila. 'forge keystore new' chalao."
  publish_keystore_props
  log "📦 Building Release Bundle (AAB) for $(basename "$proj")..."
  if ! run_gradle "$proj" bundleRelease; then warn "Bundle build fail."; return 1; fi
  local aab="$proj/app/build/outputs/bundle/release/app-release.aab"
  if [[ -f "$aab" ]]; then ok "AAB ready: $aab ($(du -h "$aab" | cut -f1))"; fi
}

cmd_install() {
  local type="debug" proj_arg="" a
  for a in "$@"; do
    case "$a" in release|debug) type="$a" ;; *) proj_arg="$a" ;; esac
  done
  local proj apk; proj="$(resolve_proj "$proj_arg")"
  apk="$proj/app/build/outputs/apk/$type/app-$type.apk"
  [[ -f "$apk" ]] || die "$type APK nahi mili. Pehle 'forge build $type' chalao."
  log "📲 Installer khul raha hai..."
  termux-open "$apk"
}

cmd_export() {
  local type="all" proj_arg="" a
  for a in "$@"; do
    case "$a" in debug|release|aab|all) type="$a" ;; *) proj_arg="$a" ;; esac
  done
  local proj name ver dest found=0 src
  proj="$(resolve_proj "$proj_arg")"; name="$(basename "$proj")"
  ver="$(get_version_name "$proj")"; ver="${ver:-0}"
  [[ -d "$HOME/storage/downloads" ]] || die "Storage access nahi hai. Pehle 'termux-setup-storage' chalao."
  dest="$HOME/storage/downloads/ForgeApps"; mkdir -p "$dest"

  if [[ "$type" == debug || "$type" == all ]]; then
    src="$proj/app/build/outputs/apk/debug/app-debug.apk"
    if [[ -f "$src" ]]; then cp "$src" "$dest/${name}-${ver}-debug.apk"; ok "Debug APK copied"; found=1; fi
  fi
  if [[ "$type" == release || "$type" == all ]]; then
    src="$proj/app/build/outputs/apk/release/app-release.apk"
    if [[ -f "$src" ]]; then cp "$src" "$dest/${name}-${ver}-release.apk"; ok "Release APK copied"; found=1; fi
  fi
  if [[ "$type" == aab || "$type" == all ]]; then
    src="$proj/app/build/outputs/bundle/release/app-release.aab"
    if [[ -f "$src" ]]; then cp "$src" "$dest/${name}-${ver}-release.aab"; ok "AAB copied"; found=1; fi
  fi
  if (( found )); then ok "🎉 Files: Download/ForgeApps/"; else warn "Koi build file nahi mili. Pehle 'forge build' chalao."; return 1; fi
}

cmd_icon() {
  local proj_arg="" img="" a
  for a in "$@"; do
    if [[ -f "$a" ]]; then img="$a"; else proj_arg="$a"; fi
  done
  [[ -n "$img" ]] || die "Usage: forge icon [project] <image.png|jpg>"
  local proj; proj="$(resolve_proj "$proj_arg")"
  if ! have magick && ! have convert; then
    log "📦 ImageMagick install ho raha hai..."
    pkg install -y --no-install-recommends imagemagick >/dev/null 2>&1 || true
  fi
  local im="convert"; have magick && im="magick"
  have "$im" || die "ImageMagick install nahi hua"

  local res="$proj/app/src/main/res" d size
  log "🎨 Icons ban rahe hain: $img"
  for d in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
    size="${d#*:}"
    mkdir -p "$res/mipmap-${d%%:*}"
    "$im" "$img" -resize "${size}x${size}^" -gravity center -extent "${size}x${size}" \
      "$res/mipmap-${d%%:*}/ic_launcher.png" || die "Icon convert fail ($d)"
  done
  local manifest="$proj/app/src/main/AndroidManifest.xml"
  if [[ -f "$manifest" ]] && ! grep -q 'android:icon=' "$manifest"; then
    sed -i 's|<application |<application android:icon="@mipmap/ic_launcher" |' "$manifest"
  fi
  ok "App icon set (manifest bhi update hua)"
}

cmd_package() {
  local proj_arg="" new_pkg="" a
  for a in "$@"; do
    if [[ "$a" =~ $PKG_RE ]]; then new_pkg="$a"; else proj_arg="$a"; fi
  done
  local proj old_pkg; proj="$(resolve_proj "$proj_arg")"
  [[ -f "$proj/app/build.gradle" ]] || die "app/build.gradle nahi mila."
  old_pkg="$(get_namespace "$proj")"
  [[ -n "$old_pkg" ]] || die "Purana namespace detect nahi hua."
  if [[ -z "$new_pkg" ]]; then
    printf '➜ Purana package: %s\n➜ Naya package name: ' "$old_pkg"; read -r new_pkg
  fi
  [[ "$new_pkg" =~ $PKG_RE ]] || die "Invalid package name format!"
  log "🔄 $old_pkg ➜ $new_pkg"
  apply_package_change "$proj" "$old_pkg" "$new_pkg"
  ok "Package updated: $new_pkg"
}

cmd_rename() {
  local proj_arg="" label="" a
  for a in "$@"; do
    if [[ -d "$a" || -d "$HOME/$a" ]] && [[ -z "$proj_arg" ]]; then proj_arg="$a"; else label="$a"; fi
  done
  [[ -n "$label" ]] || die "Usage: forge rename [project] \"Naya App Naam\""
  local proj; proj="$(resolve_proj "$proj_arg")"
  set_app_label "$proj" "$label"
  ok "App name → $label"
}

cmd_bump() {
  local kind="patch" proj_arg="" a
  for a in "$@"; do
    case "$a" in major|minor|patch) kind="$a" ;; *) proj_arg="$a" ;; esac
  done
  local proj f vc vn ma mi pa newvn newvc
  proj="$(resolve_proj "$proj_arg")"; f="$proj/app/build.gradle"
  [[ -f "$f" ]] || die "app/build.gradle nahi mila."
  vc="$(grep -Eo 'versionCode[[:space:]]+[0-9]+' "$f" | head -1 | grep -Eo '[0-9]+$' || true)"
  vn="$(get_version_name "$proj")"
  [[ -n "$vc" && -n "$vn" ]] || die "versionCode/versionName nahi mile."
  [[ "$vn" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || die "versionName '$vn' numeric (x.y.z) nahi hai — manually badlo."
  IFS=. read -r ma mi pa <<< "$vn"
  ma="${ma:-0}"; mi="${mi:-0}"; pa="${pa:-0}"
  case "$kind" in
    major) ma=$((ma + 1)); mi=0; pa=0 ;;
    minor) mi=$((mi + 1)); pa=0 ;;
    patch) pa=$((pa + 1)) ;;
  esac
  newvn="$ma.$mi.$pa"; newvc=$((vc + 1))
  sed -i -E "s/(versionCode[[:space:]]+)[0-9]+/\1$newvc/; s/(versionName[[:space:]]+\")[^\"]+(\")/\1$newvn\2/" "$f"
  ok "Version: $vn ($vc) ➜ $newvn ($newvc)"
}

cmd_clean() {
  local proj; proj="$(resolve_proj "${1:-}")"
  log "🧹 Cleaning $(basename "$proj")..."
  rm -rf "$proj/build" "$proj/app/build" "$proj/.gradle"
  ok "Build cache hata diya"
}

cmd_backup() {
  local proj name dest out
  proj="$(resolve_proj "${1:-}")"; name="$(basename "$proj")"
  [[ -d "$HOME/storage/downloads" ]] || die "Storage access nahi hai. 'termux-setup-storage' chalao."
  dest="$HOME/storage/downloads/ForgeBackups"; mkdir -p "$dest"
  out="$dest/${name}-$(date +%Y%m%d-%H%M).tar.gz"
  tar czf "$out" -C "$(dirname "$proj")" --exclude=build --exclude=.gradle --exclude=local.properties "$name"
  ok "Backup ready: Download/ForgeBackups/$(basename "$out") ($(du -h "$out" | cut -f1))"
}

cmd_repair() {
  local proj; proj="$(resolve_proj "${1:-}")"
  log "🔧 Repairing $(basename "$proj")..."
  echo "sdk.dir=$ANDROID_SDK" > "$proj/local.properties"
  if [[ -f "$FORGE_DIR/wrapper/gradlew" ]]; then
    cp -r "$FORGE_DIR/wrapper/gradlew" "$FORGE_DIR/wrapper/gradle" "$proj/"
    chmod +x "$proj/gradlew"
  fi
  rm -rf "$proj/.gradle"
  ok "Project repaired!"
}

cmd_keystore() {
  local sub="${1:-info}" ks props pass dest
  ks="$(ks_file)"; props="$(ks_props)"
  case "$sub" in
    info)
      if [[ ! -f "$ks" ]]; then warn "Keystore nahi bana. 'forge keystore new' chalao."; return 1; fi
      ok "Keystore: $ks"
      pass="$(sed -n 's/^FORGE_STORE_PASS=//p' "$props" 2>/dev/null | head -1 || true)"
      if have keytool && [[ -n "$pass" ]]; then
        keytool -list -v -keystore "$ks" -storepass "$pass" 2>/dev/null \
          | grep -E 'Alias name|Valid from|SHA1|SHA256' || true
      fi
      ;;
    backup)
      [[ -f "$ks" ]] || die "Keystore nahi mila."
      [[ -d "$HOME/storage/downloads" ]] || die "Storage access nahi hai. 'termux-setup-storage' chalao."
      dest="$HOME/storage/downloads/ForgeBackups/keystore-$(date +%Y%m%d-%H%M)"
      mkdir -p "$dest"
      cp "$ks" "$dest/"; [[ -f "$props" ]] && cp "$props" "$dest/"
      ok "Keystore backup: Download/ForgeBackups/$(basename "$dest")/"
      warn "Is folder ko safe jagah (Drive/pendrive) me rakho. Password file bhi isi me hai."
      ;;
    new)
      if [[ -f "$ks" ]]; then
        warn "Purana keystore replace hoga — us se signed apps update NAHI ho paayenge!"
        confirm "Pakka naya keystore banana hai?" || { log "Cancel."; return 0; }
        mv "$ks" "$ks.bak-$(date +%Y%m%d%H%M)"
        [[ -f "$props" ]] && mv "$props" "$props.bak-$(date +%Y%m%d%H%M)"
      fi
      ensure_keystore
      ;;
    *) die "Usage: forge keystore [info|backup|new]" ;;
  esac
}

cmd_update() {
  if dpkg -s termux-forge >/dev/null 2>&1; then
    local tag deb
    tag="$(curl -fsSL "https://api.github.com/repos/$REPO_SLUG/releases/latest" 2>/dev/null \
      | sed -nE 's/.*"tag_name": *"v?([^"]+)".*/\1/p' | head -1 || true)"
    [[ -n "$tag" ]] || die "Latest version check fail (internet / GitHub rate limit)."
    if [[ "$tag" == "$FORGE_VERSION" ]]; then ok "Already latest (v$FORGE_VERSION)"; return 0; fi
    log "⬇️  v$FORGE_VERSION ➜ v$tag"
    mkdir -p "$TMPDIR"; deb="$TMPDIR/termux-forge_${tag}_all.deb"
    curl -fL "https://github.com/$REPO_SLUG/releases/download/v${tag}/termux-forge_${tag}_all.deb" -o "$deb" \
      || die "Download fail"
    pkg install -y "$deb" && rm -f "$deb"
    ok "Updated to v$tag"
  elif [[ -d "$SHARE_DIR/.git" ]]; then
    log "🔄 git se update ho raha hai..."
    git -C "$SHARE_DIR" fetch origin main --quiet
    git -C "$SHARE_DIR" reset --hard origin/main --quiet
    ok "Updated. Ab 'forge setup' dobara chala sakte ho (CLI refresh ke liye)."
  else
    die "Update method nahi mila. install.sh dobara chalao."
  fi
}

cmd_ai() {
  local target="${1:-}"
  have opencode || die "OpenCode install nahi hai. 'forge setup' chalao."
  if [[ -n "$target" ]]; then cd "$(resolve_proj "$target")"; fi
  exec opencode
}

cmd_help() {
  printf '%s%sFORGE v%s%s\n' "$CY" "$B" "$FORGE_VERSION" "$R"
  cat <<'EOF' | fold -s -w "$(ui_width)"
forge <command> [options]

SETUP
  setup [--yes] [--name N]
    Environment setup
    --skip-android / --skip-ai
    --skip-shell / --speedtest
  doctor
    Health check
  info
    Versions, paths, free space
  update
    Latest Forge install karo

PROJECTS
  create <name> [opts]
    Naya project
    --template kotlin|webview
    --name "App"
    --package com.x.y
    --url https://example.com
    --git
  import <path>
    Project Termux home me lao
  list
    Saare projects
  rename [proj] "New Name"
    App display name badlo
  package [proj] com.new.pkg
    Package aur folders badlo
  icon [proj] <image>
    App icon banao
  bump [major|minor|patch] [proj]
    App version badhao
  clean [proj]
    Build cache hatao
  repair [proj]
    SDK path aur wrapper fix
  backup [proj]
    Download/ForgeBackups me save

BUILD & SHIP
  build [release] [proj] [-i]
    APK banao; -i se installer
  bundle [proj]
    Release AAB banao
  install [debug|release] [proj]
    Built APK ka installer kholo
  export [type] [proj]
    type: debug|release|aab|all
    Download/ForgeApps me copy
  keystore [info|backup|new]
    Release signing key manage

TOOLS
  ai [proj]
    OpenCode AI kholo
  sdk <args>
    sdkmanager passthrough
  version
    Forge version

Tip: project folder ke andar
[proj] dena zaroori nahi.
EOF
}

# ──────────────────────────── entrypoints ────────────────────────────
run_cli() {
  export ANDROID_HOME="$ANDROID_SDK" ANDROID_SDK_ROOT="$ANDROID_SDK"
  export JAVA_HOME="${JAVA_HOME:-$PREFIX/lib/jvm/java-17-openjdk}"
  mkdir -p "$TMPDIR"
  local cmd="${1:-help}"
  if (($# > 0)); then shift; fi

  case "$cmd" in
    setup)            run_full_setup "$@" ;;
    create|new)       cmd_create "$@" ;;
    import)           cmd_import "$@" ;;
    list|ls)          cmd_list ;;
    build)            cmd_build "$@" ;;
    bundle)           cmd_bundle "$@" ;;
    install)          cmd_install "$@" ;;
    export)           cmd_export "$@" ;;
    icon)             cmd_icon "$@" ;;
    package)          cmd_package "$@" ;;
    rename)           cmd_rename "$@" ;;
    bump)             cmd_bump "$@" ;;
    clean)            cmd_clean "$@" ;;
    repair)           cmd_repair "$@" ;;
    backup)           cmd_backup "$@" ;;
    keystore)         cmd_keystore "$@" ;;
    update)           cmd_update ;;
    ai)               cmd_ai "$@" ;;
    sdk)              exec "$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_SDK" "$@" ;;
    doctor)           doctor ;;
    info)             cmd_info ;;
    version|-v|--version) echo "termux-forge v${FORGE_VERSION}" ;;
    help|-h|--help)   cmd_help ;;
    *)                warn "Unknown command: $cmd"; cmd_help; return 1 ;;
  esac
}

run_full_setup() {
  while (($#)); do
    case "$1" in
      -y|--yes)       FORGE_YES=1 ;;
      --name)         (($# >= 2)) || die "--name ke baad naam do"; FORGE_NAME="$2"; shift ;;
      --skip-android) SKIP_ANDROID=1 ;;
      --skip-ai)      SKIP_OPENCODE=1 ;;
      --skip-shell)   SKIP_SHELL=1 ;;
      --speedtest)    FORGE_SPEEDTEST=1 ;;
      *)              warn "Ignoring unknown option: $1" ;;
    esac
    shift
  done

  [[ -n "${TERMUX_VERSION:-}" || "$PREFIX" == *com.termux* ]] \
    || die "Yeh setup sirf Termux (Android) ke liye hai."

  mkdir -p "$FORGE_DIR" "$TMPDIR"
  export ANDROID_HOME="$ANDROID_SDK" ANDROID_SDK_ROOT="$ANDROID_SDK"
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

  ui_clear
  ui_rule
  printf '%s%s' "$G" "$B"
  ui_text 'SETUP COMPLETE'
  printf '%s' "$R"
  ui_rule
  ui_text 'Shell reload karo:'
  ui_text '  exec zsh'
  printf '\n'
  ui_text 'Health check:'
  ui_text '  forge doctor'
  printf '\n'
  ui_text 'Naya project:'
  ui_text '  forge create my-app'
  ui_text '  cd ~/my-app'
  printf '\n'
  ui_text 'AI coding:'
  ui_text '  forge ai'
  printf '\n'
  ui_text 'Debug APK:'
  ui_text '  forge build'
  printf '\n'
  ui_text 'Release aur export:'
  ui_text '  forge build release'
  ui_text '  forge export'
  printf '\n'
  ui_text 'Saare commands: forge help'
}

main() {
  case "${1:-}" in
    --cli)    shift; run_cli "$@" ;;
    --doctor) doctor ;;
    version|-v|--version|help|-h|--help) run_cli "$@" ;;
    *)        run_full_setup "$@" ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
