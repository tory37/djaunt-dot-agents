#!/usr/bin/env bash
# check-budget.sh — Enforce token budgets on always-loaded instruction files.
# Exit 1 if any file is over budget. Warn at 80%.
# Override limits: AGENTS_MAX_TOKENS=5000 SKILL_MAX_TOKENS=2500 bash scripts/check-budget.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_MAX_TOKENS=${AGENTS_MAX_TOKENS:-5000}
SKILL_MAX_TOKENS=${SKILL_MAX_TOKENS:-2500}
CHARS_PER_TOKEN=${CHARS_PER_TOKEN:-4}
WARN_PERCENT=80

RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'

IS_OVER_BUDGET=false

check_file() {
    local file="$1" max_tokens="$2"
    local char_count estimated_tokens percent_used label
    char_count=$(wc -c < "$file" | tr -d ' ')
    estimated_tokens=$((char_count / CHARS_PER_TOKEN))
    percent_used=$((estimated_tokens * 100 / max_tokens))
    label="${file#"$REPO_ROOT"/}"

    if [ "$estimated_tokens" -gt "$max_tokens" ]; then
        printf "${RED}OVER${NC}  %s  ~%d / %d tokens (%d%%)\n" "$label" "$estimated_tokens" "$max_tokens" "$percent_used"
        IS_OVER_BUDGET=true
    elif [ "$percent_used" -ge "$WARN_PERCENT" ]; then
        printf "${YELLOW}WARN${NC}  %s  ~%d / %d tokens (%d%%)\n" "$label" "$estimated_tokens" "$max_tokens" "$percent_used"
    else
        printf "${GREEN}OK${NC}    %s  ~%d / %d tokens (%d%%)\n" "$label" "$estimated_tokens" "$max_tokens" "$percent_used"
    fi
}

echo "Token budget check (chars / ${CHARS_PER_TOKEN})"

check_file "$REPO_ROOT/src/AGENTS.md" "$AGENTS_MAX_TOKENS"

for skill_file in "$REPO_ROOT"/src/skills/*/SKILL.md; do
    [ -f "$skill_file" ] && check_file "$skill_file" "$SKILL_MAX_TOKENS"
done

if $IS_OVER_BUDGET; then
    echo ""
    echo "Over budget. Move detail into a reference.md beside the skill, or cut redundant rules."
    exit 1
fi
