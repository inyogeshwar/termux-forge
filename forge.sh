#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  ⚒️  TERMUX-FORGE — Ultimate Setup v5.0                   ║
# ║  🎯 OpenCode + Android SDK + APK Build                   ║
# ║  👤 github.com/inyogeshwar                               ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Config ────────────────────────────────────────────────
readonly FORGE_VERSION="5.0.0"
readonly GRADLE_VER="8.7"
readonly AGP_VER="8.5.2"
readonly KOTLIN_VER="1.9.24"
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

# ── [0] Speedtest ─────────────────────────────────────────
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

# ── [1] Storage ───────────────────────────────────────────
step_storage() {
  clear
  log "▰▱▱▱▱▱▱▱  [1/9] 🔐 Storage access..."
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
  log "▰▰▱▱▱▱▱▱  [2/9] 🔄 System update..."
  log "⏳ Please wait, updating system..."
  pkg update -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  pkg upgrade -y 2>&1 | tee -a "$FORGE_DIR/pkg_update.log" >/dev/null || true
  ok "✅ System upgrade"
  sleep 1
}

# ── [3] Packages ──────────────────────────────────────────
step_packages() {
  clear
  log "▰▰▰▱▱▱▱▱  [3/9] 📦 Base packages..."
  
  pkg_install \
    git curl wget unzip nano zsh toilet ruby figlet \
    nodejs openjdk-17 gradle python \
    aapt aapt2 apksigner glibc-repo

  # Update for glibc
  pkg update -y >/dev/null 2>&1 || true
  pkg_install glibc-runner

  if ! have lolcat; then
    gem install lolcat >/dev/null 2>&1 || warn "🔔 lolcat install fail (cosmetic)"
  fi
  ok "✅ Packages ready"
  sleep 1
}

# ── [4] Shell & Zshrc (Dynamic Banner) ────────────────────
step_shell() {
  clear
  log "▰▰▰▰▱▱▱▱  [4/9] 🐚 Oh My Zsh + Powerlevel10k + Banner..."
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

  # Create .zshrc with dynamic banner
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

# Forge Env & Aliases
export ANDROID_SDK_ROOT="$HOME/android-sdk"
export ANDROID_HOME="$HOME/android-sdk"
export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
export PATH="$PATH:$HOME/.opencode/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/35.0.0"

alias addwrapper='cp -r ~/.forge/wrapper/gradlew ~/.forge/wrapper/gradle . && echo "gradlew aa gaya"'

# Dynamic Startup Banner
_forge_banner() {
  local name w out l p max=0
  name=$(cat ~/.forge/.name 2>/dev/null || echo Forge)
  w=${COLUMNS:-49}
  out=$(toilet -w 1000 -f smblock -F border "$name" 2>/dev/null)
  while IFS= read -r l; do (( ${#l} > max )) && max=${#l}; done <<< "$out"
  (( max > w )) && out=$(toilet -w "$w" -f smblock "$name" 2>/dev/null)
  echo
  while IFS= read -r l; do
    p=$(( (w - ${#l}) / 2 )); (( p < 0 )) && p=0
    printf "%*s%s\n" "$p" "" "$l"
  done <<< "$out" | lolcat -S 1 -F 0.25 -p 2 2>/dev/null
}
[[ -o interactive ]] && _forge_banner
ZSHRC
  fi

  if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
    chsh -s zsh 2>/dev/null || warn "🔔 chsh fail — manually 'chsh -s zsh' chalao"
  fi
  ok "✅ zsh + p10k + dynamic banner ready"
  sleep 1
}

# ── [5] OpenCode (glibc-runner method) ────────────────────
step_opencode() {
  clear
  log "▰▰▰▰▰▱▱▱  [5/9] 🤖 OpenCode..."
  
  if have opencode; then 
    ok "✅ OpenCode already installed"
    return
  fi

  log "⏳ Downloading OpenCode Linux ARM64 binary (~80MB)..."
  local OC_DIR="$HOME/.opencode/bin"
  local OC_VER
  OC_VER=$(npm view opencode-linux-arm64 version 2>/dev/null) || OC_VER="1.19.5"
  
  mkdir -p "$OC_DIR"
  rm -rf "$TMPDIR/oc" && mkdir -p "$TMPDIR/oc" && cd "$TMPDIR/oc"
  
  if npm pack --silent "opencode-linux-arm64@$OC_VER" >/dev/null 2>&1; then
    tar xzf "opencode-linux-arm64-$OC_VER.tgz"
    mv -f package/bin/opencode "$OC_DIR/opencode-linux"
    chmod +x "$OC_DIR/opencode-linux"
    
    # Create wrapper for Termux (using grun)
    cat > "$PREFIX/bin/opencode" << 'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec grun "$HOME/.opencode/bin/opencode-linux" "$@"
EOF
    chmod +x "$PREFIX/bin/opencode"
    cd "$HOME"; rm -rf "$TMPDIR/oc"
    ok "✅ OpenCode installed (Termux native)"
  else
    warn "🔔 OpenCode install fail. 'curl -fsSL https://hope2333.github.io/repo/install.sh | sh -s -- --install opencode' try karo."
  fi
  sleep 1
}

# ── [6] Android SDK ───────────────────────────────────────
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

  if [[ ! -d "$ANDROID_SDK/platforms/$SDK_PLATFORM" ]] \
     || [[ ! -d "$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER" ]]; then
    log "📦 Downloading SDK components (~200 MB)..."
    "$sdkmanager" --sdk_root="$ANDROID_SDK" \
      "platform-tools" "platforms;$SDK_PLATFORM" "build-tools;$BUILD_TOOLS_VER" \
      2>&1 | tee "$FORGE_DIR/sdk_download.log" || die "❌ sdkmanager install fail"
  fi

  # Symlink ARM binaries (Crucial fix)
  log "🔗 Patching build-tools with Termux ARM binaries..."
  local BT="$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER"
  for t in aapt aapt2 aidl zipalign apksigner; do
    if [ -e "$BT/$t" ] && command -v "$t" >/dev/null; then 
      ln -sf "$(command -v $t)" "$BT/$t" 
    fi
  done

  # Gradle properties
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

  [[ -f "$ANDROID_SDK/platforms/$SDK_PLATFORM/android.jar" ]] \
    && ok "✅ android.jar mila" || warn "🔔 android.jar nahi mila"
  ok "✅ Android SDK ready (Patched)"
  sleep 1
}

# ── [7] Test APK Build ────────────────────────────────────
step_test_apk() {
  clear
  log "▰▰▰▰▰▰▰▱  [7/9] 🎯 Test APK build..."
  [[ "$SKIP_ANDROID" == "1" || "$SKIP_TEST_APK" == "1" ]] && { warn "⏭️  Test APK skipped"; return; }

  export JAVA_HOME="${PREFIX}/lib/jvm/java-17-openjdk"
  export ANDROID_HOME="$ANDROID_SDK"
  export ANDROID_SDK_ROOT="$ANDROID_SDK"

  if [[ ! -f "$TEST_APP/settings.gradle" ]]; then
    log "🏗️  Creating sample project: $TEST_APP"
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

  # Safe Gradle Wrapper Generation
  local WR="$TMPDIR/wrapper-gen"
  rm -rf "$WR"; mkdir -p "$WR" && cd "$WR"
  touch settings.gradle
  gradle -q wrapper --gradle-version "$GRADLE_VER" >/dev/null 2>&1 || true
  
  if [ -f "$WR/gradlew" ]; then
    cp -r "$WR/gradlew" "$WR/gradle" "$TEST_APP/"
    rm -rf "$FORGE_DIR/wrapper" && mkdir -p "$FORGE_DIR/wrapper"
    cp -r "$WR/gradlew" "$WR/gradle" "$FORGE_DIR/wrapper/"
    ok "✓ Gradle wrapper ready"
  else
    warn "⚠ Wrapper generation failed"
  fi
  cd "$TEST_APP"

  log "⏳ Building APK... (First time 3-5 mins lagenge)"
  if ./gradlew assembleDebug --no-daemon > "$FORGE_DIR/build.log" 2>&1; then
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
  log "▰▰▰▰▰▰▰▰  [8/9] 🏁 Finalizing..."
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
  version) echo "termux-forge v5.0.0" ;;
  *) cat <<'EOF'
╔══════════════════════════════════════════╗
║  ⚒️  FORGE CLI v5.0                      ║
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

  local apk_file
  apk_file="$(find "$HOME/hello-forge" -name "*.apk" -type f 2>/dev/null | head -n 1)"
  if [[ -n "$apk_file" ]]; then
    ok "✓ Test APK ($apk_file)"
  else
    warn "⚠ Test APK (nahi mila — 'forge build' chalao)"
    fails=$((fails+1))
  fi

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