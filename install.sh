#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  🚀 TERMUX-FORGE — Bootstrap Installer v7.0.0            ║
# ║  curl -fsSL .../install.sh | bash                        ║
# ║  Options: curl ... | bash -s -- --yes --name Yogeshwar   ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

REPO_OWNER="${FORGE_REPO_OWNER:-inyogeshwar}"
REPO_NAME="${FORGE_REPO_NAME:-termux-forge}"
BRANCH="${FORGE_BRANCH:-main}"
DEST="$HOME/.local/share/termux-forge"

if [[ -t 1 ]]; then
  R=$'\033[0m'; B=$'\033[1m'; G=$'\033[32m'
  BL=$'\033[34m'; RE=$'\033[31m'; CY=$'\033[36m'
else
  R=''; B=''; G=''; BL=''; RE=''; CY=''
fi

log() { printf '%s➜%s %s\n' "$BL$B" "$R" "$*"; }
ok()  { printf '%s✓%s %s\n' "$G" "$R" "$*"; }
die() { printf '%s✗%s %s\n' "$RE" "$R" "$*" >&2; exit 1; }

if [[ -t 1 ]]; then clear; fi
printf '%s%sTERMUX FORGE%s\n' "$CY" "$B" "$R"
printf 'v7.0.1 / Installer\n\n'

[[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == *"com.termux"* ]] \
  || die "Yeh script sirf Termux (Android) ke liye hai."

if ! command -v git >/dev/null 2>&1; then
  log "📦 git install ho raha hai..."
  pkg install -y git
fi

if [[ -d "$DEST/.git" ]]; then
  log "🔄 Existing install update ho raha hai..."
  git -C "$DEST" fetch origin "$BRANCH" --quiet
  git -C "$DEST" reset --hard "origin/$BRANCH" --quiet
else
  log "📥 Repo clone ho raha hai..."
  rm -rf "$DEST"
  mkdir -p "$(dirname "$DEST")"
  git clone --depth 1 --branch "$BRANCH" \
    "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$DEST" \
    || die "Clone fail — internet chal raha hai?"
fi

ok "Repo ready → $DEST"
echo
sleep 1
exec bash "$DEST/forge.sh" "$@"
