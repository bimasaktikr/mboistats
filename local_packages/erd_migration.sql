-- Migration: Transform database from flat TEXT arrays to a normalized ERD
-- Description: Creates master tables for categories and majors, sets up recommendations,
-- normalizes user data into user_all, sets up user interests, and links contents.
-- Note: Old tables are kept for backward compatibility. Safe to run multiple times.

-- Step 1: Create `categories` master table
CREATE TABLE IF NOT EXISTS public.categories (
  id_category SERIAL PRIMARY KEY,
  category TEXT NOT NULL UNIQUE
);

INSERT INTO public.categories (category) VALUES
  ('perekonomian'), ('tenaga_kerja'), ('ipm'),
  ('kemiskinan'), ('kependudukan'), ('pertanian'), ('kesejahteraan')
ON CONFLICT (category) DO NOTHING;

-- Step 2: Create `major` master table and migrate data
CREATE TABLE IF NOT EXISTS public.major (
  id_major SERIAL PRIMARY KEY,
  major TEXT NOT NULL UNIQUE,
  category_id_category INT REFERENCES public.categories(id_category)
);

-- Map all majors + Lainnya + Umum with their first relevant sector
INSERT INTO public.major (major, category_id_category)
SELECT m.major, c.id_category
FROM (VALUES
  ('Teknik Informatika', 'perekonomian'),
  ('Ilmu Komputer', 'perekonomian'),
  ('Sains Data', 'perekonomian'),
  ('Sistem Informasi', 'perekonomian'),
  ('Teknologi Informasi', 'perekonomian'),
  ('Teknik Sipil', 'perekonomian'),
  ('Perencanaan Wilayah & Kota (PWK)', 'perekonomian'),
  ('Teknik Industri', 'perekonomian'),
  ('Teknik Mesin', 'perekonomian'),
  ('Teknik Elektro', 'perekonomian'),
  ('Teknik Kimia', 'perekonomian'),
  ('Teknik Lingkungan', 'perekonomian'),
  ('Ekonomi Pembangunan', 'perekonomian'),
  ('Ilmu Ekonomi', 'perekonomian'),
  ('Manajemen', 'perekonomian'),
  ('Bisnis', 'perekonomian'),
  ('Kewirausahaan', 'perekonomian'),
  ('Akuntansi', 'perekonomian'),
  ('Keuangan', 'perekonomian'),
  ('Statistika', 'perekonomian'),
  ('Matematika', 'perekonomian'),
  ('Fisika', 'ipm'),
  ('Kimia', 'ipm'),
  ('Biologi', 'pertanian'),
  ('Hukum', 'kependudukan'),
  ('Ilmu Administrasi Publik', 'kependudukan'),
  ('Ilmu Administrasi Bisnis', 'perekonomian'),
  ('Ilmu Komunikasi', 'kependudukan'),
  ('Hubungan Internasional', 'perekonomian'),
  ('Sosiologi', 'kemiskinan'),
  ('Psikologi', 'kesejahteraan'),
  ('Antropologi', 'kependudukan'),
  ('Pendidikan / Keguruan', 'ipm'),
  ('Pertanian', 'pertanian'),
  ('Agribisnis', 'pertanian'),
  ('Kehutanan', 'pertanian'),
  ('Peternakan', 'pertanian'),
  ('Kedokteran', 'ipm'),
  ('Kesehatan Masyarakat', 'ipm'),
  ('Farmasi', 'ipm'),
  ('Keperawatan', 'ipm'),
  ('Gizi', 'ipm'),
  ('Pariwisata', 'perekonomian'),
  ('Perhotelan', 'perekonomian'),
  ('Desain Komunikasi Visual (DKV)', 'perekonomian'),
  ('Arsitektur', 'perekonomian'),
  ('Sastra / Bahasa', 'ipm'),
  ('Seni & Kriya', 'perekonomian'),
  ('Lainnya', 'perekonomian'),
  ('Umum', 'perekonomian')
) AS m(major, category)
JOIN public.categories c ON c.category = m.category
ON CONFLICT (major) DO NOTHING;

-- Step 3: Create `major_recommendations` junction table and migrate
CREATE TABLE IF NOT EXISTS public.major_recommendations (
  id SERIAL PRIMARY KEY,
  major_id INT NOT NULL REFERENCES public.major(id_major) ON DELETE CASCADE,
  category_id INT NOT NULL REFERENCES public.categories(id_category) ON DELETE CASCADE,
  UNIQUE(major_id, category_id)
);

INSERT INTO public.major_recommendations (major_id, category_id)
SELECT m.id_major, c.id_category
FROM (VALUES
  ('Teknik Informatika', 'perekonomian'), ('Teknik Informatika', 'tenaga_kerja'),
  ('Ilmu Komputer', 'perekonomian'), ('Ilmu Komputer', 'tenaga_kerja'),
  ('Sains Data', 'perekonomian'), ('Sains Data', 'ipm'), ('Sains Data', 'kemiskinan'),
  ('Sistem Informasi', 'perekonomian'), ('Sistem Informasi', 'tenaga_kerja'),
  ('Teknologi Informasi', 'perekonomian'), ('Teknologi Informasi', 'tenaga_kerja'),
  ('Teknik Sipil', 'perekonomian'), ('Teknik Sipil', 'kependudukan'),
  ('Perencanaan Wilayah & Kota (PWK)', 'perekonomian'), ('Perencanaan Wilayah & Kota (PWK)', 'kependudukan'), ('Perencanaan Wilayah & Kota (PWK)', 'kemiskinan'),
  ('Teknik Industri', 'perekonomian'), ('Teknik Industri', 'tenaga_kerja'),
  ('Teknik Mesin', 'perekonomian'), ('Teknik Mesin', 'tenaga_kerja'),
  ('Teknik Elektro', 'perekonomian'), ('Teknik Elektro', 'tenaga_kerja'),
  ('Teknik Kimia', 'perekonomian'), ('Teknik Kimia', 'tenaga_kerja'),
  ('Teknik Lingkungan', 'perekonomian'), ('Teknik Lingkungan', 'kependudukan'), ('Teknik Lingkungan', 'ipm'),
  ('Ekonomi Pembangunan', 'perekonomian'), ('Ekonomi Pembangunan', 'kemiskinan'), ('Ekonomi Pembangunan', 'kesejahteraan'),
  ('Ilmu Ekonomi', 'perekonomian'), ('Ilmu Ekonomi', 'kemiskinan'), ('Ilmu Ekonomi', 'kesejahteraan'),
  ('Manajemen', 'perekonomian'), ('Manajemen', 'tenaga_kerja'), ('Manajemen', 'kesejahteraan'),
  ('Bisnis', 'perekonomian'), ('Bisnis', 'tenaga_kerja'), ('Bisnis', 'kesejahteraan'),
  ('Kewirausahaan', 'perekonomian'), ('Kewirausahaan', 'tenaga_kerja'),
  ('Akuntansi', 'perekonomian'), ('Akuntansi', 'kesejahteraan'),
  ('Keuangan', 'perekonomian'), ('Keuangan', 'kesejahteraan'),
  ('Statistika', 'perekonomian'), ('Statistika', 'ipm'), ('Statistika', 'kemiskinan'),
  ('Matematika', 'perekonomian'), ('Matematika', 'ipm'),
  ('Fisika', 'ipm'), ('Fisika', 'perekonomian'),
  ('Kimia', 'ipm'), ('Kimia', 'perekonomian'),
  ('Biologi', 'pertanian'), ('Biologi', 'ipm'),
  ('Hukum', 'kependudukan'), ('Hukum', 'kesejahteraan'), ('Hukum', 'kemiskinan'),
  ('Ilmu Administrasi Publik', 'kependudukan'), ('Ilmu Administrasi Publik', 'kesejahteraan'), ('Ilmu Administrasi Publik', 'kemiskinan'),
  ('Ilmu Administrasi Bisnis', 'perekonomian'), ('Ilmu Administrasi Bisnis', 'tenaga_kerja'),
  ('Ilmu Komunikasi', 'kependudukan'), ('Ilmu Komunikasi', 'kesejahteraan'),
  ('Hubungan Internasional', 'perekonomian'), ('Hubungan Internasional', 'kependudukan'),
  ('Sosiologi', 'kemiskinan'), ('Sosiologi', 'kependudukan'), ('Sosiologi', 'kesejahteraan'),
  ('Psikologi', 'kesejahteraan'), ('Psikologi', 'ipm'),
  ('Antropologi', 'kependudukan'), ('Antropologi', 'kemiskinan'), ('Antropologi', 'kesejahteraan'),
  ('Pendidikan / Keguruan', 'ipm'), ('Pendidikan / Keguruan', 'kesejahteraan'),
  ('Pertanian', 'pertanian'), ('Pertanian', 'perekonomian'),
  ('Agribisnis', 'pertanian'), ('Agribisnis', 'perekonomian'),
  ('Kehutanan', 'pertanian'), ('Kehutanan', 'perekonomian'),
  ('Peternakan', 'pertanian'), ('Peternakan', 'perekonomian'),
  ('Kedokteran', 'ipm'), ('Kedokteran', 'kesejahteraan'),
  ('Kesehatan Masyarakat', 'ipm'), ('Kesehatan Masyarakat', 'kesejahteraan'), ('Kesehatan Masyarakat', 'kemiskinan'),
  ('Farmasi', 'ipm'), ('Farmasi', 'kesejahteraan'),
  ('Keperawatan', 'ipm'), ('Keperawatan', 'kesejahteraan'),
  ('Gizi', 'ipm'), ('Gizi', 'kemiskinan'), ('Gizi', 'kesejahteraan'),
  ('Pariwisata', 'perekonomian'), ('Pariwisata', 'kesejahteraan'),
  ('Perhotelan', 'perekonomian'), ('Perhotelan', 'tenaga_kerja'),
  ('Desain Komunikasi Visual (DKV)', 'perekonomian'), ('Desain Komunikasi Visual (DKV)', 'tenaga_kerja'),
  ('Arsitektur', 'perekonomian'), ('Arsitektur', 'kependudukan'),
  ('Sastra / Bahasa', 'ipm'), ('Sastra / Bahasa', 'kependudukan'),
  ('Seni & Kriya', 'perekonomian'), ('Seni & Kriya', 'kesejahteraan'),
  ('Lainnya', 'perekonomian'), ('Lainnya', 'kependudukan'),
  ('Umum', 'perekonomian'), ('Umum', 'kependudukan')
) AS vals(major_name, category_name)
JOIN public.major m ON m.major = vals.major_name
JOIN public.categories c ON c.category = vals.category_name
ON CONFLICT (major_id, category_id) DO NOTHING;

-- Step 4: Create `user_all` table
CREATE TABLE IF NOT EXISTS public.user_all (
  id_user UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  name TEXT,
  phone TEXT,
  type_user TEXT DEFAULT 'umum' CHECK (type_user IN ('mahasiswa', 'umum')),
  institution_id TEXT,     -- Hanya untuk buku tamu
  university_id TEXT,      -- Hanya untuk buku tamu
  education_id TEXT,       -- Hanya untuk buku tamu
  work_id TEXT,            -- Hanya untuk buku tamu
  major_id_major INT REFERENCES public.major(id_major),
  device_id TEXT,          -- Backward compatibility
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_all DISABLE ROW LEVEL SECURITY;

-- Migrate from user_profiles
INSERT INTO public.user_all (email, type_user, major_id_major, device_id, created_at)
SELECT 
  up.device_id AS email,
  CASE WHEN up.major = 'Umum' THEN 'umum' ELSE 'mahasiswa' END AS type_user,
  m.id_major,
  up.device_id,
  up.created_at
FROM public.user_profiles up
LEFT JOIN public.major m ON m.major = up.major
ON CONFLICT (email) DO NOTHING;

-- Step 5: Create `user_interests` junction table and migrate
CREATE TABLE IF NOT EXISTS public.user_interests (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.user_all(id_user) ON DELETE CASCADE,
  category_id INT NOT NULL REFERENCES public.categories(id_category) ON DELETE CASCADE,
  UNIQUE(user_id, category_id)
);

-- Migrate from user_profiles.onboarding_sectors
INSERT INTO public.user_interests (user_id, category_id)
SELECT ua.id_user, cat.id_category
FROM public.user_profiles up
JOIN public.user_all ua ON ua.email = up.device_id
CROSS JOIN LATERAL unnest(up.onboarding_sectors) AS sector_name
JOIN public.categories cat ON cat.category = sector_name
ON CONFLICT (user_id, category_id) DO NOTHING;

-- Step 6: Modify `contents` - add `category_id` FK
ALTER TABLE public.contents ADD COLUMN IF NOT EXISTS category_id INT REFERENCES public.categories(id_category);

-- Backfill from sector_categories[1]
UPDATE public.contents c
SET category_id = cat.id_category
FROM public.categories cat
WHERE LOWER(c.sector_categories[1]) = cat.category
  AND c.category_id IS NULL;

-- Step 7: Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
