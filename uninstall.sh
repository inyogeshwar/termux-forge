#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  🗑️  TERMUX-FORGE — Complete Uninstaller v6.5.0          ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

R=$'\033[0m'; B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; RE=$'\033[31m'; CY=$'\033[36m'
log()  { printf '%s➜%s %s\n' "$CY$B" "$R" "$*"; }
ok()   { printf '%s✓%s %s\n' "$G" "$R" "$*"; }

clear
log "⚠️  WARNING: Yeh sab kuch delete kar dega (Projects, SDK, OpenCode, Configs)"
printf "Kya aap pakka uninstall karna chahte hain? (y/N): "
read -r ans </dev/tty || ans="n"
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
  echo "Cancel kar diya."
  exit 0
fi

log "1. Termux-Forge files remove ho rahi hain..."
rm -rf "$HOME/.local/share/termux-forge"
rm -rf "$HOME/.forge"
rm -rf "$HOME/hello-forge"
rm -f "$HOME/git_install.log"

log "2. Binaries / Package remove kiye ja rahe hain..."
if dpkg -s termux-forge >/dev/null 2>&1; then
  pkg uninstall -y termux-forge || dpkg -r termux-forge || true
else
  rm -f "${PREFIX:-/data/data/com.termux/files/usr}/bin/forge"
fi
rm -f "${PREFIX:-/data/data/com.termux/files/usr}/bin/opencode"

log "3. .zshrc ko clean kiya ja raha hai..."
if [ -f "$HOME/.zshrc" ]; then
  sed -i '/# ── FORGE_ZSHRC/,/# ── END FORGE_ZSHRC/d' "$HOME/.zshrc" 2>/dev/null || true
fi

log "4. Gradle aur Android SDK remove kiya ja raha hai..."
rm -rf "$HOME/android-sdk"
rm -rf "$HOME/.gradle"

ok "✅ Uninstall Complete! Naya setup karne ke liye fresh install script chala sakte ho."