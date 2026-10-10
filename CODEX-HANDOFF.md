# Tawakal Mart: deployment handoff

Read START-HERE.md and VERIFICATION.md before making changes. This is the complete local source, not a deployed Site.

## Start

Use Node >=22.13 (24 recommended). Run `npm install`, `npm run setup:local`, then `npm run dev`. Local setup builds the Worker and seeds an isolated local sample database. For reproducible pnpm installs, use the checked-in pnpm lockfile and packageManager version.

## Verification

Run `npm run typecheck`, `npm test`, `python tests/database.py`, `npm run build`, and `node tests/worker.mjs`. Do a desktop/mobile browser walkthrough before launch; visual browser QA has not been completed.

## Hosting requirements

This is a Vinext/Cloudflare Worker application with D1, R2 and Sites-specific ChatGPT authentication. It is not a static HTML export or a standard Vercel Next.js deployment. The `.openai/hosting.json` deliberately has no project_id because ChatGPT Sites registration failed with `site_hosting_usage_limit_reached` (HTTP 429). Moving source to GitHub does not reset that quota.

If deploying through ChatGPT Sites, use its supported registration/source/deployment workflow, persist a successfully returned project ID, configure DB and BUCKET bindings, apply migrations, and set ADMIN_USER_ID to the trusted Site-specific owner identity. Do not overwrite another existing Site.

If deploying outside Sites, explicitly adapt the Sites authentication/runtime integration and provision real D1/R2 bindings before deployment. Do not expose the development login as production authentication. Never rely on a browser-supplied user ID for admin authorization.

## Launch configuration

Keep preview/sample mode until real catalog, photos, contact details, shipping rules and reviewed policies are ready. Email delivery is not integrated. Set production owner identity, test uploads, COD checkout, inventory reservation, order tracking and admin access. No production secrets, customer data, local database, node_modules or generated build output are included in Git; npm install and build regenerate dependencies/output.

All source, bundled imagery, migration history, tests, framework support files and dependency lockfile are included. START-HERE.md documents feature coverage and remaining limitations.
