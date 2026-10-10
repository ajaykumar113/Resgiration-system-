# Multi-Registration Form Management System

A production-ready Multi-Registration Form Management System built with **React**, **TypeScript**, **Tailwind CSS**, and **Supabase PostgreSQL**.

---

## 🌟 Features Overview

- **Home Page with 10 Distinct Registration Cards**:
  - Exactly named: `Registration Form 1` through `Registration Form 10`.
  - Unique Form IDs: `FORM-1` to `FORM-10`.
  - Short descriptions, badges, custom category tags, and responsive action triggers.
- **Ten Tailored Registration Forms**:
  - Standard required fields: **Full Name**, **Email**, **Phone Number**, **Address**, **Date of Birth**.
  - Form-specific specialized metadata fields (e.g. conference track, corporate position, university department, patient blood group/allergies, team size, cloud workloads, alumni chapters, etc.).
  - Real-time client-side validation, error banners, submission spinners.
  - Accidental repeated submission prevention (button disabled while submitting, debounce, confirmation modals).
- **Single Supabase PostgreSQL Table (`public.registrations`)**:
  - `id`: UUID Primary Key (`gen_random_uuid()`)
  - `form_id`: Text with check constraint (`'FORM-1'` to `'FORM-10'`)
  - `full_name`: Text
  - `email`: Text
  - `phone`: Text
  - `form_data`: JSONB for extensible form-specific metadata
  - `created_at`: TIMESTAMPTZ
- **Strict Row Level Security (RLS)**:
  - **Public Insert**: Anonymous and authenticated users can insert records into `registrations`.
  - **Admin Read Only**: Anonymous users can **never** read registration records. Authenticated users can only read records if their user ID is listed in `public.admin_users`.
  - **Never exposes the Supabase service-role key**.
- **Admin Management Portal (`/admin`)**:
  - Supabase Auth email/password login.
  - Metrics cards: Total Submissions, Today's Submissions, Active Form Count, RLS Status.
  - Filter by Form ID (`ALL` or `FORM-1` to `FORM-10`).
  - Search by Name, Email, or Phone.
  - Sort by Newest or Oldest.
  - View full JSONB details modal.
  - RFC 4180-compliant **CSV Export**.

---

## 🚀 Quickstart & Setup Guide

### 1. Install Dependencies

Ensure Node.js (v18+ or v20+) is installed, then run:

```bash
npm install
```

---

### 2. Configure Supabase Environment Variables

1. Go to [supabase.com](https://supabase.com) and create a free project.
2. In your Supabase Dashboard, navigate to **Project Settings → API**.
3. Copy your **Project URL** and **anon / public key**.
4. In the root directory of this project, open `.env` (or copy `.env.example` to `.env`):

```env
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### 3. Run the SQL Migration in Supabase

1. Open your Supabase project dashboard.
2. In the left navigation, click on **SQL Editor**.
3. Click **New Query**.
4. Paste the contents of `supabase/schema.sql` (or copy below):

```sql
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

-- 2. Performance indexes
CREATE INDEX IF NOT EXISTS idx_registrations_form_id ON public.registrations(form_id);
CREATE INDEX IF NOT EXISTS idx_registrations_created_at ON public.registrations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_registrations_email ON public.registrations(email);
CREATE INDEX IF NOT EXISTS idx_registrations_full_name ON public.registrations(full_name);

-- 3. Create Admin Users Table
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'admin',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- 5. Drop old policies if any
DROP POLICY IF EXISTS "Public users can insert registrations" ON public.registrations;
DROP POLICY IF EXISTS "Authorized admins can view all registrations" ON public.registrations;
DROP POLICY IF EXISTS "Authorized admins can delete registrations" ON public.registrations;
DROP POLICY IF EXISTS "Users can check their own admin status" ON public.admin_users;

-- 6. Insert policy for public users
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

-- 7. Select policy for authorized admins only
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

-- 8. Delete policy for authorized admins
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

-- 9. Self admin status check
CREATE POLICY "Users can check their own admin status"
ON public.admin_users
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
);
```
5. Click **Run** to execute the migration.

---

### 4. Configure an Authorized Administrator

1. In Supabase Dashboard, go to **Authentication → Users** and click **Add user** (or sign up via the app's Admin Portal).
2. Note the user's `UUID` from the Auth Users list.
3. Open the **SQL Editor** in Supabase and run:

```sql
INSERT INTO public.admin_users (user_id, email)
VALUES ('<REPLACE_WITH_AUTH_USER_UUID>', 'admin@yourdomain.com')
ON CONFLICT (user_id) DO NOTHING;
```

Now this user has authorized admin status to query all submissions and export CSV data!

---

### 5. Run the Application Locally

Start the local development server:

```bash
npm run dev
```

Open your browser to:
```
http://localhost:5173
```

---

### 6. Testing the 10 Forms and Verifying Database Records

1. From the Home Page, click **Register Now** on **Registration Form 1**.
2. Complete the form and submit.
3. Verify the success modal displays the generated UUID.
4. Test multiple forms (`Registration Form 2` through `Registration Form 10`).
5. In Supabase Dashboard, go to **Table Editor → registrations** to inspect the live inserted rows.
6. Navigate to `http://localhost:5173/#admin` (or click **Admin Portal** in the navbar).
7. Sign in with your admin credentials to filter, search, view full JSON records, and export CSV.

---

### 7. Build and Publish the Website

To create an optimized production build:

```bash
npm run build
```

The compiled assets will be output to the `dist/` folder, ready for deployment to:
- **Vercel**: Import repository, set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in Environment Variables.
- **Netlify**: Deploy `dist/` directory, configure environment variables.
- **Cloudflare Pages**: Framework preset `Vite`, build command `npm run build`, output directory `dist`.
