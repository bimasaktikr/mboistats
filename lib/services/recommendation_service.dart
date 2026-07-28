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

  // 1. Cek apakah profil perangkat sudah terdaftar di Supabase
  static Future<bool> checkProfileExists() async {
    try {
      final deviceId = await LoggerService.getDeviceId();
      final data = await _client
          .from('device_profiles')
          .select('device_id')
          .eq('device_id', deviceId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      print("Error checking device profile: $e");
      return false;
    }
  }

  // 2. Simpan atau perbarui profil perangkat (Jurusan & Sektor Pilihan)
  static Future<void> saveProfile(String major, List<String> onboardingSectors) async {
    try {
      final deviceId = await LoggerService.getDeviceId();
      await _client.from('device_profiles').upsert({
        'device_id': deviceId,
        'major': major,
        'onboarding_sectors': onboardingSectors,
      });
      print("Device profile successfully saved: $major");
    } catch (e) {
      print("Error saving device profile: $e");
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
      default:
        return [];
    }
  }

  // 4. Panggil RPC Supabase untuk mendapatkan Konten Terpersonalisasi
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({int limit = 6}) async {
    try {
      final deviceId = await LoggerService.getDeviceId();
      final List<dynamic> response = await _client.rpc(
        'get_personalized_recommendations_by_device',
        params: {
          'input_device_id': deviceId,
          'rec_limit': limit,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching personalized recommendations: $e");
      return [];
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
      final deviceId = await LoggerService.getDeviceId();
      final List<dynamic> response = await _client
          .from('activity_logs')
          .select('item_name, sector_category, created_at, action_type, cover_url, content_url')
          .eq('device_id', deviceId)
          .inFilter('action_type', ['view_pdf', 'download_file'])
          .order('created_at', ascending: false)
          .limit(limit * 3); // Ambil lebih banyak untuk de-duplikasi

      // De-duplikasi nama item konten dalam memori
      final seen = <String>{};
      final uniqueList = <Map<String, dynamic>>[];
      for (var item in response) {
        final name = item['item_name'] as String?;
        if (name != null && !seen.contains(name)) {
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
