# FlexaVolt MES Starter Kit (Supabase + DigitalOcean)

This repository is a **starter blueprint** for a lightweight MES / assembly + traceability system:

- **Supabase** = Postgres system-of-record + Auth + optional Storage
- **DigitalOcean** server = API gatekeeper + rules engine + integrations (fixtures, printing)
- Optional **Print Agent** running near Zebra/TSC printers

## Key design choices (latest insights)
- **Pattern A (recommended): Serial number is immutable**
  - Units start as generic: `YYMM-GN-00001` (5-wide)
  - Later you assign the unit to a final **variant** (BatSure/PoolTuner/BoilerTuner) without changing SN
- **Variant-driven rules**: packaging/manuals/HW/FW rules are tied to `variant_id`
- **Append-only event log**: every step emits `unit_events`
- **Pack Gate**: packing is blocked unless assignment + test + kit compatibility + policies are satisfied

## What’s included
- `supabase/migrations/001_init.sql` – schema (items, inventory ledger, variants, units, tests, events, kits, print jobs)
- `supabase/migrations/002_functions.sql` – GN serial generator + assign variant + **atomic print-job claim**
- `packages/mes-api` – Fastify TypeScript API
- `packages/print-agent` – polling print agent (replace printing stub)
- `docker-compose.yml` – local dev for API + Redis + print-agent (Supabase remains cloud)
- `.env.example` – copy to `.env` and fill in secrets

## Quick start
1. Create a Supabase project.
2. Run migrations in Supabase SQL editor (in this order):
   - `supabase/migrations/001_init.sql`
   - `supabase/migrations/002_functions.sql`
3. (Optional) Seed minimal example data:
   - `supabase/seed/001_seed_minimal.sql`
4. Copy `.env.example` → `.env` and fill values.
5. Install deps:
   - `npm install`
6. Start API:
   - `npm run dev`
7. (Optional) Run docker compose (API + Redis + print-agent):
   - `docker compose --env-file .env up --build`

## API overview (MVP)
- `POST /units/create-generic`
- `POST /units/:sn/assign-variant`
- `POST /units/:sn/flash`
- `POST /units/:sn/assemble`
- `POST /units/:sn/pack/scan-kit`
- `POST /units/:sn/pack/finalize`  (Pack Gate)
- `POST /units/:sn/move-to-stock`
- `GET  /units/:sn`
- `POST /test-results` (fixture ingest, token protected)

Print jobs:
- `POST /print-jobs`
- `GET  /print-jobs/next?agent_id=AGENT01` (agent claims job atomically via RPC)
- `POST /print-jobs/:id/done|fail`

## Deployment (DigitalOcean)

📖 **See [DEPLOYMENT.md](./DEPLOYMENT.md) for complete deployment instructions.**

Quick deployment options:
- **App Platform** (Recommended): Use `.do/app.yaml` for automated deployment
- **Droplet**: Use `docker-compose.prod.yml` for Docker-based deployment

Key requirements:
- Deploy `packages/mes-api` (Node 20) behind HTTPS
- Keep Supabase service role key server-side only
- Use environment variables for tokens and keys
