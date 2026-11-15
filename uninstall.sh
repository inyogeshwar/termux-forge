#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  🗑️  TERMUX-FORGE — Uninstaller v7.0.0                   ║
# ║  Options: --yes  --keep-sdk  --purge                     ║
# ║  Default: release keystore SAFE rehta hai (~/.forge)     ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

YES=0; PURGE=0; KEEP_SDK=0
for a in "$@"; do
  case "$a" in
    -y|--yes)   YES=1 ;;
    --purge)    PURGE=1 ;;
    --keep-sdk) KEEP_SDK=1 ;;
    -h|--help)
      echo "Usage: uninstall.sh [--yes] [--keep-sdk] [--purge]"
      echo "  --keep-sdk  Android SDK + ~/.gradle na hatao (re-download bachta hai)"
      echo "  --purge     release keystore bhi delete karo (DANGEROUS)"
      exit 0 ;;
    *) echo "Unknown option: $a" >&2; exit 1 ;;
  esac
done

R=$'\033[0m'; B=$'\033[1m'; G=$'\033[32m'; CY=$'\033[36m'
log() { printf '%s➜%s %s\n' "$CY$B" "$R" "$*"; }
ok()  { printf '%s✓%s %s\n' "$G" "$R" "$*"; }
PFX="${PREFIX:-/data/data/com.termux/files/usr}"

if [[ -t 1 ]]; then clear; fi
log "⚠️  Yeh Termux-Forge, OpenCode, configs (aur default me Android SDK) hata dega."
log "    Tumhare projects (~/my-app etc.) NAHI hatenge."
if (( PURGE )); then log "    🔥 --purge: release keystore BHI delete hoga!"; else log "    🔐 Release keystore safe rahega: ~/.forge/release.keystore"; fi

if (( ! YES )); then
  printf 'Pakka uninstall karna hai? (y/N): '
  read -r ans 2>/dev/null </dev/tty || ans="n"
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Cancel kar diya."; exit 0; }
fi

log "1. Forge files..."
rm -rf "$HOME/.local/share/termux-forge" "$HOME/hello-forge" "$HOME/git_install.log"
if [[ -d "$HOME/.forge" ]]; then
  if (( PURGE )); then
    rm -rf "$HOME/.forge"
  else
    find "$HOME/.forge" -mindepth 1 -maxdepth 1 \
      ! -name 'release.keystore' ! -name 'keystore.properties' -exec rm -rf {} +
  fi
fi

log "2. forge / opencode binaries..."
if dpkg -s termux-forge >/dev/null 2>&1; then
  pkg uninstall -y termux-forge || apt remove -y termux-forge || dpkg -r termux-forge || true
else
  rm -f "$PFX/bin/forge"
fi
rm -f "$PFX/bin/opencode"
rm -rf "$HOME/.opencode"

log "3. .zshrc clean..."
if [[ -f "$HOME/.zshrc" ]]; then
  sed -i '/# ── FORGE_ZSHRC/,/# ── END FORGE_ZSHRC/d' "$HOME/.zshrc" 2>/dev/null || true
fi

if (( KEEP_SDK )); then
  log "4. Android SDK / ~/.gradle rakha gaya (--keep-sdk)"
else
  log "4. Android SDK + Gradle cache..."
  rm -rf "$HOME/android-sdk" "$HOME/.gradle"
fi

ok "✅ Uninstall complete! (Oh My Zsh alag hai: rm -rf ~/.oh-my-zsh)"
