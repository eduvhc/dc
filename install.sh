#!/usr/bin/env bash
#
# dc installer — installs or updates dc CLI + Claude Code skill
#

set -euo pipefail

REPO="https://raw.githubusercontent.com/eduvhc/dc/main"
BIN_DIR="${HOME}/.local/bin"
SKILL_DIR="${HOME}/.claude/skills/dc"

# Colors
if [[ -t 1 ]] && command -v tput &>/dev/null; then
    GREEN=$(tput setaf 2) YELLOW=$(tput setaf 3) CYAN=$(tput setaf 6) BOLD=$(tput bold) NC=$(tput sgr0)
else
    GREEN='' YELLOW='' CYAN='' BOLD='' NC=''
fi

log()     { printf "%b\n" "$*"; }
success() { log "${GREEN}✓${NC} $*"; }
warn()    { log "${YELLOW}→${NC} $*"; }
info()    { log "${CYAN}→${NC} $*"; }

# Detect install vs update
if [[ -x "${BIN_DIR}/dc" ]]; then
    OLD_VERSION=$("${BIN_DIR}/dc" --version 2>/dev/null || echo "unknown")
    warn "Existing installation found (${OLD_VERSION})"
    ACTION="Updated"
else
    ACTION="Installed"
fi

# Install dc CLI
mkdir -p "$BIN_DIR"
info "Downloading dc to ${BIN_DIR}/dc..."
curl -fsSL "${REPO}/dc" -o "${BIN_DIR}/dc"
chmod +x "${BIN_DIR}/dc"
NEW_VERSION=$("${BIN_DIR}/dc" --version 2>/dev/null || echo "unknown")

if [[ "$ACTION" == "Updated" ]]; then
    if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
        success "dc already up to date (${NEW_VERSION})"
    else
        success "dc updated: ${OLD_VERSION} → ${NEW_VERSION}"
    fi
else
    success "dc installed (${NEW_VERSION})"
fi

# Install Claude Code skill (optional)
if command -v claude &>/dev/null; then
    log ""
    if [[ -f "${SKILL_DIR}/SKILL.md" ]]; then
        info "Claude Code detected — skill already installed"
        printf "%b [y/N] " "Update Claude Code skill?"
    else
        info "Claude Code detected"
        printf "%b [y/N] " "Install Claude Code skill for dc?"
    fi
    read -r answer
    if [[ "$answer" == [yY] ]]; then
        mkdir -p "$SKILL_DIR"
        curl -fsSL "${REPO}/skill/SKILL.md" -o "${SKILL_DIR}/SKILL.md"
        success "Claude Code skill ready — use ${BOLD}/dc${NC} in Claude Code"
    else
        info "Skipped Claude Code skill"
    fi
fi

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    log ""
    log "${BOLD}Add this to your shell profile (.bashrc / .zshrc):${NC}"
    log "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    log ""
fi

success "Done! Run ${BOLD}dc -h${NC} to get started."
