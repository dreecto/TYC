-- ============================================================================
-- TYC Partner — seed data + first-login setup
-- ============================================================================
-- Run this AFTER migration.sql. It creates one test partner, then walks you
-- through creating your clerk login and linking it to that partner.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) Test partner
-- ----------------------------------------------------------------------------
-- Fixed UUID so the instructions below can reference it directly.
insert into public.partners (id, name, address, payout_rate, active)
values (
  '11111111-1111-1111-1111-111111111111',
  'Test Golf Shop',
  '123 Fairway Dr, Scottsdale, AZ',
  1.0,
  true
)
on conflict (id) do nothing;


-- ============================================================================
-- 2) Create your clerk login  (Supabase Auth dashboard)
-- ============================================================================
-- Auth users can't be created from the SQL editor, so make the login in the
-- dashboard, then run step 3 to link it.
--
--   a. Supabase dashboard -> Authentication -> Users -> "Add user"
--      -> "Create new user".
--   b. Enter your email + a password.
--   c. Turn ON "Auto Confirm User" (so you can sign in immediately without
--      an email confirmation step).
--   d. Click "Create user".
--   e. Click the new user in the list and copy their User UID
--      (a uuid like 0e6c...). You'll paste it in step 3.
--
-- This email + password is exactly what you'll type into the app's login
-- screen.


-- ============================================================================
-- 3) Link your login to the test partner  (SQL editor)
-- ============================================================================
-- Replace BOTH placeholders below, then run just this statement:
--   * PASTE_AUTH_USER_UID_HERE  -> the User UID copied in step 2e
--   * Your Name                 -> your display name (optional)
--
-- insert into public.profiles (id, partner_id, full_name, role)
-- values (
--   'PASTE_AUTH_USER_UID_HERE',
--   '11111111-1111-1111-1111-111111111111',  -- Test Golf Shop
--   'Your Name',
--   'clerk'
-- );
--
-- Now open the app, sign in with the email/password from step 2, and you'll be
-- scoped to Test Golf Shop's data.


-- ============================================================================
-- Quick verification (optional) — run after step 3
-- ============================================================================
-- Confirms the profile is linked to the partner:
--
-- select p.full_name, p.role, pa.name as partner, pa.payout_rate
-- from public.profiles p
-- join public.partners pa on pa.id = p.partner_id;
-- ============================================================================
