-- ============================================================================
-- TYC Partner — database schema, RLS policies, and storage setup
-- ============================================================================
-- Paste this entire file into the Supabase SQL editor and run it once.
--
-- Model: every user belongs to exactly one partner (store). All partner data
-- (intake items, settlement batches, photos) is scoped so a user can only ever
-- read or write rows belonging to THEIR partner. Scoping is enforced by Row
-- Level Security on every table plus matching storage policies.
--
-- Safe to re-run: uses IF NOT EXISTS / DROP POLICY IF EXISTS throughout.
-- ============================================================================

create extension if not exists "pgcrypto";  -- for gen_random_uuid()

-- ----------------------------------------------------------------------------
-- Tables
-- ----------------------------------------------------------------------------

-- Partners (stores). One row per retail store TradeYourClubs works with.
create table if not exists public.partners (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  address     text,
  payout_rate numeric not null default 1.0,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- Profiles. One row per app user, linked to auth.users and to a partner.
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  partner_id uuid not null references public.partners (id) on delete restrict,
  full_name  text,
  role       text not null default 'clerk',
  created_at timestamptz not null default now()
);

create index if not exists profiles_partner_id_idx
  on public.profiles (partner_id);

-- Intake items. A single traded-in golf club (or other item).
create table if not exists public.intake_items (
  id                  uuid primary key default gen_random_uuid(),
  partner_id          uuid not null references public.partners (id) on delete restrict,
  created_by          uuid references auth.users (id) on delete set null,
  brand               text,
  model               text,
  category            text not null default 'other'
                        check (category in (
                          'driver', 'fairway', 'hybrid', 'iron_set',
                          'wedge', 'putter', 'other'
                        )),
  specs               jsonb not null default '{}'::jsonb,
  condition           text
                        check (condition in ('like_new', 'good', 'fair')),
  pga_value           numeric,
  offer_value         numeric,
  status              text not null default 'accepted'
                        check (status in ('accepted', 'picked_up', 'settled')),
  customer_accepted_at timestamptz,
  -- FK to settlement_batches added below, once that table exists.
  batch_id            uuid,
  created_at          timestamptz not null default now()
);

-- Settlement batches. Groups items TradeYourClubs picks up / pays for.
create table if not exists public.settlement_batches (
  id         uuid primary key default gen_random_uuid(),
  partner_id uuid not null references public.partners (id) on delete restrict,
  status     text not null default 'open'
               check (status in ('open', 'picked_up', 'paid')),
  total      numeric not null default 0,
  paid_at    timestamptz,
  created_at timestamptz not null default now()
);

-- intake_items.batch_id references settlement_batches, which is declared after
-- intake_items above. Add the FK now that both tables exist.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'intake_items_batch_id_fkey'
  ) then
    alter table public.intake_items
      add constraint intake_items_batch_id_fkey
      foreign key (batch_id)
      references public.settlement_batches (id)
      on delete set null;
  end if;
end$$;

create index if not exists intake_items_partner_id_idx
  on public.intake_items (partner_id);
create index if not exists intake_items_batch_id_idx
  on public.intake_items (batch_id);
create index if not exists settlement_batches_partner_id_idx
  on public.settlement_batches (partner_id);

-- ----------------------------------------------------------------------------
-- Helper: the partner_id of the currently authenticated user.
-- ----------------------------------------------------------------------------
-- SECURITY DEFINER so it can read profiles without tripping RLS recursion
-- (policies on profiles below call this function).
create or replace function public.current_partner_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select partner_id from public.profiles where id = auth.uid()
$$;

revoke all on function public.current_partner_id() from public;
grant execute on function public.current_partner_id() to authenticated;

-- ----------------------------------------------------------------------------
-- Row Level Security — explicitly enabled on EVERY table.
-- ----------------------------------------------------------------------------
alter table public.partners           enable row level security;
alter table public.profiles           enable row level security;
alter table public.intake_items       enable row level security;
alter table public.settlement_batches enable row level security;

-- --- partners: read-only for members of that partner ---
drop policy if exists partners_select on public.partners;
create policy partners_select on public.partners
  for select to authenticated
  using (id = public.current_partner_id());

-- --- profiles ---
-- A user can always read their own profile, plus any profile in their partner.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated
  using (
    id = auth.uid()
    or partner_id = public.current_partner_id()
  );

-- A user may update only their own profile, and may not move partners or
-- escalate the partner link.
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and partner_id = public.current_partner_id());

-- --- intake_items: full CRUD scoped to the user's partner ---
drop policy if exists intake_items_select on public.intake_items;
create policy intake_items_select on public.intake_items
  for select to authenticated
  using (partner_id = public.current_partner_id());

drop policy if exists intake_items_insert on public.intake_items;
create policy intake_items_insert on public.intake_items
  for insert to authenticated
  with check (
    partner_id = public.current_partner_id()
    and created_by = auth.uid()
  );

drop policy if exists intake_items_update on public.intake_items;
create policy intake_items_update on public.intake_items
  for update to authenticated
  using (partner_id = public.current_partner_id())
  with check (partner_id = public.current_partner_id());

drop policy if exists intake_items_delete on public.intake_items;
create policy intake_items_delete on public.intake_items
  for delete to authenticated
  using (partner_id = public.current_partner_id());

-- --- settlement_batches: full CRUD scoped to the user's partner ---
drop policy if exists settlement_batches_select on public.settlement_batches;
create policy settlement_batches_select on public.settlement_batches
  for select to authenticated
  using (partner_id = public.current_partner_id());

drop policy if exists settlement_batches_insert on public.settlement_batches;
create policy settlement_batches_insert on public.settlement_batches
  for insert to authenticated
  with check (partner_id = public.current_partner_id());

drop policy if exists settlement_batches_update on public.settlement_batches;
create policy settlement_batches_update on public.settlement_batches
  for update to authenticated
  using (partner_id = public.current_partner_id())
  with check (partner_id = public.current_partner_id());

drop policy if exists settlement_batches_delete on public.settlement_batches;
create policy settlement_batches_delete on public.settlement_batches
  for delete to authenticated
  using (partner_id = public.current_partner_id());

-- ----------------------------------------------------------------------------
-- Storage: item-photos bucket, path {partner_id}/{item_id}/{n}.jpg
-- ----------------------------------------------------------------------------
-- Private bucket. Access is granted only via the policies below.
insert into storage.buckets (id, name, public)
values ('item-photos', 'item-photos', false)
on conflict (id) do nothing;

-- The first folder segment of the object path is the partner_id. Scope every
-- operation to objects whose first segment matches the user's partner_id.
drop policy if exists item_photos_select on storage.objects;
create policy item_photos_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'item-photos'
    and (storage.foldername(name))[1] = public.current_partner_id()::text
  );

drop policy if exists item_photos_insert on storage.objects;
create policy item_photos_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'item-photos'
    and (storage.foldername(name))[1] = public.current_partner_id()::text
  );

drop policy if exists item_photos_update on storage.objects;
create policy item_photos_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'item-photos'
    and (storage.foldername(name))[1] = public.current_partner_id()::text
  )
  with check (
    bucket_id = 'item-photos'
    and (storage.foldername(name))[1] = public.current_partner_id()::text
  );

drop policy if exists item_photos_delete on storage.objects;
create policy item_photos_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'item-photos'
    and (storage.foldername(name))[1] = public.current_partner_id()::text
  );

-- ============================================================================
-- Done. Next: run supabase/seed.sql to create the test partner, then follow
-- its instructions to create your clerk login and link the profiles row.
-- ============================================================================
