-- ============================================================================
-- TYC Partner — admin role + cross-partner access (run AFTER migration.sql)
-- ============================================================================
-- Adds a TYC admin capability on top of the per-partner model:
--   * is_admin() helper (role = 'admin' on the caller's profile)
--   * additive RLS policies letting admins read EVERY partner's data and photos
--   * admins can update intake_items status and profiles.role
-- Permissive policies OR together, so these sit alongside the partner-scoped
-- policies from migration.sql without weakening them for clerks.
-- Safe to re-run.
-- ============================================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role = 'admin' from public.profiles where id = auth.uid()),
    false
  )
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- --- partners: admins read all ---
drop policy if exists partners_admin_select on public.partners;
create policy partners_admin_select on public.partners
  for select to authenticated
  using (public.is_admin());

-- --- profiles: admins read all, and can change roles / reassign ---
drop policy if exists profiles_admin_select on public.profiles;
create policy profiles_admin_select on public.profiles
  for select to authenticated
  using (public.is_admin());

drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- --- intake_items: admins read all + update status (pickup/settle) ---
drop policy if exists intake_items_admin_select on public.intake_items;
create policy intake_items_admin_select on public.intake_items
  for select to authenticated
  using (public.is_admin());

drop policy if exists intake_items_admin_update on public.intake_items;
create policy intake_items_admin_update on public.intake_items
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- --- settlement_batches: admins read all ---
drop policy if exists settlement_batches_admin_select on public.settlement_batches;
create policy settlement_batches_admin_select on public.settlement_batches
  for select to authenticated
  using (public.is_admin());

-- --- storage: admins can view every partner's item photos ---
drop policy if exists item_photos_admin_select on storage.objects;
create policy item_photos_admin_select on storage.objects
  for select to authenticated
  using (bucket_id = 'item-photos' and public.is_admin());


-- ============================================================================
-- Make yourself the first admin (SQL editor)
-- ============================================================================
-- There has to be one admin to start; set it here by user id. This is your
-- clerk login from seed.sql — promoting it just adds the Admin tab in the app.
--
--   update public.profiles
--   set role = 'admin'
--   where id = '6bdb51bb-fb0e-4e63-82ef-f756955ae3cf';
--
-- After that, you can promote/demote anyone else from inside the app's Admin
-- tab (Team section) — no SQL needed.
-- ============================================================================
