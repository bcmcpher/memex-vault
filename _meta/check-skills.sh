#!/usr/bin/env bash
# check-skills.sh — static checks on skills/*/SKILL.md that no fixture can see.
#
# A skill body is not run as written. The skill loader substitutes positional
# parameters — `$0`…`$9` and `$ARGUMENTS`, braced or not — with the invocation's
# arguments before any shell or awk sees the text, even inside code fences. So
# `awk '{print $2}'` arrives as `awk '{print <second word>}'`, and `"$1"` as the
# operator's first word. Trial 2 lost memex-seed's manifest reader and
# memex-tend's step-1 awk this way (T2-2, T2-4); nothing failed loudly, the
# commands just computed something else.
#
# Checks:
#   1. No positional parameter anywhere in a SKILL.md.
#   2. No bundled schema digest, and no pointer to one. rc.2 shipped fifteen
#      `skills/*/references/vault-schema.md` copies that had drifted from
#      `_meta/schema.md` and lacked the decision tree three skills sent readers
#      to (T2-24, T2-35). Skills read `$VAULT/_meta/schema.md`; a copy is a
#      second truth that goes stale silently.
#
# Usage:
#   bash _meta/check-skills.sh
# Exit 0 clean, 1 on any finding, 2 on a usage error.

set -uo pipefail

VAULT="$(cd "$(dirname "$0")/.." && pwd)"

for arg in "$@"; do
    echo "unknown argument: $arg" >&2; exit 2
done

[ -d "$VAULT/skills" ] || { echo "no skills/ at $VAULT" >&2; exit 2; }

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
fail=0

report() {  # name, grep output
    if [ -n "$2" ]; then
        echo "${RED}FAIL${NC}  $1"
        printf '%s\n' "$2" | sed -e "s#^$VAULT/##" -e 's/^/        /'
        fail=$((fail + 1))
    else
        echo "${GREEN}PASS${NC}  $1"
    fi
}

# 1. Positional parameters. `$$`, `$?`, `$#` and named variables are untouched by
#    the loader and stay legal.
hits=$(grep -nE '\$\{?([0-9]|ARGUMENTS)' "$VAULT"/skills/*/SKILL.md || true)
report "no positional parameters in skills/*/SKILL.md" "$hits"

# 2. Schema digests.
hits=$( { find "$VAULT/skills" -name vault-schema.md
          grep -rn 'references/vault-schema' "$VAULT/skills" "$VAULT/README.md" 2>/dev/null; } || true)
report "no bundled schema digests in skills/" "$hits"

echo ""
if [ "$fail" -gt 0 ]; then
    echo "${RED}$fail check(s) failed.${NC}"
    exit 1
fi
echo "${GREEN}All checks passed.${NC}"
