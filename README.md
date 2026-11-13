# odoo-oca

Odoo 20.0 Community image with pinned OCA modules for Dutch bookkeeping.
Built and smoke-tested by GitHub Actions, published to `ghcr.io/gschuurman/odoo-oca`.

| Module | Source |
|---|---|
| `l10n_nl_tax_statement` | fork `gschuurman/l10n-netherlands`, own 20.0 migration (from 19.0) |
| `l10n_nl_xaf_auditfile_export` | fork `gschuurman/l10n-netherlands`, own 20.0 migration (from 18.0) |
| `account_financial_report` | fork `gschuurman/account-financial-reporting`, own 20.0 migration (from 19.0) |
| `account_asset_management` | fork `gschuurman/account-financial-tools`, own 20.0 migration (from 19.0) |
| `report_xlsx_helper` | fork `gschuurman/reporting-engine`, own 20.0 migration (from 19.0) |
| `report_xlsx` | `OCA/reporting-engine` 20.0 (via the fork) |
| `date_range` | `OCA/server-ux` 20.0 |

On 13-11-2026 none of the modules above were released for 20.0 upstream and no
migration PRs were open (see OCA/l10n-netherlands#460). The migrations live on
`20.0-mig-<module>` branches in the forks; `l10n-netherlands` has an extra
`20.0-odoo-oca` branch that merges both NL modules. Once a module is released
upstream on 20.0, point its pin back to OCA.

## Pins

- Base image: `odoo:20.0` on digest, in `Dockerfile`.
- OCA repositories: full commit SHAs in `addons.env`. The build fails if the fetched commit differs.

Tags are `20.0-<yyyymmdd>-<short sha>`; there is no `latest`.

## Smoke test

`./smoke-test.sh <image>` starts a throwaway PostgreSQL, installs all modules
with `nl_NL` loaded, checks `ir_module_module` for `installed`, and runs the OCA
modules' own tests. CI runs it for every PR and before every push.

## Notable 20.0 changes handled in the migrations

- `ir.model.access` + `ir.rule` are merged into `ir.access` (`security/ir.access.csv`).
- `account.group` is gone; the trial balance hierarchy uses parent accounts.
- QWeb `t-esc` renders nothing; use `t-out`.
- `res.company.company_registry` is gone; the KvK number is the partner identifier `NL_KVK`.
- `ir.actions.report.report_file` and `odoo.models.PREFETCH_MAX` were removed.
- Binary fields return a `BinaryValue` (`.content`) instead of base64.
- `without_demo` is a boolean since 19.0 (`all` is no longer valid).

License: AGPL-3.0, like the OCA modules.
