#!/usr/bin/env bash
# Brings agent and skill changes made in the user-level folder back into this
# repository on a new branch, ready for a pull request. Only agents and
# skills this repository already tracks are synced, plus any named with
# --add or --add-skill.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME_DIR="${CLAUDE_HOME_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}"
COPILOT_HOME_DIR="${COPILOT_HOME_DIR:-$HOME/.copilot}"

# Things that must not reach a public repository: home paths, e-mail
# addresses, and common credential formats.
SENSITIVE_PATTERN='/Users/[^/ ]+|/home/[^/ ]+|[A-Za-z]:\\Users\\|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY'

usage() {
  cat <<EOF
Usage: scripts/sync-back.sh [--from claude|copilot] [--add NAME]...
                            [--add-skill NAME]... [--push] [--dry-run]
                            [--allow-sensitive]

Copies changed agents and skills from the user-level folder into agents/ and
skills/, on a new branch sync/<timestamp>, and commits them.

Options:
  --from claude|copilot  folder to read from (default: claude)
                           claude   $CLAUDE_HOME_DIR
                           copilot  $COPILOT_HOME_DIR
  --add NAME             also bring in an agent the repository does not track
                         yet (NAME without .agent.md); repeatable
  --add-skill NAME       also bring in a skill folder the repository does not
                         track yet; repeatable
  --push                 push the branch and open a pull request with gh
  --dry-run              show what would change, write nothing
  --allow-sensitive      commit even if the safety scan finds something
EOF
}

source_name="claude"
is_dry_run=false
should_push=false
is_sensitive_allowed=false
added_agents=""
added_skills=""

while [ $# -gt 0 ]; do
  case "$1" in
    --from) source_name="${2:-}"; shift ;;
    --add) added_agents="$added_agents ${2:-}"; shift ;;
    --add-skill) added_skills="$added_skills ${2:-}"; shift ;;
    --push) should_push=true ;;
    --dry-run) is_dry_run=true ;;
    --allow-sensitive) is_sensitive_allowed=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$source_name" in
  claude) source_home="$CLAUDE_HOME_DIR"; other_home="$COPILOT_HOME_DIR" ;;
  copilot) source_home="$COPILOT_HOME_DIR"; other_home="$CLAUDE_HOME_DIR" ;;
  *) echo "--from must be claude or copilot" >&2; exit 2 ;;
esac

if [ ! -d "$source_home" ]; then
  echo "Source folder not found: $source_home" >&2
  exit 1
fi
if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$REPO_DIR is not a git repository." >&2
  exit 1
fi

# Relative paths to consider: everything the repository tracks under agents/
# and skills/, plus what --add and --add-skill name in the source folder.
relative_files="$(
  cd "$REPO_DIR"
  ls agents/*.agent.md 2>/dev/null || true
  [ -d skills ] && find skills -type f ! -name '.DS_Store' | sort
)"
for name in $added_agents; do
  relative_files="$relative_files agents/$name.agent.md"
done
for name in $added_skills; do
  if [ -d "$source_home/skills/$name" ]; then
    relative_files="$relative_files $(cd "$source_home" && find "skills/$name" -type f ! -name '.DS_Store' | sort)"
  else
    echo "  skipped    skills/$name (not in $source_home)"
  fi
done

changed_files=""
for relative_file in $relative_files; do
  source_file="$source_home/$relative_file"
  repo_file="$REPO_DIR/$relative_file"
  if [ ! -f "$source_file" ]; then
    echo "  skipped    $relative_file (not in $source_home)"
    continue
  fi
  if [ -f "$repo_file" ] && cmp -s "$source_file" "$repo_file"; then
    continue
  fi
  if [ -f "$repo_file" ]; then
    echo "  changed    $relative_file"
  else
    echo "  new        $relative_file"
  fi
  if [ -f "$other_home/$relative_file" ] && ! cmp -s "$source_file" "$other_home/$relative_file"; then
    echo "  warning    $relative_file differs between the Claude and Copilot folders; using $source_name"
  fi
  changed_files="$changed_files $relative_file"
done

if [ -z "$changed_files" ]; then
  echo "Nothing to sync: the repository already matches $source_home."
  exit 0
fi

has_sensitive=false
for relative_file in $changed_files; do
  if grep -nE "$SENSITIVE_PATTERN" "$source_home/$relative_file" >/dev/null 2>&1; then
    has_sensitive=true
    echo "Possible personal data or secret in $relative_file:" >&2
    grep -nE "$SENSITIVE_PATTERN" "$source_home/$relative_file" >&2
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

branch_name="sync/$(date +%Y%m%d-%H%M%S)"
git -C "$REPO_DIR" switch -c "$branch_name"

for relative_file in $changed_files; do
  mkdir -p "$(dirname "$REPO_DIR/$relative_file")"
  cp "$source_home/$relative_file" "$REPO_DIR/$relative_file"
done
# shellcheck disable=SC2086
git -C "$REPO_DIR" add -- $changed_files
git -C "$REPO_DIR" commit -m "chore: sync agents and skills from the $source_name user folder" -m "Updated:$changed_files"

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
