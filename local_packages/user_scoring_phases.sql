-- ============================================================================
-- SQL RPC FUNCTIONS FOR WEIGHTED HYBRID SCORING SYSTEM (RESTRUCTURED ERD)
-- ============================================================================

-- 1. FUNGSI SCORING 7 SEKTOR UNTUK INDIVIDUAL USER (3 FASE ADAPTIF)
CREATE OR REPLACE FUNCTION get_sector_scores_for_user(input_user_id TEXT)
RETURNS TABLE (
  sector_name TEXT,
  score NUMERIC
) AS $$
DECLARE
  total_interactions INT := 0;
  w_explicit NUMERIC := 0.2;
  w_freq NUMERIC := 0.5;
  w_recency NUMERIC := 0.3;
  user_sectors TEXT[];
BEGIN
  -- 1. Ambil onboarding sectors dari user_interests + categories (via user_all)
  SELECT ARRAY_AGG(cat.category) INTO user_sectors
  FROM public.user_all ua
  JOIN public.user_interests ui ON ui.user_id = ua.id_user
  JOIN public.categories cat ON cat.id_category = ui.category_id
  WHERE ua.email = input_user_id OR ua.id_user::TEXT = input_user_id;

  -- 2. Hitung total interaksi user dalam 30 hari terakhir
  SELECT COUNT(*) INTO total_interactions
  FROM public.activity_logs a
  WHERE a.user_id = input_user_id
    AND a.created_at >= NOW() - INTERVAL '30 days'
    AND LOWER(a.sector_category) IN ('tenaga_kerja', 'ipm', 'perekonomian', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan');

  -- 3. Penentuan Bobot 3 Fase Adaptif
  IF total_interactions = 0 THEN
    w_explicit := 1.0; w_freq := 0.0; w_recency := 0.0;
  ELSIF total_interactions < 10 THEN
    w_explicit := 0.7; w_freq := 0.2; w_recency := 0.1;
  ELSE
    w_explicit := 0.2; w_freq := 0.5; w_recency := 0.3;
  END IF;

  RETURN QUERY
  WITH user_clicks AS (
    SELECT 
      LOWER(a.sector_category) AS sector,
      SUM(
        CASE 
          WHEN a.action_type IN ('view_pdf', 'download_file', 'view_brs_pdf', 'view_publikasi_pdf') THEN 3.0
          WHEN a.action_type = 'view_page' THEN 1.0
          ELSE 0.5
        END
      )::NUMERIC AS click_count,
      MAX(a.created_at) AS last_click_time
    FROM public.activity_logs a
    WHERE a.user_id = input_user_id
      AND a.created_at >= NOW() - INTERVAL '30 days'
      AND LOWER(a.sector_category) IN ('tenaga_kerja', 'ipm', 'perekonomian', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan')
    GROUP BY 1
  ),
  max_click AS (
    SELECT COALESCE(MAX(click_count), 1.0) AS max_val FROM user_clicks
  )
  SELECT 
    s.sec_code AS sector_name,
    (
      w_explicit * (CASE WHEN user_sectors IS NOT NULL AND s.sec_code = ANY(user_sectors) THEN 1.0 ELSE 0.0 END)
      + w_freq * COALESCE(uc.click_count / mc.max_val, 0.0)
      + w_recency * COALESCE(EXP(-0.1 * EXTRACT(EPOCH FROM (NOW() - uc.last_click_time)) / 3600.0), 0.0)
    )::NUMERIC AS score
  FROM 
    (VALUES 
      ('tenaga_kerja'), ('ipm'), ('perekonomian'), 
      ('kemiskinan'), ('kependudukan'), ('pertanian'), ('kesejahteraan')
    ) AS s(sec_code)
    LEFT JOIN user_clicks uc ON uc.sector = s.sec_code
    CROSS JOIN max_click mc
  ORDER BY score DESC;
END;
$$ LANGUAGE plpgsql;


-- 2. FUNGSI REKOMENDASI PERSONALISASI BERDASARKAN SKOR USER (MANY-TO-MANY CATEGORIES)
CREATE OR REPLACE FUNCTION get_personalized_recommendations_by_user(
  input_user_id TEXT,
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
  WITH ranked_sectors AS (
    SELECT 
      rs_inner.sector_name, 
      rs_inner.score,
      ROW_NUMBER() OVER (ORDER BY rs_inner.score DESC, rs_inner.sector_name ASC) AS sector_rank
    FROM get_sector_scores_for_user(input_user_id) rs_inner
  ),
  recent_logs AS (
    SELECT DISTINCT LOWER(TRIM(a.title)) AS item_name, a.content_url
    FROM public.activity_logs a
    WHERE a.user_id = input_user_id
      AND a.action_type IN ('view_pdf', 'download_file', 'view_page', 'view_brs_pdf', 'view_publikasi_pdf')
      AND a.created_at >= NOW() - INTERVAL '30 days'
  ),
  candidate_contents AS (
    SELECT 
      c.id::TEXT AS content_id,
      c.item_name AS content_title,
      LOWER(cat.category) AS sec_cat,
      COALESCE(c.content_type, c.action_type) AS content_type,
      c.cover_url,
      c.content_url,
      c.created_at,
      rs.score AS sector_score,
      rs.sector_rank,
      CASE 
        WHEN rl.item_name IS NOT NULL OR (c.content_url IS NOT NULL AND c.content_url != '' AND rl_url.content_url IS NOT NULL) THEN 0 
        ELSE 1 
      END AS is_unseen,
      ROW_NUMBER() OVER (
        PARTITION BY LOWER(cat.category)
        ORDER BY 
          (CASE WHEN rl.item_name IS NOT NULL OR (c.content_url IS NOT NULL AND c.content_url != '' AND rl_url.content_url IS NOT NULL) THEN 0 ELSE 1 END) DESC,
          c.created_at DESC
      ) AS rank_in_sector
    FROM public.contents c
    JOIN public.contents_has_categories chc ON chc.contents_id_content = c.id
    JOIN public.categories cat ON cat.id_category = chc.categories_id_category
    JOIN ranked_sectors rs ON rs.sector_name = LOWER(cat.category)
    LEFT JOIN recent_logs rl ON rl.item_name = LOWER(TRIM(c.item_name))
    LEFT JOIN recent_logs rl_url ON rl_url.content_url = c.content_url AND c.content_url IS NOT NULL AND c.content_url != ''
    WHERE c.item_name NOT ILIKE '%TEST%' 
      AND c.item_name NOT ILIKE '%dummy%'
      AND c.item_name NOT IN ('Halaman Login', 'Halaman Profil', 'Masuk dengan Google', 'Masuk dengan Google (Native)', 'Login Google Sukses', 'Login Google Native Sukses', 'Hapus Akun', 'Logout', 'Temukan BRS lainnya', 'Temukan Infografis lainnya', 'Temukan Publikasi lainnya')
  ),
  top_1_per_sector AS (
    SELECT 
      cc.content_id,
      cc.content_title,
      cc.sec_cat AS sector_category,
      cc.content_type,
      cc.cover_url,
      cc.content_url,
      (cc.sector_score * 0.70 + (EXTRACT(EPOCH FROM cc.created_at) / 1000000000.0) * 0.30)::NUMERIC AS final_score,
      cc.sector_rank
    FROM candidate_contents cc
    WHERE cc.rank_in_sector = 1
  )
  SELECT 
    t.content_id,
    t.content_title,
    t.sector_category,
    t.content_type,
    t.cover_url,
    t.content_url,
    t.final_score
  FROM top_1_per_sector t
  ORDER BY 
    t.sector_rank ASC
  LIMIT rec_limit;
END;
$$ LANGUAGE plpgsql;


-- 3. FUNGSI DASHBOARD MONITORING TAB "USER SCORING" (BEBAS DEVICE_ID)
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
  WITH all_users AS (
    -- 1. Pengguna yang sudah login & menyelesaikan onboarding sektor di aplikasi mobile Mboistats
    SELECT DISTINCT
      ua.id_user::TEXT AS user_uuid,
      ua.email AS user_email,
      ua.created_at AS reg_time
    FROM public.user_all ua
    JOIN public.user_interests ui ON ui.user_id = ua.id_user
    UNION
    -- 2. Pengguna yang memiliki riwayat aktivitas di aplikasi mobile Mboistats
    SELECT 
      a.user_id AS user_uuid,
      a.user_id AS user_email,
      MIN(a.created_at) AS reg_time
    FROM public.activity_logs a
    WHERE a.user_id IS NOT NULL AND a.user_id <> '' AND a.user_id <> 'Anonymous'
    GROUP BY a.user_id
  ),
  distinct_users AS (
    SELECT 
      au.user_email,
      MAX(au.user_uuid) AS user_uuid,
      MIN(au.reg_time) AS first_seen
    FROM all_users au
    WHERE au.user_email IS NOT NULL AND au.user_email <> ''
    GROUP BY au.user_email
  ),
  user_stats AS (
    SELECT 
      du.user_email,
      du.user_uuid,
      COUNT(a.id) FILTER (
        WHERE a.created_at >= NOW() - INTERVAL '30 days'
          AND LOWER(a.sector_category) IN ('tenaga_kerja', 'ketenagakerjaan', 'ipm', 'perekonomian', 'ekonomi', 'kemiskinan', 'kependudukan', 'pertanian', 'kesejahteraan')
          AND a.action_type NOT IN ('login_success', 'click_login_google', 'delete_account', 'logout')
          AND a.title NOT IN ('Halaman Login', 'Halaman Profil', 'Masuk dengan Google', 'Masuk dengan Google (Native)', 'Login Google Sukses', 'Login Google Native Sukses', 'Hapus Akun', 'Logout')
      ) AS interactions_30d,
      COALESCE(MAX(a.created_at), du.first_seen) AS last_activity,
      COALESCE(MAX(a.platform), 'Android') AS platform
    FROM distinct_users du
    LEFT JOIN public.activity_logs a ON a.user_id = du.user_email OR a.user_id = du.user_uuid
    GROUP BY du.user_email, du.user_uuid, du.first_seen
  ),
  phase_calc AS (
    SELECT 
      us.*,
      CASE 
        WHEN us.interactions_30d = 0 THEN 'cold-start'
        WHEN us.interactions_30d < 10 THEN 'warm-up'
        ELSE 'established'
      END AS phase,
      CASE WHEN us.interactions_30d = 0 THEN 1.0
           WHEN us.interactions_30d < 10 THEN 0.7
           ELSE 0.2 END AS w_explicit,
      CASE WHEN us.interactions_30d = 0 THEN 0.0
           WHEN us.interactions_30d < 10 THEN 0.2
           ELSE 0.5 END AS w_freq,
      CASE WHEN us.interactions_30d = 0 THEN 0.0
           WHEN us.interactions_30d < 10 THEN 0.1
           ELSE 0.3 END AS w_recency
    FROM user_stats us
  ),
  user_onboarding AS (
    SELECT 
      ua.email,
      ARRAY_AGG(cat.category) AS sectors
    FROM public.user_all ua
    JOIN public.user_interests ui ON ui.user_id = ua.id_user
    JOIN public.categories cat ON cat.id_category = ui.category_id
    GROUP BY ua.email
  ),
  top_sectors AS (
    SELECT DISTINCT ON (du_sub.u_id)
      du_sub.u_id,
      rss.sector_name AS top_sector,
      rss.score AS top_sector_score
    FROM (
      SELECT du.user_email AS u_id FROM distinct_users du
    ) du_sub
    CROSS JOIN LATERAL get_sector_scores_for_user(du_sub.u_id) rss
    ORDER BY du_sub.u_id, rss.score DESC
  )
  SELECT 
    pc.user_uuid AS device_id,
    pc.user_email AS user_id,
    pc.platform,
    pc.phase,
    pc.interactions_30d AS total_interactions,
    pc.w_explicit,
    pc.w_freq,
    pc.w_recency,
    uo.sectors AS onboarding_sectors,
    ts.top_sector,
    COALESCE(ts.top_sector_score, 1.0)::NUMERIC AS top_sector_score,
    pc.last_activity
  FROM phase_calc pc
  LEFT JOIN user_onboarding uo ON uo.email = pc.user_email
  LEFT JOIN top_sectors ts ON ts.u_id = pc.user_email
  ORDER BY pc.last_activity DESC;
END;
$$ LANGUAGE plpgsql;

NOTIFY pgrst, 'reload schema';
