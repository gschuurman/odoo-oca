#!/usr/bin/env bash
# Smoke test for the image: install all modules on a throwaway PostgreSQL,
# verify they are 'installed', then run the OCA modules' own tests.
# usage: ./smoke-test.sh <image>
set -euo pipefail
IMAGE=${1:?usage: smoke-test.sh <image>}
CORE=base,account,l10n_nl,sale_management,project,hr_timesheet,sale_timesheet,hr_expense
OCA=l10n_nl_tax_statement,l10n_nl_xaf_auditfile_export,account_financial_report,account_asset_management
NET=odoo-smoke-$$
PG=odoo-smoke-pg-$$
cleanup() { docker rm -f "$PG" >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker network create "$NET" >/dev/null
docker run -d --name "$PG" --network "$NET" \
  -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres postgres:16 >/dev/null
until docker exec "$PG" pg_isready -U odoo >/dev/null 2>&1; do sleep 1; done

odoo() { docker run --rm --network "$NET" -e HOST="$PG" -e USER=odoo -e PASSWORD=odoo "$IMAGE" odoo "$@"; }

echo "::group::install all modules"
odoo -d smoke -i "$CORE,$OCA" --load-language=nl_NL --stop-after-init --log-level=warn
echo "::endgroup::"

expected=$(tr ',' '\n' <<<"$CORE,$OCA" | sort)
installed=$(docker exec "$PG" psql -U odoo -d smoke -Atc \
  "SELECT name FROM ir_module_module WHERE state = 'installed'" | sort)
missing=$(comm -23 <(echo "$expected") <(echo "$installed"))
if [ -n "$missing" ]; then
  echo "NOT INSTALLED: $missing" >&2
  exit 1
fi
echo "all $(wc -l <<<"$expected") modules installed"

echo "::group::OCA module tests"
tags=$(sed 's/[^,]*/\/&/g' <<<"$OCA")
log=$(mktemp)
odoo -d smoketest -i "l10n_nl,$OCA" --test-enable --test-tags "$tags" --stop-after-init 2>&1 | tee "$log" | grep -E "odoo\.tests\.(result|stats)|ERROR|FAIL" || true
echo "::endgroup::"
grep -qE "odoo\.tests\.result: 0 failed, 0 error\(s\) of [1-9][0-9]* tests" "$log" || { echo "module tests failed" >&2; exit 1; }
echo "smoke test passed"
