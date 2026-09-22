# Hejly Phase 1

Source base: `9ae63601ce81cb11b0e5b0e69fa169ca2a6622f6`.
Branch: `hejly/phase-1-branding`. No newer upstream commits are included.

## Scope and pending logos

The operational runner configures only `INSTALLATION_NAME=Hejly`,
`BRAND_NAME=Hejly`, `BRAND_URL=https://gethejly.com` and
`WIDGET_BRAND_URL=https://gethejly.com`. No application logic or YAML defaults change.
These shared values also affect existing email branding and widget attribution;
no templates, widget behavior or premium flags are changed.

**Logo replacement is pending.** No approved Hejly SVG assets were available locally.
The current Chatwoot files remain unchanged. Future replacements are limited to:

- `public/brand-assets/logo.svg`
- `public/brand-assets/logo_dark.svg`
- `public/brand-assets/logo_thumbnail.svg`

No favicon matrix, manifest, onboarding text or documentation links are changed.
This phase does not remove every Chatwoot reference.

## Build without publishing

After review and separate approval to commit/push, make the manual
`Build Hejly Community Edition` workflow available in GitHub Actions. GitHub requires
`workflow_dispatch` workflows to exist on the default branch before they can be
triggered. Select the reviewed Phase 1 ref; no automatic trigger is configured.
Keep upstream publishing workflows disabled in the fork's Actions settings.

The workflow builds the selected commit, not a floating upstream ref. In its disposable
checkout it removes `enterprise/` and `spec/enterprise/` and appends `CW_EDITION=ce`
to the Dockerfile, matching upstream's FOSS preparation. Tracked source files remain
unchanged. The edition marker alone does not disable Enterprise code.

Native amd64 and arm64 jobs use the existing Dockerfile with `context: .`, preserving
Git metadata for `.git_sha`. Each loads and validates its image locally on the runner.
There is no registry login, registry push, combined manifest or deployment.

Validation checks the CE marker, absence of Enterprise directories, source SHA,
three existing logo files, runner Ruby syntax and `ChatwootApp.enterprise?` without
booting Rails or connecting to a database. These checks do not prove Rails startup,
database compatibility or branding behavior.

Each job uploads a compressed Docker image artifact retained for three days. Download
the artifact matching the staging host architecture, extract the artifact ZIP, then:

```sh
docker load --input hejly-ce-amd64.tar.gz
```

Use `hejly-ce-arm64.tar.gz` on arm64. The loaded tag is
`hejly/chatwoot:sha-<full-commit>-ce-<architecture>`. Record the workflow commit and image
ID. Both Rails and Sidekiq must use that same image. No production configuration is
changed by this workflow.

## Apply and verify in staging first

Use an isolated staging database, Redis and storage, with production delivery and
external integrations disabled. Identify production's exact image version before
planning any migration; `chatwoot/chatwoot:latest` is not proof of a pure CE image.
Back up database and storage before any later production migration.

1. Configure staging to use the built CE image. Complete normal database preparation
   with `bundle exec rails db:chatwoot_prepare`; this runner does not prepare schemas.
2. Record the existing values of the four branding keys for rollback. Verify that
   `LOGO`, `LOGO_DARK` and `LOGO_THUMBNAIL` point to their default `/brand-assets/` paths.
   If they differ, investigate rather than adding more writes to this script.
3. Explicitly run inside the configured staging container:

   ```sh
   bundle exec rails runner script/hejly/configure_branding.rb
   ```

   It refuses an image containing Enterprise code, requires all four existing records,
   saves only changed values in one transaction, and preserves their `locked` flags.
   Missing records mean normal database preparation must be completed first.
   Normal model saves invoke the existing configuration-cache invalidation callbacks.
4. Run the command again. Verify the same four values and unchanged `updated_at`
   timestamps on the second run, with no changes to unrelated configuration records.
5. Check Rails and Sidekiq startup and the dashboard/login name in a fresh browser
   session. The logos remain Chatwoot until approved assets are supplied and rebuilt.
   After replacement, check light, dark and compact logos; favicon work remains deferred.

The values live in the database and survive container replacement. Run the script
explicitly after upgrades when verification or reapplication is needed, never as an
unconditional startup hook. These are internal upstream settings, so verify them on
future upgrades. For rollback, restore the four recorded values using normal
`InstallationConfig` model saves. Image rollback alone does not revert configuration
or schema changes.

## Review gate

Local static checks do not replace a successful workflow build or staging validation.
Registry publication, production configuration, database migration and deployment
require separate approval. No production branding command has been run by adding
these files.
