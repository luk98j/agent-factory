#!/usr/bin/env bash
# Copies the agents and skills in this repository to the user-level folders
# of Claude Code and GitHub Copilot CLI, so they are available in every
# project. Only files from agents/ and skills/ are written; nothing else in
# the targets is touched.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME_DIR="${CLAUDE_HOME_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}"
COPILOT_HOME_DIR="${COPILOT_HOME_DIR:-$HOME/.copilot}"

usage() {
  cat <<EOF
Usage: scripts/install.sh [--dry-run] [--claude-only | --copilot-only]

Copies agents/*.agent.md and skills/<name>/ to:
  Claude Code   $CLAUDE_HOME_DIR/{agents,skills}
  Copilot CLI   $COPILOT_HOME_DIR/{agents,skills}

Options:
  --dry-run        show what would change, write nothing
  --claude-only    install for Claude Code only
  --copilot-only   install for Copilot CLI only

Override the targets with CLAUDE_HOME_DIR and COPILOT_HOME_DIR.
EOF
}

is_dry_run=false
should_install_claude=true
should_install_copilot=true

for arg in "$@"; do
  case "$arg" in
    --dry-run) is_dry_run=true ;;
    --claude-only) should_install_copilot=false ;;
    --copilot-only) should_install_claude=false ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

# Paths relative to the repository root: every agent file and every file
# inside a skill folder.
list_repo_files() {
  (
    cd "$REPO_DIR"
    ls agents/*.agent.md 2>/dev/null || true
    [ -d skills ] && find skills -type f ! -name '.DS_Store' | sort
  )
}

relative_files="$(list_repo_files)"
if [ -z "$relative_files" ]; then
  echo "No agents or skills found in $REPO_DIR" >&2
  exit 1
fi

install_to() {
  local label="$1" target_home="$2"
  local new_count=0 updated_count=0 unchanged_count=0
  echo "$label -> $target_home"

  for relative_file in $relative_files; do
    local source_file="$REPO_DIR/$relative_file"
    local target_file="$target_home/$relative_file"
    local state
    if [ ! -f "$target_file" ]; then
      state="new"; new_count=$((new_count + 1))
    elif cmp -s "$source_file" "$target_file"; then
      state="unchanged"; unchanged_count=$((unchanged_count + 1))
    else
      state="updated"; updated_count=$((updated_count + 1))
    fi
    if [ "$state" != "unchanged" ]; then
      echo "  $state  $relative_file"
      if ! $is_dry_run; then
        mkdir -p "$(dirname "$target_file")"
        cp "$source_file" "$target_file"
      fi
    fi
  done
  echo "  $new_count new, $updated_count updated, $unchanged_count unchanged"
}

$should_install_claude && install_to "Claude Code" "$CLAUDE_HOME_DIR"
$should_install_copilot && install_to "Copilot CLI" "$COPILOT_HOME_DIR"

if $is_dry_run; then
  echo "Dry run: nothing was written."
else
  echo "Done. Start a session with: claude --agent orchestrator  |  copilot --agent orchestrator"
fi
