#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  ⚒️  TERMUX-FORGE — Main Setup v4.1 (Full Fixed)          ║
# ║  🎯 OpenCode + Android SDK + APK Build                   ║
# ║  👤 github.com/inyogeshwar                               ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Config ────────────────────────────────────────────────
readonly FORGE_VERSION="4.1.0"
readonly GRADLE_VER="8.7"
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

# ── Colors ────────────────────────────────────────────────
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

# ── Mobile-Friendly Banner ────────────────────────────────
banner() {
clear
cat <<EOF
${CY}┌────────────────────────────────────┐${R}
${CY}│${R}  ${MG}${B}⚒️  T E R M U X - F O R G E${R}       ${CY}│${R}
${CY}├────────────────────────────────────┤${R}
${CY}│${R}  ${G}🎯 v${FORGE_VERSION}${R}  ${CY}│${R}  ${Y}🤖 OpenCode${R}  ${CY}│${R}  ${BL}⚙️ SDK${R} ${CY}│${R}
${CY}│${R}  ${BL}👤 github.com/inyogeshwar${R}          ${CY}│${R}
${CY}└────────────────────────────────────┘${R}
EOF
}

# ── Name prompt ───────────────────────────────────────────
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

# ── Helpers ───────────────────────────────────────────────
pkg_install() {
  local pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  local missing=()
  local p
  for p in "${pkgs[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  
  log "📦 Installing: ${missing[*]}"
  log "⏳ Downloading... (Live progress below, please wait)"
  
  mkdir -p "$FORGE_DIR"
  local log_file="$FORGE_DIR/pkg_install.log"
  local attempt

  for attempt in {1..3}; do
    if pkg install -y "${missing[@]}" 2>&1 | tee "$log_file"; then
      ok "✓ Packages installed successfully."
      return 0
    fi
    if [[ $attempt -lt 3 ]]; then
      warn "⚠ Install fail hua (Attempt $attempt/3). Retrying in 3s..."
      sleep 3
    fi
  done

  warn "❌ pkg install failed."
  tail -n 15 "$log_file" >&2
  die "Check internet or run 'termux-change-repo'."
}
has_storage() { [[ -d "$HOME/storage" ]]; }

# ── [1] Storage ───────────────────────────────────────────
step_storage() {
  clear
  log "▰▱▱▱▱▱▱▱  [1/7] 🔐 Storage access..."
  if has_storage; then ok "✅ Storage mil gaya"; return; fi
  termux-setup-storage >/dev/null 2>&1 || true
  local i
  for i in {1..15}; do has_storage && break; sleep 1; done
  has_storage && ok "✅ Storage mil gaya" || warn "🔔 Storage permission nahi mila (skip)"
  sleep 1
}

# ── [2] Update ────────────────────────────────────────────
step_update() {
  clear
  log "▰▰▱▱▱▱▱▱  [2/7] 🔄 System update..."
  log "⏳ Please wait, updating system..."
  pkg update -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  pkg upgrade -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  ok "✅ System upgrade"
  sleep 1
}

# ── [Speedtest] ───────────────────────────────────────────
step_speedtest() {
  clear
  log "▰▱▱▱▱▱▱▱  [0/8] 🚀 Internet Speed Test..."
  
  if ! have speedtest-cli; then
    log "📦 Installing Python (needed for speedtest)..."
    pkg_install python || true
    
    log "🐍 Installing speedtest-cli via pip..."
    pip install speedtest-cli --quiet 2>/dev/null || true
    
    # Fallback if pip fails
    if ! have speedtest-cli; then
      curl -fsSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py \
        -o "$PREFIX/bin/speedtest-cli" && chmod +x "$PREFIX/bin/speedtest-cli" || true
    fi
  fi

  if have speedtest-cli || [[ -x "$PREFIX/bin/speedtest-cli" ]]; then
    log "⏳ Testing your network speed (Please wait 10-15s)..."
    echo "--------------------------------------------------"
    speedtest-cli --simple || warn "🔔 Speedtest fail ho gaya, par setup continue rahega."
    echo "--------------------------------------------------"
    if [[ "$FORGE_YES" == "0" ]]; then
      printf '\n➜ Network theek lag raha hai? Setup start karne ke liye Enter dabao...'
      read -r _ </dev/tty || true
    fi
  else
    warn "🔔 speedtest-cli install nahi ho paya, skip kar rahe hain."
  fi
  sleep 1
}

# ── [3] Packages ──────────────────────────────────────────
step_packages() {
  clear
  log "▰▰▰▱▱▱▱▱  [3/7] 📦 Base packages..."
  
  # Speedtest-cli removed from here (handled in step_speedtest)
  pkg_install \
    git curl wget unzip nano zsh toilet ruby figlet \
    nodejs openjdk-17 gradle python \
    aapt aapt2 apksigner

  if ! dpkg -s glibc-repo >/dev/null 2>&1; then
    log "📦 Adding glibc repository..."
    pkg install -y glibc-repo 2>&1 | tee -a "$FORGE_DIR/pkg_install.log"
    log "🔄 Updating package lists for glibc..."
    pkg update -y >/dev/null 2>&1 || true
  fi

  if ! dpkg -s glibc-runner >/dev/null 2>&1; then
    pkg_install glibc-runner
  fi

  if ! have lolcat; then
    gem install lolcat >/dev/null 2>&1 || warn "🔔 lolcat install fail (cosmetic)"
  fi
  ok "✅ Packages ready"
  sleep 1
}

# ── [4] Shell & Zshrc ─────────────────────────────────────
step_shell() {
  clear
  log "▰▰▰▰▱▱▱▱  [4/7] 🐚 Oh My Zsh + Powerlevel10k..."
  log "⏳ Setting up terminal environment..."

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 \
      || warn "🔔 Oh My Zsh install fail"
  fi

  local zc="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [[ -d "$zc/themes/powerlevel10k" ]] \
    || git clone --depth 1 https://github.com/romkatv/powerlevel10k.git \
         "$zc/themes/powerlevel10k" >/dev/null 2>&1 || true
  [[ -d "$zc/plugins/zsh-autosuggestions" ]] \
    || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
         "$zc/plugins/zsh-autosuggestions" >/dev/null 2>&1 || true

  if ! grep -q 'FORGE_ZSHRC' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'ZSHRC'

# ── FORGE_ZSHRC — managed block ───────────────────────────
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
command -v lolcat >/dev/null && alias lc='lolcat'

# Forge env variables
export ANDROID_SDK_ROOT="$HOME/android-sdk"
export ANDROID_HOME="$HOME/android-sdk"
export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
export PATH="$PATH:$HOME/.opencode/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/35.0.0"
ZSHRC
  fi

  if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
    chsh -s zsh 2>/dev/null || warn "🔔 chsh fail — manually 'chsh -s zsh' chalao"
  fi
  ok "✅ zsh + p10k ready"
  sleep 1
}

# ── [5] OpenCode ──────────────────────────────────────────
step_opencode() {
  clear
  log "▰▰▰▰▰▱▱▱  [5/7] 🤖 OpenCode..."
  
  if have opencode; then 
    ok "✅ OpenCode already installed"
    return
  fi

  log "⏳ Downloading OpenCode... (Live progress below)"

  # 1. Official v2 URL
  if curl -fsSL https://opencode.ai/install | bash; then
    ok "✅ OpenCode installed (official script)"
    return
  fi

  warn "⚠️ Official install script fail hua, alternative method try kar rahe hain..."
  sleep 1
  
  # 2. Fallback: Termux Specific Repo
  if curl -fsSL https://hope2333.github.io/repo/install.sh | sh -s -- --install opencode; then
    ok "✅ OpenCode installed (Termux native)"
    return
  fi
  
  warn "🔔 OpenCode install nahi ho paya."
  sleep 1
}

# ── [6] Android SDK ───────────────────────────────────────
step_android_sdk() {
  clear
  log "▰▰▰▰▰▰▱▱  [6/7] ⚙️  Android SDK..."
  [[ "$SKIP_ANDROID" == "1" ]] && { warn "⏭️  Android SDK skipped"; return; }

  export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
  mkdir -p "$ANDROID_SDK"

  local sdkmanager="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"

  if [[ ! -x "$sdkmanager" ]]; then
    log "📥 Downloading cmdline-tools (~100 MB)..."
    log "⏳ Live progress below:"
    local zip="$TMPDIR/cmdline-tools.zip"
    curl -# -L "$CMDLINE_TOOLS_URL" -o "$zip" \
      || die "❌ cmdline-tools download fail"
    rm -rf "$ANDROID_SDK/cmdline-tools"
    mkdir -p "$ANDROID_SDK/cmdline-tools"
    log "📦 Extracting..."
    unzip -q "$zip" -d "$ANDROID_SDK/cmdline-tools"
    mv "$ANDROID_SDK/cmdline-tools/cmdline-tools" "$ANDROID_SDK/cmdline-tools/latest"
    rm -f "$zip"
  fi

  yes | "$sdkmanager" --sdk_root="$ANDROID_SDK" --licenses >/dev/null 2>&1 || true

  if [[ ! -d "$ANDROID_SDK/platforms/$SDK_PLATFORM" ]] \
     || [[ ! -d "$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER" ]]; then
    log "📦 Downloading SDK components (~200 MB)..."
    log "⏳ Live progress below:"
    "$sdkmanager" --sdk_root="$ANDROID_SDK" \
      "platform-tools" "platforms;$SDK_PLATFORM" "build-tools;$BUILD_TOOLS_VER" \
      2>&1 | tee "$FORGE_DIR/sdk_download.log" || die "❌ sdkmanager install fail"
  fi

  local aapt2_bin
  aapt2_bin="$(command -v aapt2 || echo "${PREFIX}/bin/aapt2")"
  mkdir -p "$HOME/.gradle"
  grep -q "aapt2FromMavenOverride" "$HOME/.gradle/gradle.properties" 2>/dev/null \
    || echo "android.aapt2FromMavenOverride=$aapt2_bin" >> "$HOME/.gradle/gradle.properties"

  [[ -f "$ANDROID_SDK/platforms/$SDK_PLATFORM/android.jar" ]] \
    && ok "✅ android.jar mila" || warn "🔔 android.jar nahi mila"
  ok "✅ Android SDK ready"
  sleep 1
}

# ── [7] Test APK Build ────────────────────────────────────
step_test_apk() {
  clear
  log "▰▰▰▰▰▰▰▱  [7/7] 🎯 Test APK build..."
  [[ "$SKIP_ANDROID" == "1" || "$SKIP_TEST_APK" == "1" ]] && { warn "⏭️  Test APK skipped"; return; }

  export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
  export ANDROID_HOME="$ANDROID_SDK"
  export ANDROID_SDK_ROOT="$ANDROID_SDK"

  if [[ ! -f "$TEST_APP/settings.gradle" ]]; then
    log "🏗️  Creating sample project: $TEST_APP"
    mkdir -p "$TEST_APP/app/src/main/java/com/forge/hello"

    # ✅ FIX: Plugin Management Block for Gradle 8+
    cat > "$TEST_APP/settings.gradle" <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "hello-forge"
include ":app"
EOF

    cat > "$TEST_APP/build.gradle" <<'EOF'
plugins {
    id 'com.android.application' version '8.5.2' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.24' apply false
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
    ok "🔧 local.properties created → sdk.dir=$ANDROID_SDK"
  fi

  # ✅ FIX: Ensure Gradle Wrapper is used for correct version
  local gradle_cmd
  if [[ ! -f "$TEST_APP/gradlew" ]]; then
    log "⚙️  Generating Gradle wrapper ($GRADLE_VER)..."
    (cd "$TEST_APP" && gradle wrapper --gradle-version "$GRADLE_VER" --no-daemon >/dev/null 2>&1) || true
  fi

  if [[ -x "$TEST_APP/gradlew" ]]; then
    gradle_cmd="./gradlew"; ok "✓ gradlew detected (Gradle $GRADLE_VER)"
  else
    gradle_cmd="gradle"; ok "✓ Using system gradle (wrapper skip)"
  fi

  log "⏳ Building APK... (First time 3-5 mins lagenge)"
  cd "$TEST_APP"
  if $gradle_cmd assembleDebug --no-daemon > "$FORGE_DIR/build.log" 2>&1; then
    ok "✅ Test APK ready"
    local apk="$TEST_APP/app/build/outputs/apk/debug/app-debug.apk"
    [[ -f "$apk" ]] && ok "📲 APK → $apk" || warn "🔔 APK file not found"
  else
    warn "❌ Build failed → log: $FORGE_DIR/build.log"
    tail -20 "$FORGE_DIR/build.log" >&2 || true
  fi
  sleep 1
}

# ── [8] Finalize ──────────────────────────────────────────
step_finalize() {
  clear
  log "▰▰▰▰▰▰▰▰  [8/8] 🏁 Finalizing..."
  mkdir -p "$FORGE_DIR"

  local forge_bin="${PREFIX}/bin/forge"
  cat > "$forge_bin" <<'CLI'
#!/usr/bin/env bash
set -Eeuo pipefail
case "${1:-help}" in
  build)
    cd "${2:-$HOME/hello-forge}"
    shift 2 2>/dev/null || shift
    exec ./gradlew assembleDebug --no-daemon "$@" 2>/dev/null || exec gradle assembleDebug --no-daemon "$@"
    ;;
  sdk)    exec sdkmanager --sdk_root="$ANDROID_HOME" "${@:2}" ;;
  ai)     exec opencode ;;
  doctor) exec bash "$HOME/.local/share/termux-forge/forge.sh" --doctor ;;
  version) echo "termux-forge v4.1.0" ;;
  *) cat <<'EOF'
╔══════════════════════════════════════════╗
║  ⚒️  FORGE CLI v4.1                      ║
╠══════════════════════════════════════════╣
║  ➜ forge build [dir]   Build APK         ║
║  ➜ forge sdk [args]    sdkmanager        ║
║  ➜ forge ai            OpenCode          ║
║  ➜ forge doctor        Health check      ║
║  ➜ forge version       Version           ║
╚══════════════════════════════════════════╝
EOF
  ;;
esac
CLI
  chmod +x "$forge_bin"
  ok "✅ forge CLI → $forge_bin"
}

# ── Doctor ────────────────────────────────────────────────
doctor() {
  log "🩺 Health check..."
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
  check "✓ Test APK"              '[[ -f "$HOME/hello-forge/app/build/outputs/apk/debug/app-debug.apk" ]]'

  [[ "$fails" -eq 0 ]] && ok "🎯 Sab theek hai! 🚀" || warn "⚠ $fails check(s) fail"
  return "$fails"
}

# ── Main ──────────────────────────────────────────────────
main() {
  mkdir -p "$FORGE_DIR"
  export TMPDIR="${TMPDIR:-${PREFIX}/tmp}"
  mkdir -p "$TMPDIR"

  if [[ "${1:-}" == "--doctor" ]]; then doctor; return; fi

  banner
  ask_name

  step_storage
  step_update
  step_speedtest
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
${CY}➜ Aage yeh use karo:${R}
  ${G}▸${R} forge build        ${Y}APK build${R}
  ${G}▸${R} forge doctor       ${Y}Health check${R}
  ${G}▸${R} forge ai           ${Y}OpenCode${R}
  ${G}▸${R} exec zsh           ${Y}Naya shell (recommended)${R}

${CY}📲 APK path:${R}
  ${BL}~/hello-forge/app/build/outputs/apk/debug/app-debug.apk${R}

${MG}👤 github.com/inyogeshwar${R}
EOF
}

main "$@"