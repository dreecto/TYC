-- ============================================================================
-- TYC Partner — group multiple items into one customer visit
-- ============================================================================
-- Run AFTER migration.sql and migration2_admin.sql.
--
-- A customer can trade in several clubs at once. Each club is still its own
-- intake_items row (its own photos, condition, PGA value, and offer), but they
-- share a visit_id and one customer signature + acceptance timestamp.
--
-- No RLS changes needed: visit_id is just another column on intake_items,
-- already protected by the existing partner-scoped and admin policies.
-- Safe to re-run.
-- ============================================================================

alter table public.intake_items
  add column if not exists visit_id uuid;

create index if not exists intake_items_visit_id_idx
  on public.intake_items (visit_id);
