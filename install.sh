#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║  🚀 TERMUX-FORGE — Bootstrap Installer v6.5.0            ║
# ╚══════════════════════════════════════════════════════════╝
set -Eeuo pipefail

REPO_OWNER="${FORGE_REPO_OWNER:-inyogeshwar}"
REPO_NAME="${FORGE_REPO_NAME:-termux-forge}"
BRANCH="${FORGE_BRANCH:-main}"
DEST="$HOME/.local/share/termux-forge"

R=$'\033[0m'; B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'
BL=$'\033[34m'; RE=$'\033[31m'; CY=$'\033[36m'; MG=$'\033[35m'

log()  { printf '%s➜%s %s\n' "$BL$B" "$R" "$*"; }
ok()   { printf '%s✓%s %s\n' "$G" "$R" "$*"; }
die()  { printf '%s✗%s %s\n' "$RE" "$R" "$*" >&2; exit 1; }

clear
cat <<EOF
${CY}┌────────────────────────────────────┐${R}
${CY}│${R}  ${MG}${B}⚒️  TERMUX-FORGE  v6.5.0${R}          ${CY}│${R}
${CY}├────────────────────────────────────┤${R}
${CY}│${R}  ${BL}👤 inyogeshwar${R}                     ${CY}│${R}
${CY}│${R}  ${Y}🚀 Forge anything on Termux${R}        ${CY}│${R}
${CY}└────────────────────────────────────┘${R}
EOF

[[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == *"com.termux"* ]] \
  || die "⛔ Yeh script sirf Termux (Android) ke liye hai."

command -v git >/dev/null 2>&1 || {
  log "📦 git install ho raha hai..."
  pkg install -y git | tee "$HOME/git_install.log"
}

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
    || die "❌ Clone fail — repo public hai? Internet chal raha hai?"
fi

ok "✅ Repo ready → $DEST"
echo
sleep 1
exec bash "$DEST/forge.sh" "$@"