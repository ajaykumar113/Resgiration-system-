-- ==============================================================================
-- Multi-Registration Form Management System
-- Supabase PostgreSQL Schema & Row Level Security (RLS) Setup
-- ==============================================================================

-- 1. Create the shared registrations table
CREATE TABLE IF NOT EXISTS public.registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id TEXT NOT NULL CHECK (form_id IN (
        'FORM-1', 'FORM-2', 'FORM-3', 'FORM-4', 'FORM-5',
        'FORM-6', 'FORM-7', 'FORM-8', 'FORM-9', 'FORM-10'
    )),
    full_name TEXT NOT NULL CHECK (length(trim(full_name)) > 0),
    email TEXT NOT NULL CHECK (length(trim(email)) > 0),
    phone TEXT NOT NULL CHECK (length(trim(phone)) > 0),
    form_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Create index on form_id, email, and created_at for fast filtering and search
CREATE INDEX IF NOT EXISTS idx_registrations_form_id ON public.registrations(form_id);
CREATE INDEX IF NOT EXISTS idx_registrations_created_at ON public.registrations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_registrations_email ON public.registrations(email);
CREATE INDEX IF NOT EXISTS idx_registrations_full_name ON public.registrations(full_name);

-- 3. Create Admin Users Table
-- Only users listed in this table with active Supabase Auth user IDs have admin dashboard access.
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'admin',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_users_user_id ON public.admin_users(user_id);

-- 4. Enable Row Level Security (RLS) on both tables
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- 5. Drop any existing policies to ensure idempotent runs
DROP POLICY IF EXISTS "Public users can insert registrations" ON public.registrations;
DROP POLICY IF EXISTS "Authorized admins can view all registrations" ON public.registrations;
DROP POLICY IF EXISTS "Authorized admins can delete registrations" ON public.registrations;
DROP POLICY IF EXISTS "Users can check their own admin status" ON public.admin_users;
DROP POLICY IF EXISTS "Admins can view admin list" ON public.admin_users;

-- 6. RLS Policies for `registrations`:
-- (A) PUBLIC INSERT:
-- Anyone (anonymous or authenticated) can submit new registrations,
-- but only with valid form_id, non-empty full_name, email, and phone.
CREATE POLICY "Public users can insert registrations"
ON public.registrations
FOR INSERT
TO anon, authenticated
WITH CHECK (
    form_id IN (
        'FORM-1', 'FORM-2', 'FORM-3', 'FORM-4', 'FORM-5',
        'FORM-6', 'FORM-7', 'FORM-8', 'FORM-9', 'FORM-10'
    )
    AND length(trim(full_name)) > 0
    AND length(trim(email)) > 0
    AND length(trim(phone)) > 0
);

-- (B) ADMIN SELECT ONLY:
-- Anonymous users can NEVER read registration records.
-- Authenticated users can ONLY read registrations if their auth.uid() exists in `admin_users`.
CREATE POLICY "Authorized admins can view all registrations"
ON public.registrations
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE public.admin_users.user_id = auth.uid()
    )
);

-- (C) ADMIN DELETE (optional management feature):
CREATE POLICY "Authorized admins can delete registrations"
ON public.registrations
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE public.admin_users.user_id = auth.uid()
    )
);

-- 7. RLS Policies for `admin_users`:
-- Authenticated users can check if their own user_id is in admin_users
CREATE POLICY "Users can check their own admin status"
ON public.admin_users
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
);

-- ==============================================================================
-- INSTRUCTIONS TO PROMOTE A USER TO ADMIN:
--
-- 1. Sign up a user in the Supabase Dashboard (Authentication -> Users -> Add User)
--    or using the Admin Login form in the app.
-- 2. Find the newly created user's UUID in the Auth Users table.
-- 3. Run the following query in the Supabase SQL Editor:
--
--    INSERT INTO public.admin_users (user_id, email)
--    VALUES ('<PASTE-USER-UUID-HERE>', 'admin@example.com')
--    ON CONFLICT (user_id) DO NOTHING;
-- ==============================================================================
