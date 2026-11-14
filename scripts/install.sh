#!/usr/bin/env bash
# Copies the agents in this repository to the user-level agent folders of
# Claude Code and GitHub Copilot CLI, so they are available in every project.
# Only files from agents/ are written; nothing else in the targets is touched.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$REPO_DIR/agents"
CLAUDE_DIR="${CLAUDE_AGENTS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents}"
COPILOT_DIR="${COPILOT_AGENTS_DIR:-$HOME/.copilot/agents}"

usage() {
  cat <<EOF
Usage: scripts/install.sh [--dry-run] [--claude-only | --copilot-only]

Copies agents/*.agent.md to:
  Claude Code   $CLAUDE_DIR
  Copilot CLI   $COPILOT_DIR

Options:
  --dry-run        show what would change, write nothing
  --claude-only    install for Claude Code only
  --copilot-only   install for Copilot CLI only

Override the targets with CLAUDE_AGENTS_DIR and COPILOT_AGENTS_DIR.
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

if ! ls "$SOURCE_DIR"/*.agent.md >/dev/null 2>&1; then
  echo "No agent files found in $SOURCE_DIR" >&2
  exit 1
fi

install_to() {
  local label="$1" target_dir="$2"
  local new_count=0 updated_count=0 unchanged_count=0
  echo "$label -> $target_dir"
  $is_dry_run || mkdir -p "$target_dir"

  for source_file in "$SOURCE_DIR"/*.agent.md; do
    local name target_file state
    name="$(basename "$source_file")"
    target_file="$target_dir/$name"
    if [ ! -f "$target_file" ]; then
      state="new"; new_count=$((new_count + 1))
    elif cmp -s "$source_file" "$target_file"; then
      state="unchanged"; unchanged_count=$((unchanged_count + 1))
    else
      state="updated"; updated_count=$((updated_count + 1))
    fi
    if [ "$state" != "unchanged" ]; then
      echo "  $state  $name"
      $is_dry_run || cp "$source_file" "$target_file"
    fi
  done
  echo "  $new_count new, $updated_count updated, $unchanged_count unchanged"
}

$should_install_claude && install_to "Claude Code" "$CLAUDE_DIR"
$should_install_copilot && install_to "Copilot CLI" "$COPILOT_DIR"

if $is_dry_run; then
  echo "Dry run: nothing was written."
else
  echo "Done. Start a session with: claude --agent orchestrator  |  copilot --agent orchestrator"
fi
