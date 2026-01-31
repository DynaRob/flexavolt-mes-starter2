-- FlexaVolt MES Starter - Schema v1 (MVP)
-- Run in Supabase SQL Editor.

-- =========
-- ENUMS
-- =========
create type if not exists public.unit_status as enum (
  'CREATED',
  'FLASHED',
  'TEST_PASS',
  'ASSEMBLED',
  'PACKED',
  'IN_FINISHED_STOCK',
  'REWORK',
  'SCRAPPED'
);

create type if not exists public.event_type as enum (
  'UNIT_CREATED',
  'UNIT_ASSIGNED_TO_VARIANT',
  'FLASH_OK',
  'FLASH_FAIL',
  'TEST_PASS',
  'TEST_FAIL',
  'ASSEMBLY_DONE',
  'PACK_KIT_SCANNED',
  'PACK_FINALIZED',
  'MOVE_TO_STOCK',
  'INVENTORY_MOVE',
  'PRINT_JOB_CREATED',
  'PRINT_JOB_DONE',
  'PRINT_JOB_FAIL'
);

create type if not exists public.item_type as enum (
  'HARDWARE',
  'PACKAGING',
  'MANUAL',
  'SOFTWARE',
  'STICKER',
  'WRAPPER',
  'TEST',
  'LABOUR',
  'FINISHED_GOOD',
  'SUBASSEMBLY'
);

create type if not exists public.inv_move_type as enum (
  'RECEIPT_IN',
  'ISSUE_TO_WIP',
  'CONSUME_TO_BUILD',
  'ADJUSTMENT',
  'TRANSFER',
  'PRODUCE_FINISHED',
  'SCRAP'
);

-- =========
-- MASTER DATA
-- =========
create table if not exists public.suppliers (
  supplier_id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  email text,
  phone text,
  created_at timestamptz not null default now()
);

create table if not exists public.items (
  item_id text primary key, -- SKU_ID
  name text not null,
  description text,
  item_type public.item_type not null,
  uom text not null default 'pcs',
  is_stocked boolean not null default true,
  default_supplier_id uuid references public.suppliers(supplier_id),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.supplier_prices (
  supplier_price_id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.suppliers(supplier_id),
  item_id text not null references public.items(item_id),
  currency text not null,
  unit_price numeric(12,4) not null,
  valid_from date not null,
  created_at timestamptz not null default now()
);

-- =========
-- INVENTORY
-- =========
create table if not exists public.locations (
  location_id uuid primary key default gen_random_uuid(),
  name text not null unique,
  type text not null, -- WAREHOUSE/WIP/STATION/QUARANTINE/FINISHED_GOODS
  created_at timestamptz not null default now()
);

create table if not exists public.inventory_ledger (
  ledger_id uuid primary key default gen_random_uuid(),
  item_id text not null references public.items(item_id),
  location_id uuid not null references public.locations(location_id),
  movement_type public.inv_move_type not null,
  qty numeric(12,3) not null, -- signed
  ref_type text,
  ref_id text,
  unit_cost numeric(12,4),
  created_at timestamptz not null default now(),
  created_by uuid
);

create or replace view public.inventory_on_hand as
select item_id, location_id, sum(qty) as qty_on_hand
from public.inventory_ledger
group by item_id, location_id;

-- =========
-- PRODUCT VARIANTS + RULES
-- =========
create table if not exists public.product_variants (
  variant_id uuid primary key default gen_random_uuid(),
  finished_item_id text not null references public.items(item_id),
  variant_code text not null unique,
  default_language_set text not null default 'EN',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.variant_rules (
  variant_id uuid primary key references public.product_variants(variant_id) on delete cascade,
  allowed_hw_revs jsonb not null default '[]',
  firmware_policy jsonb not null default '{}',
  packaging_policy jsonb not null default '{}',
  manual_policy jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

-- =========
-- PRODUCTION
-- =========
create table if not exists public.production_orders (
  prod_order_id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(variant_id),
  qty_planned integer not null,
  status text not null default 'PLANNED',
  due_date date,
  created_at timestamptz not null default now()
);

create table if not exists public.serialized_units (
  sn text primary key,
  prod_order_id uuid references public.production_orders(prod_order_id),
  variant_id uuid references public.product_variants(variant_id), -- nullable for GN stage

  product_code text not null default 'GN', -- internal code used in SN generation
  serial_class text not null default 'GENERIC', -- GENERIC or FINAL

  assigned_variant_id uuid references public.product_variants(variant_id),
  assigned_product_code text,
  assigned_at timestamptz,
  assigned_by uuid,

  status public.unit_status not null default 'CREATED',
  production_stage text not null default 'CREATED',

  hw_rev_detected text,
  fw_version_detected text,
  fw_build_hash text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.test_runs (
  test_run_id uuid primary key default gen_random_uuid(),
  sn text not null references public.serialized_units(sn) on delete cascade,
  fixture_id text not null,
  result text not null, -- PASS/FAIL
  metrics jsonb not null default '{}',
  fw_readback jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.unit_events (
  event_id uuid primary key default gen_random_uuid(),
  sn text references public.serialized_units(sn) on delete cascade,
  event_type public.event_type not null,
  station_id text,
  operator_id uuid,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- =========
-- PACKAGING KITS
-- =========
create table if not exists public.packaging_kits (
  kit_id text primary key,
  language_set text not null, -- NL-EN etc.
  compatible_variant_codes text[] not null default '{}',
  insert_versions jsonb not null default '{}',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- =========
-- PRINT JOBS
-- =========
create table if not exists public.print_jobs (
  print_job_id uuid primary key default gen_random_uuid(),
  job_type text not null,
  sn text,
  payload jsonb not null default '{}',
  status text not null default 'QUEUED', -- QUEUED/PRINTING/DONE/FAIL
  assigned_agent_id text,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========
-- SEQUENCES (YYMM + product_code)
-- =========
create table if not exists public.serial_sequences (
  yymm text not null,
  product_code text not null,
  next_seq integer not null default 1,
  primary key (yymm, product_code)
);

-- =========
-- RLS (minimal reads)
-- =========
alter table public.serialized_units enable row level security;
alter table public.unit_events enable row level security;
alter table public.test_runs enable row level security;
alter table public.print_jobs enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='serialized_units' and policyname='read_units') then
    create policy "read_units" on public.serialized_units for select to authenticated using (true);
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='unit_events' and policyname='read_events') then
    create policy "read_events" on public.unit_events for select to authenticated using (true);
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='test_runs' and policyname='read_tests') then
    create policy "read_tests" on public.test_runs for select to authenticated using (true);
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='print_jobs' and policyname='read_print_jobs') then
    create policy "read_print_jobs" on public.print_jobs for select to authenticated using (true);
  end if;
end $$;
