-- ====================================================================
-- SCRIPT SUPABASE: RESET DATA & UPDATE FUNGSI SCORING 7 SEKTOR
-- ====================================================================

-- 1. FUNGSI HITUNG SKOR SEKTOR PER DEVICE / USER (HANYA 7 SEKTOR STATISTIK)
CREATE OR REPLACE FUNCTION get_sector_scores_for_device(input_device_id TEXT)
RETURNS TABLE (
  sector_name TEXT,
  score NUMERIC
) AS $$
DECLARE
  total_interactions INT;
  w_explicit NUMERIC := 0.3;
  w_freq NUMERIC := 0.4;
  w_recency NUMERIC := 0.3;
BEGIN
  -- Hitung HANYA interaksi yang termasuk ke dalam 7 sektor statistik
  SELECT COUNT(*) INTO total_interactions
  FROM public.activity_logs a
  WHERE (a.user_id = input_device_id OR a.device_id = input_device_id)
    AND a.created_at >= NOW() - INTERVAL '30 days'
    AND (
      LOWER(a.sector_category) IN ('tenaga_kerja', 'ketenagakerjaan', 'ipm', 'perekonomian', 'ekonomi', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan')
      OR a.sector_category ILIKE '%tenaga%'
      OR a.sector_category ILIKE '%kerja%'
      OR a.sector_category ILIKE '%ekonomi%'
      OR a.sector_category ILIKE '%perekonomian%'
      OR a.sector_category ILIKE '%ipm%'
      OR a.sector_category ILIKE '%kemiskinan%'
      OR a.sector_category ILIKE '%kependudukan%'
      OR a.sector_category ILIKE '%pertanian%'
      OR a.sector_category ILIKE '%kesejahteraan%'
    )
    AND a.action_type NOT IN ('login_success', 'click_login_google', 'delete_account', 'logout')
    AND a.item_name NOT IN ('Halaman Login', 'Halaman Profil', 'Masuk dengan Google', 'Masuk dengan Google (Native)', 'Login Google Sukses', 'Login Google Native Sukses', 'Hapus Akun', 'Logout');

  -- Penentuan Bobot 3 Fase (Cold-Start, Warm-Up, Established)
  IF total_interactions = 0 THEN
    w_explicit := 1.0; w_freq := 0.0; w_recency := 0.0;
  ELSIF total_interactions < 10 THEN
    w_explicit := 0.7; w_freq := 0.2; w_recency := 0.1;
  ELSE
    w_explicit := 0.3; w_freq := 0.4; w_recency := 0.3;
  END IF;

  RETURN QUERY
  WITH user_clicks AS (
    SELECT 
      LOWER(
        CASE 
          WHEN a.sector_category ILIKE '%tenaga%' OR a.sector_category ILIKE '%kerja%' THEN 'tenaga_kerja'
          WHEN a.sector_category ILIKE '%ekonomi%' OR a.sector_category ILIKE '%perekonomian%' THEN 'perekonomian'
          WHEN a.sector_category ILIKE '%ipm%' THEN 'ipm'
          WHEN a.sector_category ILIKE '%kemiskinan%' THEN 'kemiskinan'
          WHEN a.sector_category ILIKE '%kependudukan%' THEN 'kependudukan'
          WHEN a.sector_category ILIKE '%pertanian%' THEN 'pertanian'
          WHEN a.sector_category ILIKE '%kesejahteraan%' THEN 'kesejahteraan'
          ELSE LOWER(a.sector_category)
        END
      ) AS sector,
      SUM(
        CASE 
          WHEN a.action_type IN ('view_pdf', 'download_file') THEN 3.0
          WHEN a.action_type = 'view_page' THEN 1.0
          ELSE 0.5
        END
      )::NUMERIC AS click_count,
      MAX(a.created_at) AS last_click_time
    FROM public.activity_logs a
    WHERE (a.user_id = input_device_id OR a.device_id = input_device_id)
      AND a.created_at >= NOW() - INTERVAL '30 days'
      AND (
        LOWER(a.sector_category) IN ('tenaga_kerja', 'ketenagakerjaan', 'ipm', 'perekonomian', 'ekonomi', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan')
        OR a.sector_category ILIKE '%tenaga%'
        OR a.sector_category ILIKE '%kerja%'
        OR a.sector_category ILIKE '%ekonomi%'
        OR a.sector_category ILIKE '%perekonomian%'
        OR a.sector_category ILIKE '%ipm%'
        OR a.sector_category ILIKE '%kemiskinan%'
        OR a.sector_category ILIKE '%kependudukan%'
        OR a.sector_category ILIKE '%pertanian%'
        OR a.sector_category ILIKE '%kesejahteraan%'
      )
      AND a.action_type NOT IN ('login_success', 'click_login_google', 'delete_account', 'logout')
      AND a.item_name NOT IN ('Halaman Login', 'Halaman Profil', 'Masuk dengan Google', 'Masuk dengan Google (Native)', 'Login Google Sukses', 'Login Google Native Sukses', 'Hapus Akun', 'Logout')
    GROUP BY 1
  ),
  max_click AS (
    SELECT COALESCE(MAX(click_count), 1.0) AS max_val FROM user_clicks
  )
  SELECT 
    s.sec_code AS sector_name,
    (
      w_explicit * (CASE WHEN dp.onboarding_sectors IS NOT NULL AND s.sec_code = ANY(dp.onboarding_sectors) THEN 1.0 ELSE 0.0 END)
      + w_freq * COALESCE(uc.click_count / mc.max_val, 0.0)
      + w_recency * COALESCE(EXP(-0.1 * EXTRACT(EPOCH FROM (NOW() - uc.last_click_time)) / 3600.0), 0.0)
    )::NUMERIC AS score
  FROM 
    (VALUES 
      ('tenaga_kerja'), ('ipm'), ('perekonomian'), 
      ('kemiskinan'), ('kependudukan'), ('pertanian'), ('kesejahteraan')
    ) AS s(sec_code)
    LEFT JOIN public.user_profiles dp ON dp.device_id = input_device_id
    LEFT JOIN user_clicks uc ON uc.sector = s.sec_code
    CROSS JOIN max_click mc
  ORDER BY score DESC;
END;
$$ LANGUAGE plpgsql;


-- 2. FUNGSI REKOMENDASI KONTEN PERSONALIZED
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
BEGIN
  RETURN QUERY
  WITH sector_scores AS (
    SELECT sector_name, score
    FROM get_sector_scores_for_device(input_device_id)
  ),
  user_activity_items AS (
    SELECT DISTINCT ON (a.item_name)
      a.id::TEXT AS content_id,
      a.item_name AS content_title,
      LOWER(
        CASE 
          WHEN a.sector_category ILIKE '%tenaga%' OR a.sector_category ILIKE '%kerja%' THEN 'tenaga_kerja'
          WHEN a.sector_category ILIKE '%ekonomi%' OR a.sector_category ILIKE '%perekonomian%' THEN 'perekonomian'
          WHEN a.sector_category ILIKE '%ipm%' THEN 'ipm'
          WHEN a.sector_category ILIKE '%kemiskinan%' THEN 'kemiskinan'
          WHEN a.sector_category ILIKE '%kependudukan%' THEN 'kependudukan'
          WHEN a.sector_category ILIKE '%pertanian%' THEN 'pertanian'
          WHEN a.sector_category ILIKE '%kesejahteraan%' THEN 'kesejahteraan'
          ELSE LOWER(a.sector_category)
        END
      ) AS sec_cat,
      a.action_type AS content_type,
      a.cover_url,
      a.content_url,
      a.created_at
    FROM public.activity_logs a
    WHERE (a.user_id = input_device_id OR a.device_id = input_device_id)
      AND a.action_type IN ('view_pdf', 'download_file', 'view_page')
      AND (
        LOWER(a.sector_category) IN ('tenaga_kerja', 'ketenagakerjaan', 'ipm', 'perekonomian', 'ekonomi', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan')
        OR a.sector_category ILIKE '%tenaga%'
        OR a.sector_category ILIKE '%kerja%'
        OR a.sector_category ILIKE '%ekonomi%'
        OR a.sector_category ILIKE '%perekonomian%'
        OR a.sector_category ILIKE '%ipm%'
        OR a.sector_category ILIKE '%kemiskinan%'
        OR a.sector_category ILIKE '%kependudukan%'
        OR a.sector_category ILIKE '%pertanian%'
        OR a.sector_category ILIKE '%kesejahteraan%'
      )
      AND a.item_name NOT IN ('Halaman Login', 'Halaman Profil', 'Masuk dengan Google', 'Masuk dengan Google (Native)', 'Login Google Sukses', 'Login Google Native Sukses', 'Hapus Akun', 'Logout', 'Temukan BRS lainnya', 'Temukan Infografis lainnya', 'Temukan Publikasi lainnya', 'Pertanian', 'Perekonomian', 'Tenaga Kerja', 'IPM', 'Kemiskinan', 'Kependudukan', 'Kesejahteraan')
    ORDER BY a.item_name, a.created_at DESC
  ),
  contents_items AS (
    SELECT 
      c.id::TEXT AS content_id,
      c.item_name AS content_title,
      c.sector_categories[1] AS sec_cat,
      c.action_type AS content_type,
      c.cover_url,
      c.content_url,
      c.created_at
    FROM public.contents c
  ),
  combined_all AS (
    SELECT * FROM user_activity_items
    UNION ALL
    SELECT * FROM contents_items c_item
    WHERE NOT EXISTS (SELECT 1 FROM user_activity_items u_act WHERE u_act.content_title = c_item.content_title)
  ),
  scored_items AS (
    SELECT 
      ca.content_id,
      ca.content_title,
      ca.sec_cat,
      ca.content_type,
      ca.cover_url,
      ca.content_url,
      (
        COALESCE(ss.score, 0.1) * 7.0 + 
        (EXTRACT(EPOCH FROM ca.created_at) / 1000000000.0) * 3.0
      )::NUMERIC AS calculated_score,
      ROW_NUMBER() OVER (PARTITION BY ca.sec_cat ORDER BY ca.created_at DESC) AS rank_per_sector
    FROM combined_all ca
    LEFT JOIN sector_scores ss ON ss.sector_name = ca.sec_cat
  )
  SELECT 
    si.content_id,
    si.content_title,
    si.sec_cat AS sector_category,
    si.content_type,
    si.cover_url,
    si.content_url,
    si.calculated_score AS final_score
  FROM scored_items si
  ORDER BY 
    si.rank_per_sector ASC,
    si.calculated_score DESC
  LIMIT rec_limit;
END;
$$ LANGUAGE plpgsql;


-- 3. FUNGSI DASHBOARD MONITORING TAB "USER SCORING" (HANYA 7 SEKTOR STATISTIK)
CREATE OR REPLACE FUNCTION get_all_user_scoring_phases()
RETURNS TABLE (
  device_id TEXT,
  user_id TEXT,
  platform TEXT,
  phase TEXT,
  total_interactions BIGINT,
  w_explicit NUMERIC,
  w_freq NUMERIC,
  w_recency NUMERIC,
  onboarding_sectors TEXT[],
  top_sector TEXT,
  top_sector_score NUMERIC,
  last_activity TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  WITH device_user_mapping AS (
    -- Petakan setiap device_id ke user_id (email SSO) jika pernah login
    SELECT 
      a.device_id,
      MAX(a.user_id) FILTER (WHERE a.user_id IS NOT NULL AND a.user_id <> '' AND a.user_id <> 'Anonymous') AS auth_user
    FROM public.activity_logs a
    GROUP BY a.device_id
  ),
  unified_logs AS (
    -- Setiap log disatukan ke identifier akun jika device tersebut sudah login
    SELECT 
      a.id,
      COALESCE(dum.auth_user, a.user_id, a.device_id) AS account_key,
      a.device_id,
      COALESCE(dum.auth_user, a.user_id) AS resolved_user_id,
      a.platform,
      a.sector_category,
      a.action_type,
      a.item_name,
      a.created_at
    FROM public.activity_logs a
    LEFT JOIN device_user_mapping dum ON dum.device_id = a.device_id
  ),
  all_accounts AS (
    -- Gabungkan daftar akun unik dari logs dan user_profiles
    SELECT 
      up.device_id AS account_key, 
      up.device_id, 
      CASE WHEN up.device_id LIKE '%@%' THEN up.device_id ELSE NULL END AS user_id, 
      'IOS'::TEXT AS platform, 
      up.created_at AS ref_time
    FROM public.user_profiles up
    UNION
    SELECT 
      ul.account_key, 
      MAX(ul.device_id) AS device_id, 
      MAX(ul.resolved_user_id) AS user_id, 
      MAX(ul.platform) AS platform, 
      MAX(ul.created_at) AS ref_time
    FROM unified_logs ul
    GROUP BY ul.account_key
  ),
  distinct_accounts AS (
    SELECT 
      acc.account_key,
      MAX(acc.device_id) AS device_id,
      MAX(acc.user_id) AS user_id,
      MAX(acc.platform) AS platform,
      MAX(acc.ref_time) AS last_seen
    FROM all_accounts acc
    GROUP BY acc.account_key
  ),
  account_stats AS (
    SELECT 
      da.account_key,
      da.device_id,
      da.user_id,
      da.platform,
      COUNT(ul.id) FILTER (
        WHERE ul.created_at >= NOW() - INTERVAL '30 days'
          AND (
            LOWER(ul.sector_category) IN ('tenaga_kerja', 'ketenagakerjaan', 'ipm', 'perekonomian', 'ekonomi', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan')
            OR ul.sector_category ILIKE '%tenaga%'
            OR ul.sector_category ILIKE '%kerja%'
            OR ul.sector_category ILIKE '%ekonomi%'
            OR ul.sector_category ILIKE '%perekonomian%'
            OR ul.sector_category ILIKE '%ipm%'
            OR ul.sector_category ILIKE '%kemiskinan%'
            OR ul.sector_category ILIKE '%kependudukan%'
            OR ul.sector_category ILIKE '%pertanian%'
            OR ul.sector_category ILIKE '%kesejahteraan%'
          )
          AND ul.action_type NOT IN ('login_success', 'click_login_google', 'delete_account', 'logout')
          AND ul.item_name NOT IN ('Halaman Login', 'Halaman Profil', 'Masuk dengan Google', 'Masuk dengan Google (Native)', 'Login Google Sukses', 'Login Google Native Sukses', 'Hapus Akun', 'Logout')
      ) AS interactions_30d,
      COALESCE(MAX(ul.created_at), da.last_seen) AS last_activity
    FROM distinct_accounts da
    LEFT JOIN unified_logs ul ON ul.account_key = da.account_key
    GROUP BY da.account_key, da.device_id, da.user_id, da.platform, da.last_seen
  ),
  phase_calc AS (
    SELECT 
      ast.*,
      CASE 
        WHEN ast.interactions_30d = 0 THEN 'cold-start'
        WHEN ast.interactions_30d < 10 THEN 'warm-up'
        ELSE 'established'
      END AS phase,
      CASE WHEN ast.interactions_30d = 0 THEN 1.0
           WHEN ast.interactions_30d < 10 THEN 0.7
           ELSE 0.3 END AS w_explicit,
      CASE WHEN ast.interactions_30d = 0 THEN 0.0
           WHEN ast.interactions_30d < 10 THEN 0.2
           ELSE 0.4 END AS w_freq,
      CASE WHEN ast.interactions_30d = 0 THEN 0.0
           WHEN ast.interactions_30d < 10 THEN 0.1
           ELSE 0.3 END AS w_recency
    FROM account_stats ast
  ),
  top_sectors AS (
    SELECT DISTINCT ON (ul.account_key)
      ul.account_key,
      LOWER(
        CASE 
          WHEN ul.sector_category ILIKE '%tenaga%' OR ul.sector_category ILIKE '%kerja%' THEN 'tenaga_kerja'
          WHEN ul.sector_category ILIKE '%ekonomi%' OR ul.sector_category ILIKE '%perekonomian%' THEN 'perekonomian'
          WHEN ul.sector_category ILIKE '%ipm%' THEN 'ipm'
          WHEN ul.sector_category ILIKE '%kemiskinan%' THEN 'kemiskinan'
          WHEN ul.sector_category ILIKE '%kependudukan%' THEN 'kependudukan'
          WHEN ul.sector_category ILIKE '%pertanian%' THEN 'pertanian'
          WHEN ul.sector_category ILIKE '%kesejahteraan%' THEN 'kesejahteraan'
          ELSE LOWER(ul.sector_category)
        END
      ) AS top_sector,
      COUNT(*) AS sector_count
    FROM unified_logs ul
    WHERE ul.created_at >= NOW() - INTERVAL '30 days'
      AND (
        LOWER(ul.sector_category) IN ('tenaga_kerja', 'ketenagakerjaan', 'ipm', 'perekonomian', 'ekonomi', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan')
        OR ul.sector_category ILIKE '%tenaga%'
        OR ul.sector_category ILIKE '%kerja%'
        OR ul.sector_category ILIKE '%ekonomi%'
        OR ul.sector_category ILIKE '%perekonomian%'
        OR ul.sector_category ILIKE '%ipm%'
        OR ul.sector_category ILIKE '%kemiskinan%'
        OR ul.sector_category ILIKE '%kependudukan%'
        OR ul.sector_category ILIKE '%pertanian%'
        OR ul.sector_category ILIKE '%kesejahteraan%'
      )
      AND ul.action_type NOT IN ('login_success', 'click_login_google', 'delete_account', 'logout')
      AND ul.item_name NOT IN ('Halaman Login', 'Halaman Profil', 'Masuk dengan Google', 'Masuk dengan Google (Native)', 'Login Google Sukses', 'Login Google Native Sukses', 'Hapus Akun', 'Logout')
    GROUP BY ul.account_key, 2
    ORDER BY ul.account_key, COUNT(*) DESC
  )
  SELECT 
    pc.device_id,
    pc.user_id,
    pc.platform,
    pc.phase,
    pc.interactions_30d AS total_interactions,
    pc.w_explicit,
    pc.w_freq,
    pc.w_recency,
    up.onboarding_sectors,
    ts.top_sector,
    CASE WHEN ts.sector_count IS NOT NULL AND pc.interactions_30d > 0 
         THEN ROUND((ts.sector_count::NUMERIC / pc.interactions_30d) * 100, 1) 
         ELSE 0 END AS top_sector_score,
    pc.last_activity
  FROM phase_calc pc
  LEFT JOIN public.user_profiles up ON (up.device_id = pc.account_key OR up.device_id = pc.device_id OR up.device_id = pc.user_id)
  LEFT JOIN top_sectors ts ON ts.account_key = pc.account_key
  ORDER BY pc.last_activity DESC;
END;
$$ LANGUAGE plpgsql;
