-- ============================================================================
-- TYC Partner — partner contact fields + TYC HQ (run AFTER migrations 1-3)
-- ============================================================================
-- Adds the contact info captured when an admin creates a partner store, and a
-- "TYC HQ" partner that admin accounts are attached to (profiles.partner_id is
-- NOT NULL, so TYC admins need a home partner). Safe to re-run.
-- ============================================================================

alter table public.partners
  add column if not exists primary_contact text,
  add column if not exists contact_email  text,
  add column if not exists phone           text;

-- Home partner for TYC admin accounts. Fixed id referenced by the
-- admin-create-user Edge Function.
insert into public.partners (id, name, address, payout_rate, active)
values (
  '00000000-0000-0000-0000-000000000001',
  'TYC HQ',
  null,
  1.0,
  true
)
on conflict (id) do nothing;
