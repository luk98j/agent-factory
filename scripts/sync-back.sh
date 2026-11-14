#!/usr/bin/env bash
# Brings agent changes made in the user-level folder back into this
# repository on a new branch, ready for a pull request. Only agents this
# repository already tracks are synced, plus any named with --add.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_AGENTS_DIR="$REPO_DIR/agents"
CLAUDE_DIR="${CLAUDE_AGENTS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents}"
COPILOT_DIR="${COPILOT_AGENTS_DIR:-$HOME/.copilot/agents}"

# Things that must not reach a public repository: home paths, e-mail
# addresses, and common credential formats.
SENSITIVE_PATTERN='/Users/[^/ ]+|/home/[^/ ]+|[A-Za-z]:\\Users\\|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY'

usage() {
  cat <<EOF
Usage: scripts/sync-back.sh [--from claude|copilot] [--add NAME]... [--push]
                            [--dry-run] [--allow-sensitive]

Copies changed agents from the user-level folder into agents/, on a new
branch sync/agents-<timestamp>, and commits them.

Options:
  --from claude|copilot  folder to read from (default: claude)
                           claude   $CLAUDE_DIR
                           copilot  $COPILOT_DIR
  --add NAME             also bring in an agent the repository does not track
                         yet (NAME without .agent.md); repeatable
  --push                 push the branch and open a pull request with gh
  --dry-run              show what would change, write nothing
  --allow-sensitive      commit even if the safety scan finds something
EOF
}

source_name="claude"
is_dry_run=false
should_push=false
is_sensitive_allowed=false
added_names=""

while [ $# -gt 0 ]; do
  case "$1" in
    --from) source_name="${2:-}"; shift ;;
    --add) added_names="$added_names ${2:-}"; shift ;;
    --push) should_push=true ;;
    --dry-run) is_dry_run=true ;;
    --allow-sensitive) is_sensitive_allowed=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$source_name" in
  claude) source_dir="$CLAUDE_DIR"; other_dir="$COPILOT_DIR" ;;
  copilot) source_dir="$COPILOT_DIR"; other_dir="$CLAUDE_DIR" ;;
  *) echo "--from must be claude or copilot" >&2; exit 2 ;;
esac

if [ ! -d "$source_dir" ]; then
  echo "Source folder not found: $source_dir" >&2
  exit 1
fi
if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$REPO_DIR is not a git repository." >&2
  exit 1
fi

# Names to consider: every agent the repository tracks, plus --add names.
names=""
for repo_file in "$REPO_AGENTS_DIR"/*.agent.md; do
  [ -f "$repo_file" ] && names="$names $(basename "$repo_file" .agent.md)"
done
names="$names $added_names"

changed_files=""
for name in $names; do
  file_name="$name.agent.md"
  source_file="$source_dir/$file_name"
  if [ ! -f "$source_file" ]; then
    echo "  skipped    $file_name (not in $source_dir)"
    continue
  fi
  if [ -f "$REPO_AGENTS_DIR/$file_name" ] && cmp -s "$source_file" "$REPO_AGENTS_DIR/$file_name"; then
    continue
  fi
  if [ -f "$REPO_AGENTS_DIR/$file_name" ]; then
    echo "  changed    $file_name"
  else
    echo "  new        $file_name"
  fi
  if [ -f "$other_dir/$file_name" ] && ! cmp -s "$source_file" "$other_dir/$file_name"; then
    echo "  warning    $file_name differs between the Claude and Copilot folders; using $source_name"
  fi
  changed_files="$changed_files $file_name"
done

if [ -z "$changed_files" ]; then
  echo "Nothing to sync: the repository already matches $source_dir."
  exit 0
fi

has_sensitive=false
for file_name in $changed_files; do
  if grep -nE "$SENSITIVE_PATTERN" "$source_dir/$file_name" >/dev/null 2>&1; then
    has_sensitive=true
    echo "Possible personal data or secret in $file_name:" >&2
    grep -nE "$SENSITIVE_PATTERN" "$source_dir/$file_name" >&2
  fi
done
if $has_sensitive && ! $is_sensitive_allowed; then
  echo "Stopped. Remove the lines above, or rerun with --allow-sensitive if they are safe to publish." >&2
  exit 1
fi

if $is_dry_run; then
  echo "Dry run: nothing was written."
  exit 0
fi

if [ -n "$(git -C "$REPO_DIR" status --porcelain)" ]; then
  echo "The repository has uncommitted changes. Commit or stash them first." >&2
  exit 1
fi

branch_name="sync/agents-$(date +%Y%m%d-%H%M%S)"
git -C "$REPO_DIR" switch -c "$branch_name"

staged_paths=""
for file_name in $changed_files; do
  cp "$source_dir/$file_name" "$REPO_AGENTS_DIR/$file_name"
  staged_paths="$staged_paths agents/$file_name"
done
# shellcheck disable=SC2086
git -C "$REPO_DIR" add -- $staged_paths
git -C "$REPO_DIR" commit -m "chore: sync agents from the $source_name user folder" -m "Updated:$changed_files"

echo "Committed on branch $branch_name."

if ! $should_push; then
  echo "Next: git push -u origin $branch_name   then open a pull request,"
  echo "or rerun with --push to do both."
  exit 0
fi

git -C "$REPO_DIR" push -u origin "$branch_name"
if command -v gh >/dev/null 2>&1; then
  (cd "$REPO_DIR" && gh pr create --fill)
else
  echo "gh is not installed. Open the pull request for $branch_name on GitHub."
fi
