#!/usr/bin/env bash
#
# dc installer — installs dc CLI + Claude Code skill
#

set -euo pipefail

REPO="https://raw.githubusercontent.com/eduvhc/dc/main"

# Colors
if [[ -t 1 ]] && command -v tput &>/dev/null; then
    GREEN=$(tput setaf 2) CYAN=$(tput setaf 6) BOLD=$(tput bold) NC=$(tput sgr0)
else
    GREEN='' CYAN='' BOLD='' NC=''
fi

log()     { printf "%b\n" "$*"; }
success() { log "${GREEN}✓${NC} $*"; }
info()    { log "${CYAN}→${NC} $*"; }

# Install dc CLI
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"
info "Downloading dc to ${BIN_DIR}/dc..."
curl -fsSL "${REPO}/dc" -o "${BIN_DIR}/dc"
chmod +x "${BIN_DIR}/dc"
success "dc installed"

# Install Claude Code skill (optional)
if command -v claude &>/dev/null; then
    SKILL_DIR="${HOME}/.claude/skills/dc"
    mkdir -p "$SKILL_DIR"
    info "Downloading Claude Code skill..."
    curl -fsSL "${REPO}/skill/SKILL.md" -o "${SKILL_DIR}/SKILL.md"
    success "Claude Code skill installed"
else
    info "Claude Code not found — skipping skill install"
fi

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    log ""
    log "${BOLD}Add this to your shell profile (.bashrc / .zshrc):${NC}"
    log "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    log ""
fi

success "Done! Run ${BOLD}dc -h${NC} to get started."
