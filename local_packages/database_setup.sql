-- 1. Tabel Profil Perangkat (Device Profiles)
CREATE TABLE IF NOT EXISTS public.device_profiles (
  device_id TEXT PRIMARY KEY,
  major TEXT NOT NULL,                         -- Jurusan yang dipilih saat onboarding
  onboarding_sectors TEXT[] DEFAULT '{}',      -- Sektor pilihan manual / pre-selected
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabel Pemetaan Jurusan ke Sektor Relevan (Smart Default)
CREATE TABLE IF NOT EXISTS public.major_sector_mapping (
  major_name TEXT PRIMARY KEY,
  relevant_sectors TEXT[] NOT NULL
);

-- Isi Data Default Pemetaan Jurusan ke Sektor
INSERT INTO public.major_sector_mapping (major_name, relevant_sectors) VALUES
('Teknik Informatika', ARRAY['perekonomian', 'tenaga_kerja']),
('Sistem Informasi', ARRAY['perekonomian', 'tenaga_kerja']),
('Teknik Sipil', ARRAY['perekonomian']),
('Ekonomi', ARRAY['perekonomian', 'kemiskinan']),
('Akuntansi', ARRAY['perekonomian', 'kesejahteraan']),
('Ilmu Komunikasi', ARRAY['kependudukan', 'kesejahteraan']),
('Pendidikan', ARRAY['ipm']),
('Pertanian', ARRAY['pertanian', 'perekonomian'])
ON CONFLICT (major_name) DO UPDATE 
SET relevant_sectors = EXCLUDED.relevant_sectors;

-- Penyesuaian Kolom Baru (Cover & Content) di tabel activity_logs
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS cover_url TEXT;
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS content_url TEXT;

-- Nonaktifkan RLS (Row Level Security) agar log perangkat & preferensi dapat disimpan secara publik tanpa sesi Auth/SSO
ALTER TABLE public.device_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs DISABLE ROW LEVEL SECURITY;

-- 3. Fungsi PostgreSQL RPC untuk Menghitung Skor & Rekomendasi Konten (Deduplicated & Cover Aggr)
CREATE OR REPLACE FUNCTION get_personalized_recommendations_by_device(
  input_device_id TEXT,
  rec_limit INT DEFAULT 10
)
RETURNS TABLE (
  content_id TEXT,
  content_title TEXT,
  sector_category TEXT,
  content_type TEXT,
  cover_url TEXT,
  content_url TEXT,
  final_score NUMERIC
) AS $$
DECLARE
  total_interactions INT;
  w_explicit NUMERIC := 0.5;
  w_freq NUMERIC := 0.3;
  w_recency NUMERIC := 0.2;
BEGIN
  -- A. Hitung total interaksi perangkat dalam 30 hari terakhir
  SELECT COUNT(*) INTO total_interactions
  FROM public.activity_logs
  WHERE device_id = input_device_id
    AND created_at >= NOW() - INTERVAL '30 days';

  -- B. Tentukan bobot berdasarkan tahapan interaksi (Warm-Up Phase)
  IF total_interactions = 0 THEN
    w_explicit := 1.0; w_freq := 0.0; w_recency := 0.0;
  ELSIF total_interactions < 10 THEN
    w_explicit := 0.7; w_freq := 0.2; w_recency := 0.1;
  ELSE
    w_explicit := 0.3; w_freq := 0.4; w_recency := 0.3;
  END IF;

  -- C. Hitung skor rekomendasi per item konten
  RETURN QUERY
  WITH user_clicks AS (
    SELECT 
      a.sector_category AS sector,
      COUNT(*)::NUMERIC AS click_count,
      MAX(a.created_at) AS last_click_time
    FROM public.activity_logs a
    WHERE a.device_id = input_device_id
      AND a.created_at >= NOW() - INTERVAL '30 days'
    GROUP BY a.sector_category
  ),
  max_click AS (
    SELECT COALESCE(MAX(click_count), 1.0) AS max_val FROM user_clicks
  ),
  sector_scores AS (
    SELECT 
      s.sector_name,
      CASE WHEN s.sector_name = ANY(dp.onboarding_sectors) THEN 1.0 ELSE 0.0 END AS score_explicit,
      COALESCE(uc.click_count / mc.max_val, 0.0) AS score_freq,
      COALESCE(EXP(-0.05 * EXTRACT(DAY FROM NOW() - uc.last_click_time)), 0.0) AS score_recency
    FROM 
      (SELECT DISTINCT a.sector_category AS sector_name FROM public.activity_logs a) s
      LEFT JOIN public.device_profiles dp ON dp.device_id = input_device_id
      LEFT JOIN user_clicks uc ON uc.sector = s.sector_name
      CROSS JOIN max_click mc
  )
  SELECT 
    MIN(a.id)::TEXT AS content_id,
    a.item_name AS content_title,
    a.sector_category,
    a.action_type AS content_type,
    MAX(a.cover_url) AS cover_url,
    MAX(a.content_url) AS content_url,
    (
      0.7 * (w_explicit * ss.score_explicit + w_freq * ss.score_freq + w_recency * ss.score_recency)
      +
      0.3 * GREATEST(0.0, 1.0 - (EXTRACT(DAY FROM NOW() - MAX(a.created_at)) / 90.0))
    )::NUMERIC AS final_score
  FROM 
    public.activity_logs a
    JOIN sector_scores ss ON a.sector_category = ss.sector_name
  WHERE 
    a.action_type IN ('view_pdf', 'download_file')
  GROUP BY 
    a.item_name, a.sector_category, a.action_type,
    ss.score_explicit, ss.score_freq, ss.score_recency
  ORDER BY 
    final_score DESC, MAX(a.created_at) DESC
  LIMIT rec_limit;
END;
$$ LANGUAGE plpgsql;

-- Memaksa reload schema cache Postgrest agar perubahan fungsi terdeteksi di SDK
COMMENT ON TABLE public.activity_logs IS 'Tabel aktivitas Mboisstats v3';
NOTIFY pgrst, 'reload schema';
