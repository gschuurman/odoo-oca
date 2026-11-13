# syntax=docker/dockerfile:1
# Odoo 20.0 Community + pinned OCA modules for Dutch accounting.
# Every source is pinned: the base image on digest, each OCA repository on a commit SHA.
# Bump a pin in addons.env, open a PR, and CI runs the smoke test.

ARG ODOO_IMAGE=odoo:20.0@sha256:8bcae4c1f895683ee851e19dd3e7d999e81e770defe9015bc9dad8bbf10f2b0d

FROM alpine/git:v2.49.1@sha256:c0280cf9572316299b08544065d3bf35db65043d5e3963982ec50647d2746e26 AS addons
COPY addons.env /addons.env
RUN set -eu; \
    . /addons.env; \
    fetch() { \
      dest="/addons/$1"; mkdir -p "$dest"; \
      git -C "$dest" init -q; \
      git -C "$dest" fetch -q --depth 1 "$2" "$3"; \
      git -C "$dest" checkout -q FETCH_HEAD; \
      test "$(git -C "$dest" rev-parse HEAD)" = "$3"; \
      rm -rf "$dest/.git" "$dest/setup"; \
    }; \
    fetch l10n-netherlands            "$L10N_NETHERLANDS_URL"            "$L10N_NETHERLANDS_SHA"; \
    fetch account-financial-reporting "$ACCOUNT_FINANCIAL_REPORTING_URL" "$ACCOUNT_FINANCIAL_REPORTING_SHA"; \
    fetch account-financial-tools     "$ACCOUNT_FINANCIAL_TOOLS_URL"     "$ACCOUNT_FINANCIAL_TOOLS_SHA"; \
    fetch reporting-engine            "$REPORTING_ENGINE_URL"            "$REPORTING_ENGINE_SHA"; \
    fetch server-ux                   "$SERVER_UX_URL"                   "$SERVER_UX_SHA"

FROM ${ODOO_IMAGE}
LABEL org.opencontainers.image.source="https://github.com/gschuurman/odoo-oca" \
      org.opencontainers.image.description="Odoo 20.0 Community with pinned OCA modules (NL accounting)" \
      org.opencontainers.image.licenses="AGPL-3.0"
COPY --from=addons --chown=root:root /addons /mnt/extra-addons
# Default config without secrets; the cluster mounts its own odoo.conf over this file.
COPY --chown=root:root odoo.conf /etc/odoo/odoo.conf
USER odoo
