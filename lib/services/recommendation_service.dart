import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/services/logger_service.dart';

class RecommendedItem {
  final String title;
  final String route;
  final String icon;
  final String description;
  final String? coverUrl;
  final String? contentUrl;

  RecommendedItem({
    required this.title,
    required this.route,
    required this.icon,
    required this.description,
    this.coverUrl,
    this.contentUrl,
  });
}

class RecommendationService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Mendapatkan identifier yang unik: Gunakan User Email / User ID jika login, jika tidak gunakan Device ID
  static Future<String> _getProfileIdentifier() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      return user.email ?? user.id;
    }
    return await LoggerService.getDeviceId();
  }

  // 1. Cek apakah profil perangkat sudah terdaftar di Supabase
  static Future<bool> checkProfileExists() async {
    try {
      final profileId = await _getProfileIdentifier();
      final data = await _client
          .from('device_profiles')
          .select('device_id')
          .eq('device_id', profileId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      print("Error checking device profile: $e");
      return false;
    }
  }

  // 2. Mengambil profil jurusan (major) perangkat saat ini
  static Future<String?> getMajor() async {
    try {
      final profileId = await _getProfileIdentifier();
      final data = await _client
          .from('device_profiles')
          .select('major')
          .eq('device_id', profileId)
          .maybeSingle();
      if (data != null && data['major'] != null) {
        return data['major'] as String;
      }
      return null;
    } catch (e) {
      print("Error fetching device major: $e");
      return null;
    }
  }
  static void clearLocalCache() {
    _cachedRecommendations = null;
    _cachedSectorScores = null;
    _cachedRecentlyViewed = null;
  }

  // 2. Simpan atau perbarui profil perangkat (Jurusan & Sektor Pilihan)
  static Future<void> saveProfile(String major, List<String> onboardingSectors) async {
    try {
      clearLocalCache();
      final profileId = await _getProfileIdentifier();
      await _client.from('device_profiles').upsert({
        'device_id': profileId,
        'major': major,
        'onboarding_sectors': onboardingSectors,
      });
      print("Device profile successfully saved: $major");
    } catch (e) {
      print("Error saving device profile: $e");
    }
  }

  static Future<void> deleteProfile() async {
    try {
      clearLocalCache();
      final profileId = await _getProfileIdentifier();
      await _client.from('device_profiles').delete().eq('device_id', profileId);
      print("Device profile successfully deleted");
    } catch (e) {
      print("Error deleting device profile: $e");
    }
  }

  // 3. Ambil rekomendasi sektor awal berdasarkan Jurusan (Smart Default)
  static Future<List<String>> getRelevantSectorsForMajor(String major) async {
    try {
      final data = await _client
          .from('major_sector_mapping')
          .select('relevant_sectors')
          .eq('major_name', major)
          .maybeSingle();
      if (data != null && data['relevant_sectors'] != null) {
        return List<String>.from(data['relevant_sectors']);
      }
    } catch (e) {
      print("Error fetching sectors for major: $e");
    }
    // Fallback Offline jika database belum sinkron/koneksi offline
    return getOfflineRelevantSectors(major);
  }

  // Fallback pemetaan jurusan luring dengan substring matching yang optimal
  static List<String> getOfflineRelevantSectors(String major) {
    final m = major.toLowerCase();
    if (m.contains('informatika') || m.contains('komputer') || m.contains('sistem informasi') || m.contains('teknologi')) {
      return ['perekonomian', 'tenaga_kerja'];
    }
    if (m.contains('statistika') || m.contains('matematika') || m.contains('sains data')) {
      return ['perekonomian', 'ipm', 'kemiskinan'];
    }
    if (m.contains('ekonomi') || m.contains('manajemen') || m.contains('bisnis') || m.contains('keuangan')) {
      return ['perekonomian', 'kemiskinan', 'kesejahteraan'];
    }
    if (m.contains('akuntansi')) {
      return ['perekonomian', 'kesejahteraan'];
    }
    if (m.contains('sipil') || m.contains('pwk') || m.contains('perencanaan') || m.contains('industri')) {
      return ['perekonomian', 'kependudukan'];
    }
    if (m.contains('hukum') || m.contains('komunikasi') || m.contains('sosiologi') || m.contains('psikologi') || m.contains('administrasi')) {
      return ['kependudukan', 'kesejahteraan', 'kemiskinan'];
    }
    if (m.contains('pendidikan') || m.contains('keguruan')) {
      return ['ipm', 'kesejahteraan'];
    }
    if (m.contains('pertanian') || m.contains('agribisnis') || m.contains('kehutanan') || m.contains('peternakan')) {
      return ['pertanian', 'perekonomian'];
    }
    if (m.contains('kesehatan') || m.contains('kedokteran') || m.contains('farmasi')) {
      return ['ipm', 'kesejahteraan'];
    }
    if (m.contains('pariwisata') || m.contains('perhotelan')) {
      return ['perekonomian', 'kesejahteraan'];
    }
    if (m.contains('umum')) {
      return [];
    }
    return ['perekonomian', 'kependudukan'];
  }

  static List<Map<String, dynamic>>? _cachedRecommendations;
  static Map<String, double>? _cachedSectorScores;
  static List<Map<String, dynamic>>? _cachedRecentlyViewed;

  // 4. Panggil RPC Supabase untuk mendapatkan Konten Terpersonalisasi
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({int limit = 6}) async {
    try {
      final profileId = await _getProfileIdentifier();
      final List<dynamic> response = await _client.rpc(
        'get_personalized_recommendations_by_device',
        params: {
          'input_device_id': profileId,
          'rec_limit': limit,
        },
      ).timeout(const Duration(milliseconds: 2500));
      final result = List<Map<String, dynamic>>.from(response);
      if (result.isNotEmpty) {
        _cachedRecommendations = result;
      }
      return result.isNotEmpty ? result : (_cachedRecommendations ?? []);
    } catch (e) {
      print("Error fetching personalized recommendations: $e");
      return _cachedRecommendations ?? [];
    }
  }

  /// Mengambil skor preferensi per sektor untuk akun/perangkat ini.
  /// Digunakan untuk mengurutkan 7 ikon kategori di beranda secara dinamis.
  static Future<Map<String, double>> getSectorScoresForDevice() async {
    try {
      final profileId = await _getProfileIdentifier();
      final List<dynamic> response = await _client.rpc(
        'get_sector_scores_for_device',
        params: {'input_device_id': profileId},
      ).timeout(const Duration(milliseconds: 2500));
      final map = <String, double>{};
      for (var row in response) {
        map[row['sector_name'] as String] = (row['score'] as num).toDouble();
      }
      if (map.isNotEmpty) {
        _cachedSectorScores = map;
      }
      return map.isNotEmpty ? map : (_cachedSectorScores ?? {});
    } catch (e) {
      print("Error fetching sector scores: $e");
      return _cachedSectorScores ?? {};
    }
  }

  // Helper Mapper Rute & Icon untuk Sektor
  static String _getRouteForSector(String sector, String contentType) {
    switch (sector.toLowerCase()) {
      case 'perekonomian':
      case 'ekonomi':
        return '/ekonomi';
      case 'tenaga_kerja':
      case 'ketenagakerjaan':
        return '/ketenagakerjaan';
      case 'ipm':
        return '/ipm';
      case 'kemiskinan':
        return '/kemiskinan';
      case 'kependudukan':
        return '/kependudukan';
      case 'kesejahteraan':
        return '/kesejahteraan';
      case 'pertanian':
        return '/pertanian';
      case 'berita':
        return '/berita';
      case 'publikasi':
        return '/publikasi';
      case 'infografis':
        return '/infografis';
      default:
        return '/main';
    }
  }

  static String _getIconForSector(String sector) {
    switch (sector.toLowerCase()) {
      case 'perekonomian':
      case 'ekonomi':
        return 'ekonomi.png';
      case 'tenaga_kerja':
      case 'ketenagakerjaan':
        return 'ketenagakerjaan.png';
      case 'ipm':
        return 'ipm.png';
      case 'kemiskinan':
        return 'kemiskinan.png';
      case 'kependudukan':
        return 'kependudukan.png';
      case 'kesejahteraan':
        return 'kesejahteraan.png';
      case 'pertanian':
        return 'pertanian.png';
      default:
        return 'faq.png';
    }
  }

  // Wrapper untuk dipanggil oleh widget visualisasi rekomendasi sektoral existing
  static Future<List<RecommendedItem>> getSectorRecommendations({String? userId}) async {
    try {
      final list = await getPersonalizedRecommendations(limit: 5);
      if (list.isEmpty) {
        // Fallback default jika belum ada aktivitas
        return [
          RecommendedItem(
            title: 'Penduduk Menurut Kecamatan',
            route: '/PendudukKec',
            icon: 'kependudukan.png',
            description: 'Informasi jumlah penduduk di tiap kecamatan Kota Malang terbaru.',
          ),
          RecommendedItem(
            title: 'Tingkat Kemiskinan',
            route: '/TingkatKemiskinan',
            icon: 'kemiskinan.png',
            description: 'Persentase dan perkembangan tingkat kemiskinan dari tahun ke tahun.',
          ),
        ];
      }

      return list.map((item) {
        final sector = item['sector_category'] as String? ?? '';
        final title = item['content_title'] as String? ?? 'Data Statistik';
        final cType = item['content_type'] as String? ?? 'view_page';
        final coverUrl = item['cover_url'] as String?;
        final contentUrl = item['content_url'] as String?;
        
        String desc = 'Statistik sektoral Kota Malang terbaru.';
        if (cType == 'download_file') {
          desc = 'Unduh dokumen data terkait $sector Kota Malang.';
        } else if (cType == 'view_pdf') {
          desc = 'Lihat laporan resmi terkait $sector Kota Malang.';
        }

        return RecommendedItem(
          title: title,
          route: _getRouteForSector(sector, cType),
          icon: _getIconForSector(sector),
          description: desc,
          coverUrl: coverUrl,
          contentUrl: contentUrl,
        );
      }).toList();
    } catch (e) {
      print("Gagal mengurai getSectorRecommendations: $e");
      return [];
    }
  }

  // 5. Ambil data aktivitas Terakhir Dilihat (Recently Viewed)
  static Future<List<Map<String, dynamic>>> getRecentlyViewed({int limit = 5}) async {
    try {
      final profileId = await _getProfileIdentifier();
      final deviceId = await LoggerService.getDeviceId();
      final user = _client.auth.currentUser;
      final userId = user?.id;
      final userEmail = user?.email;

      final filterOr = [
        'user_id.eq.$profileId',
        if (userEmail != null) 'user_id.eq.$userEmail',
        if (userId != null) 'user_id.eq.$userId',
        'device_id.eq.$deviceId',
      ].join(',');

      final List<dynamic> response = await _client
          .from('activity_logs')
          .select('item_name, sector_category, created_at, action_type, cover_url, content_url')
          .or(filterOr)
          .inFilter('action_type', ['view_pdf', 'download_file', 'view_page'])
          .not('item_name', 'in', '("Halaman Login","Halaman Profil","Halaman Edit Profil","Halaman Kontak Layanan","Logout Akun","Masuk dengan Google","Login Google Sukses","Temukan BRS lainnya","Temukan Infografis lainnya","Temukan Publikasi lainnya","Pertanian","Perekonomian","Tenaga Kerja","IPM","Kemiskinan","Kependudukan","Kesejahteraan")')
          .order('created_at', ascending: false)
          .limit(limit * 4)
          .timeout(const Duration(milliseconds: 2500));

      // De-duplikasi nama item konten dalam memori
      final seen = <String>{};
      final uniqueList = <Map<String, dynamic>>[];
      for (var item in response) {
        final name = item['item_name'] as String?;
        if (name != null && name.isNotEmpty && !seen.contains(name)) {
          seen.add(name);
          uniqueList.add(Map<String, dynamic>.from(item));
        }
        if (uniqueList.length >= limit) break;
      }
      if (uniqueList.isNotEmpty) {
        _cachedRecentlyViewed = uniqueList;
      }
      return uniqueList;
    } catch (e) {
      print("Error fetching recently viewed: $e");
      return _cachedRecentlyViewed ?? [];
    }
  }

  /// Sync list item BPS API ke tabel 'contents' Supabase secara otomatis
  static Future<void> syncContentItems(List<Map<String, dynamic>> items, String actionType) async {
    try {
      for (var item in items) {
        final title = (item['title'] ?? item['judul'] ?? '').toString();
        if (title.isEmpty) continue;
        final cover = (item['thumbnail'] ?? item['img'] ?? item['cover'] ?? '').toString();
        final content = (item['pdf'] ?? item['img'] ?? item['dl'] ?? '').toString();

        final text = title.toLowerCase();
        final sectors = <String>[];
        if (text.contains('inflasi') || text.contains('pdrb') || text.contains('ekonomi') ||
            text.contains('hotel') || text.contains('penghunian') || text.contains('tpk') ||
            text.contains('pariwisata') || text.contains('wisatawan') || text.contains('industri') ||
            text.contains('perusahaan') || text.contains('usaha') || text.contains('perdagangan') ||
            text.contains('ekspor') || text.contains('impor') || text.contains('konstruksi') ||
            text.contains('transportasi') || text.contains('laju pertumbuhan')) {
          sectors.add('perekonomian');
        }
        if (text.contains('kemiskinan') || text.contains('miskin')) sectors.add('kemiskinan');
        if (text.contains('kerja') || text.contains('pengangguran') || text.contains('tpt') ||
            text.contains('tenaga') || text.contains('upah') || text.contains('buruh')) {
          sectors.add('tenaga_kerja');
        }
        if (text.contains('ipm') || text.contains('pembangunan manusia') ||
            text.contains('sekolah') || text.contains('harapan hidup') ||
            text.contains('melek huruf') || text.contains('pendidikan') ||
            text.contains('gender') || text.contains('ketimpangan')) {
          sectors.add('ipm');
        }
        if (text.contains('penduduk') || text.contains('kecamatan') || text.contains('dalam angka') ||
            text.contains('demografi') || text.contains('kelahiran') || text.contains('kematian') ||
            text.contains('migrasi') || text.contains('sensus') || text.contains('potensi desa') ||
            text.contains('statistik daerah')) {
          sectors.add('kependudukan');
        }
        if (text.contains('panen') || text.contains('padi') || text.contains('beras') ||
            text.contains('pertanian') || text.contains('tanaman') || text.contains('ternak') ||
            text.contains('perikanan') || text.contains('hortikultura')) {
          sectors.add('pertanian');
        }
        if (text.contains('pengeluaran') || text.contains('kesejahteraan') || text.contains('gini') ||
            text.contains('konsumsi') || text.contains('sosial') || text.contains('rumah tangga') ||
            text.contains('susenas')) {
          sectors.add('kesejahteraan');
        }
        if (sectors.isEmpty) sectors.add('perekonomian');

        await _client.from('contents').upsert({
          'item_name': title,
          'sector_categories': sectors,
          'action_type': actionType,
          'cover_url': cover,
          'content_url': content,
        }, onConflict: 'item_name');
      }
    } catch (e) {
      print("Error syncing content items to Supabase: $e");
    }
  }
}
