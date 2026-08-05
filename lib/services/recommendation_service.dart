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
  // 2. Simpan atau perbarui profil perangkat (Jurusan & Sektor Pilihan)
  static Future<void> saveProfile(String major, List<String> onboardingSectors) async {
    try {
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

  // Fallback pemetaan jurusan luring
  static List<String> getOfflineRelevantSectors(String major) {
    switch (major) {
      case 'Teknik Informatika':
      case 'Sistem Informasi':
        return ['perekonomian', 'tenaga_kerja'];
      case 'Teknik Sipil':
        return ['perekonomian'];
      case 'Ekonomi':
        return ['perekonomian', 'kemiskinan'];
      case 'Akuntansi':
        return ['perekonomian', 'kesejahteraan'];
      case 'Ilmu Komunikasi':
        return ['kependudukan', 'kesejahteraan'];
      case 'Pendidikan':
        return ['ipm'];
      case 'Pertanian':
        return ['pertanian', 'perekonomian'];
      case 'Umum':
        return [];
      default:
        return [];
    }
  }

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
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching personalized recommendations: $e");
      return [];
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
      );
      final map = <String, double>{};
      for (var row in response) {
        map[row['sector_name'] as String] = (row['score'] as num).toDouble();
      }
      return map;
    } catch (e) {
      print("Error fetching sector scores: $e");
      return {};
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
          .not('item_name', 'in', '("Halaman Login","Halaman Profil","Masuk dengan Google","Login Google Sukses","Temukan BRS lainnya","Temukan Infografis lainnya","Temukan Publikasi lainnya")')
          .order('created_at', ascending: false)
          .limit(limit * 4);

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
      return uniqueList;
    } catch (e) {
      print("Error fetching recently viewed: $e");
      return [];
    }
  }
}
