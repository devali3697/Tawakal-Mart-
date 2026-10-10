# Tawakal Mart — local development build

This project has **not been hosted or deployed**. It is an operational local development build, with sample merchandise and test orders clearly separated from a live catalog.

## Run on your Windows PC

Install Node.js 22.13 or newer (Node 24 is recommended), then extract this folder. In PowerShell or the VS Code terminal, inside the folder:

```powershell
npm install
npm run setup:local
npm run dev
```

Open the local URL printed in the terminal, normally **http://localhost:5173**.

- Storefront: `/`
- Admin: `/admin`
- Shopping bag: `/cart`
- Guest checkout: `/checkout`
- Private order lookup: `/track`

`setup:local` applies migrations to a local SQLite database and installs the sample catalog without overwriting existing records. It does not contact a production database or deploy anything. The initial setup may take a few minutes.

### Local administrator sign-in

On `/admin`, click **Sign in to your workspace**. The supplied Sites starter simulates sign-in on loopback development requests as `local_seedy` (`seedy@sites.test`). That local identity is permitted only in a development build. Sign out through the sidebar.

Do not expose the development server to the internet or use it for real customer information. Production builds have no local-admin bypass. When eventually deploying, configure the trusted Sites **ADMIN_USER_ID** binding to the owner's Site-specific user ID. Signing in by itself does not grant administrative permissions.

### Files that persist locally

Products, variants, orders, settings and newsletter signups live in `.wrangler/state`. Uploaded JPG/PNG/WebP images use the local R2 emulator. Keep that folder to preserve local data. It is excluded from this source archive. The included seed can recreate the sample catalog.

Guest cart and wishlist live in your browser's local storage. The order confirmation is in session storage; the order itself remains in the database.

## What is implemented

- Responsive editorial storefront with locally bundled photography, configurable hero campaigns, category tiles, new arrivals, favourites, collection edits, offers and newsletter signup.
- Configurable store name/logo/favicon, announcement, top menu, footer links, homepage section order and visibility, support contacts and social links.
- Catalog search, price/brand/size/colour/availability/category filters, sorting and load-more. Nested categories, collections and brands.
- Product detail, image gallery and zoom, variant selection with separate SKU/price/stock/image, quantity control, size guide, related products, moderated optional reviews.
- Persistent guest cart and wishlist. PKR cash-on-delivery checkout with Pakistan mobile validation, shipping rules, coupon restrictions, date windows and usage caps.
- Database-backed orders and immutable purchase snapshots. Unique order numbers and idempotency keys. Inventory and coupon reservation happen in a single D1 batch with database triggers. Failed stock checks roll back the order and coupon use.
- Protected admin product CRUD, duplicate/archive, multiple image upload, variant editing, CSV import/export and bulk archive.
- Order status workflow, courier/tracking information, private notes, COD collection, printable invoice and packing slip, one-time stock restoration for cancellation and return.
- Real-order customer directory and order history, dashboard metrics, daily sales chart, bestseller report, low-stock alerts, date filters and test-order separation.
- Content/settings management, shipping zones, fixed and percentage coupons, pages/policies, subscriber CSV export, review moderation.
- Public tracking exposes only status, order number, total, dates and courier/tracking reference after a matching mobile number; no delivery address or customer identity is returned.
- Robots rules, sitemap, canonical/OG metadata, product structured data and useful error/404 screens.

## Suggested local walkthrough

1. Open a product, choose a variant, add it to the bag and refresh. The bag should persist.
2. Go to checkout and place a **test order** with a valid-format Pakistani mobile number. No payment is processed and no email is sent.
3. Save the order number. Try `/track` with the matching phone and then an incorrect phone.
4. Sign into `/admin`, open the order, confirm it, then advance the workflow. A cancellation or return restores stock exactly once.
5. Add your own product with uploaded photos and variants; publish it. Check the storefront.
6. Create a coupon, including minimum amount, eligible products/categories, dates and a usage cap. Test it at checkout.
7. Change the announcement, campaign imagery or homepage order; reload the storefront to see the saved change.

## CSV import

Export the catalog from Products first to obtain the exact template. Each CSV row is one variant. Product rows share `product_id`; existing variants keep `variant_id`. Image paths are separated with `|`. CSV supports commas, quotes and multiline descriptions. Imports save one product at a time and report how many saved if a later product fails. Up to 1,000 variant rows per import. Native `.xlsx` import is not implemented; Excel can open and save the CSV format.

## Before a real launch

This build is **not yet production-approved**:

- Browser-based visual and interactive QA was not available in the build environment. Server-rendered routes, APIs, business logic and database invariants were tested; a real desktop/mobile walkthrough remains necessary.
- Use your own actual inventory, specifications, sizes, product photography and reviewed shipping/return/privacy policies. The bundled Unsplash imagery is illustrative, may depict third-party brands and is not a claim that Tawakal stocks them.
- The preview catalog has eight sample products. Live mode excludes all sample products. Add real products and business contacts before changing modes.
- Configure production owner identity, real hosting/database/storage bindings, domain and access settings. The manifest intentionally has no Site project ID.
- Email delivery is **not connected**. Newsletter signups persist and can be exported. Notification settings cannot be enabled until a provider integration is implemented. No fake email confirmations are shown.
- Carrier label booking and real carrier API status sync are not included; courier references and status are managed manually.
- The admin loads the latest 1,000 orders. Larger catalogs/order volumes need paginated admin queries and load testing. Only a single owner role is enabled.
- Scheduled coupons are supported. The offers countdown is presentational; individual product sale prices are edited manually, not automatically scheduled.
- Bestseller ordering uses real, non-cancelled order quantities, with administrator favourites as a fallback when the store has no sales.
- Delivery and support credentials/contacts are not invented. Populate them in settings.

## Architecture

TypeScript, React, Next.js App Router-compatible Vinext, Cloudflare Worker runtime, Drizzle schema, D1 (SQLite) and R2 image storage. This uses Sites-native storage/auth instead of the brief's suggested Supabase stack; no Supabase project was created or modified. Server operations live under `app/api`, shared business validation under `lib`, and owner/storefront UI under `components`.

## Verification commands

```powershell
npm run typecheck
npm test
npm run build
node tests/worker.mjs
```

Optional database-trigger checks if Python is installed:

```powershell
python tests/database.py
```

The Worker integration tests create an isolated, disposable database and storage emulator; they do not alter your local store. These tests cover auth/CSRF, server-rendered routes, database-backed catalog, checkout, idempotency, tracking privacy, order cancellation and newsletter persistence.

## No hosting

No site registration, deployment, public access change or external customer communication was performed for this local build. When you are ready to host, resume from this source; do not overwrite one of your existing stores.
