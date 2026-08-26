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
          .from('user_all')
          .select('id_user')
          .eq('email', profileId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      print("Error checking user profile: $e");
      return false;
    }
  }

  // 2. Mengambil profil jurusan (major) pengguna saat ini
  static Future<String?> getMajor() async {
    try {
      final profileId = await _getProfileIdentifier();
      final data = await _client
          .from('user_all')
          .select('major:major_id_major(major)')
          .eq('email', profileId)
          .maybeSingle();
      if (data != null && data['major'] != null) {
        return data['major']['major'] as String;
      }
      return null;
    } catch (e) {
      print("Error fetching user major: $e");
      return null;
    }
  }
  static void clearLocalCache() {
    _cachedRecommendations = null;
    _cachedSectorScores = null;
    _cachedRecentlyViewed = null;
  }

  // 2. Simpan atau perbarui profil pengguna (Jurusan & Sektor Pilihan)
  static Future<void> saveProfile(String major, List<String> onboardingSectors) async {
    try {
      clearLocalCache();
      final profileId = await _getProfileIdentifier();
      final user = _client.auth.currentUser;

      // 1. Cari major_id dari tabel major
      final majorData = await _client
          .from('major')
          .select('id_major')
          .eq('major', major)
          .maybeSingle();
      final majorId = majorData?['id_major'] as int?;

      // 2. Tentukan type_user ('mahasiswa' atau 'umum')
      final typeUser = (major == 'Umum') ? 'umum' : 'mahasiswa';

      // 3. Upsert ke user_all
      await _client.from('user_all').upsert({
        'email': profileId,
        'name': user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'],
        'type_user': typeUser,
        'major_id_major': majorId,
      }, onConflict: 'email');

      // 4. Ambil id_user yang baru dibuat/diupdate
      final userData = await _client
          .from('user_all')
          .select('id_user')
          .eq('email', profileId)
          .single();
      final userId = userData['id_user'] as String;

      // 5. Hapus user_interests lama lalu insert baru
      await _client.from('user_interests').delete().eq('user_id', userId);

      if (onboardingSectors.isNotEmpty) {
        // Ambil category IDs
        final List<dynamic> categories = await _client
            .from('categories')
            .select('id_category, category')
            .inFilter('category', onboardingSectors);

        final interests = categories.map((cat) => {
          'user_id': userId,
          'category_id': cat['id_category'],
        }).toList();

        if (interests.isNotEmpty) {
          await _client.from('user_interests').insert(interests);
        }
      }

      print("User profile successfully saved to user_all: $major");
    } catch (e) {
      print("Error saving user profile: $e");
    }
  }

  static Future<void> deleteProfile() async {
    try {
      clearLocalCache();
      final user = _client.auth.currentUser;
      final userEmail = user?.email;
      final userId = user?.id;
      final profileId = await _getProfileIdentifier();

      // 1. Hapus dari user_all (CASCADE akan menghapus user_interests juga)
      await _client.from('user_all').delete().eq('email', profileId);

      // 2. Hapus histori aktivitas dari activity_logs
      if (userEmail != null && userEmail.isNotEmpty) {
        await _client.from('activity_logs').delete().eq('user_id', userEmail);
      }
      if (userId != null && userId.isNotEmpty) {
        await _client.from('activity_logs').delete().eq('user_id', userId);
      }

      print("User profile and activity logs successfully deleted from Supabase");
    } catch (e) {
      print("Error deleting user profile and logs: $e");
    }
  }

  static Map<String, List<String>>? _cachedMajorSectorMapping;

  /// Default mapping 49 prodi sebagai fallback offline instan
  static const Map<String, List<String>> defaultMajorSectorMapping = {
    'Teknik Informatika': ['perekonomian', 'tenaga_kerja'],
    'Ilmu Komputer': ['perekonomian', 'tenaga_kerja'],
    'Sains Data': ['perekonomian', 'ipm', 'kemiskinan'],
    'Sistem Informasi': ['perekonomian', 'tenaga_kerja'],
    'Teknologi Informasi': ['perekonomian', 'tenaga_kerja'],
    'Teknik Sipil': ['perekonomian', 'kependudukan'],
    'Perencanaan Wilayah & Kota (PWK)': ['perekonomian', 'kependudukan', 'kemiskinan'],
    'Teknik Industri': ['perekonomian', 'tenaga_kerja'],
    'Teknik Mesin': ['perekonomian', 'tenaga_kerja'],
    'Teknik Elektro': ['perekonomian', 'tenaga_kerja'],
    'Teknik Kimia': ['perekonomian', 'tenaga_kerja'],
    'Teknik Lingkungan': ['perekonomian', 'kependudukan', 'ipm'],
    'Ekonomi Pembangunan': ['perekonomian', 'kemiskinan', 'kesejahteraan'],
    'Ilmu Ekonomi': ['perekonomian', 'kemiskinan', 'kesejahteraan'],
    'Manajemen': ['perekonomian', 'tenaga_kerja', 'kesejahteraan'],
    'Bisnis': ['perekonomian', 'tenaga_kerja', 'kesejahteraan'],
    'Kewirausahaan': ['perekonomian', 'tenaga_kerja'],
    'Akuntansi': ['perekonomian', 'kesejahteraan'],
    'Keuangan': ['perekonomian', 'kesejahteraan'],
    'Statistika': ['perekonomian', 'ipm', 'kemiskinan'],
    'Matematika': ['perekonomian', 'ipm'],
    'Fisika': ['ipm', 'perekonomian'],
    'Kimia': ['ipm', 'perekonomian'],
    'Biologi': ['pertanian', 'ipm'],
    'Hukum': ['kependudukan', 'kesejahteraan', 'kemiskinan'],
    'Ilmu Administrasi Publik': ['kependudukan', 'kesejahteraan', 'kemiskinan'],
    'Ilmu Administrasi Bisnis': ['perekonomian', 'tenaga_kerja'],
    'Ilmu Komunikasi': ['kependudukan', 'kesejahteraan'],
    'Hubungan Internasional': ['perekonomian', 'kependudukan'],
    'Sosiologi': ['kemiskinan', 'kependudukan', 'kesejahteraan'],
    'Psikologi': ['kesejahteraan', 'ipm'],
    'Antropologi': ['kependudukan', 'kemiskinan', 'kesejahteraan'],
    'Pendidikan / Keguruan': ['ipm', 'kesejahteraan'],
    'Pertanian': ['pertanian', 'perekonomian'],
    'Agribisnis': ['pertanian', 'perekonomian'],
    'Kehutanan': ['pertanian', 'perekonomian'],
    'Peternakan': ['pertanian', 'perekonomian'],
    'Kedokteran': ['ipm', 'kesejahteraan'],
    'Kesehatan Masyarakat': ['ipm', 'kesejahteraan', 'kemiskinan'],
    'Farmasi': ['ipm', 'kesejahteraan'],
    'Keperawatan': ['ipm', 'kesejahteraan'],
    'Gizi': ['ipm', 'kemiskinan', 'kesejahteraan'],
    'Pariwisata': ['perekonomian', 'kesejahteraan'],
    'Perhotelan': ['perekonomian', 'tenaga_kerja'],
    'Desain Komunikasi Visual (DKV)': ['perekonomian', 'tenaga_kerja'],
    'Arsitektur': ['perekonomian', 'kependudukan'],
    'Sastra / Bahasa': ['ipm', 'kependudukan'],
    'Seni & Kriya': ['perekonomian', 'kesejahteraan'],
    'Lainnya': ['perekonomian', 'kependudukan'],
    'Umum': ['perekonomian', 'kependudukan']
  };

  // 3. Mengambil daftar mapping seluruh jurusan dan sektor dari Supabase (Single Source of Truth)
  static Future<Map<String, List<String>>> getMajorSectorMapping() async {
    if (_cachedMajorSectorMapping != null && _cachedMajorSectorMapping!.isNotEmpty) {
      return _cachedMajorSectorMapping!;
    }
    try {
      // Query major with their recommended categories via junction table
      final List<dynamic> data = await _client
          .from('major')
          .select('major, major_recommendations(categories(category))')
          .order('major', ascending: true);

      if (data.isNotEmpty) {
        final map = <String, List<String>>{};
        for (final row in data) {
          final majorName = row['major']?.toString() ?? '';
          final recs = row['major_recommendations'] as List<dynamic>? ?? [];
          final sectors = recs
              .map((r) => (r['categories']?['category'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
          if (majorName.isNotEmpty && sectors.isNotEmpty) {
            map[majorName] = sectors;
          }
        }
        if (map.isNotEmpty) {
          _cachedMajorSectorMapping = map;
          return map;
        }
      }
    } catch (e) {
      print("Info: Memakai fallback default mapping jurusan: $e");
    }
    _cachedMajorSectorMapping = Map<String, List<String>>.from(defaultMajorSectorMapping);
    return _cachedMajorSectorMapping!;
  }

  // Ambil rekomendasi sektor awal berdasarkan Jurusan (Langsung dari Map)
  static Future<List<String>> getRelevantSectorsForMajor(String major) async {
    final mapping = await getMajorSectorMapping();
    return mapping[major] ?? defaultMajorSectorMapping[major] ?? ['perekonomian', 'kependudukan'];
  }

  static List<Map<String, dynamic>>? _cachedRecommendations;
  static Map<String, double>? _cachedSectorScores;
  static List<Map<String, dynamic>>? _cachedRecentlyViewed;

  // 4. Panggil RPC Supabase untuk mendapatkan Konten Terpersonalisasi
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({int limit = 6}) async {
    try {
      final profileId = await _getProfileIdentifier();
      final List<dynamic> response = await _client.rpc(
        'get_personalized_recommendations_by_user',
        params: {
          'input_user_id': profileId,
          'rec_limit': limit + 6,
        },
      ).timeout(const Duration(seconds: 8));
      
      const validSectors = {
        'perekonomian', 'ekonomi',
        'tenaga_kerja', 'ketenagakerjaan',
        'ipm',
        'kemiskinan',
        'kependudukan',
        'pertanian',
        'kesejahteraan',
      };

      final result = List<Map<String, dynamic>>.from(response).where((item) {
        final sector = (item['sector_category'] ?? '').toString().toLowerCase();
        final title = (item['content_title'] ?? item['item_name'] ?? '').toString().toLowerCase();
        
        if (!validSectors.contains(sector)) return false;
        if (title.startsWith('halaman') ||
            title.contains('kontak') ||
            title.contains('profil') ||
            title.contains('login') ||
            title.contains('logout') ||
            title.contains('temukan')) {
          return false;
        }
        return true;
      }).take(limit).toList();

      if (result.isNotEmpty) {
        _cachedRecommendations = result;
      }
      return result.isNotEmpty ? result : (_cachedRecommendations ?? []);
    } catch (e) {
      print("Error fetching personalized recommendations: $e");
      return _cachedRecommendations ?? [];
    }
  }

  /// Mengambil skor preferensi per sektor untuk akun/user ini.
  /// Digunakan untuk mengurutkan 3 ikon kategori dinamis di beranda.
  static Future<Map<String, double>> getSectorScoresForUser() async {
    try {
      final profileId = await _getProfileIdentifier();
      final List<dynamic> response = await _client.rpc(
        'get_sector_scores_for_user',
        params: {'input_user_id': profileId},
      ).timeout(const Duration(seconds: 8));
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

  // Alias backwards-compatibility
  static Future<Map<String, double>> getSectorScoresForDevice() => getSectorScoresForUser();

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
        return 'ekonomi.png';
    }
  }

  // Wrapper untuk dipanggil oleh widget visualisasi rekomendasi sektoral existing
  static Future<List<RecommendedItem>> getSectorRecommendations({String? userId, int limit = 2}) async {
    try {
      final list = await getPersonalizedRecommendations(limit: limit + 5);
      
      const validSectors = {
        'perekonomian', 'ekonomi',
        'tenaga_kerja', 'ketenagakerjaan',
        'ipm',
        'kemiskinan',
        'kependudukan',
        'pertanian',
        'kesejahteraan',
      };

      final filteredList = list.where((item) {
        final sector = (item['sector_category'] ?? '').toString().toLowerCase();
        final title = (item['content_title'] ?? item['item_name'] ?? '').toString();
        final titleLower = title.toLowerCase();

        if (!validSectors.contains(sector)) return false;
        if (titleLower.startsWith('halaman') ||
            titleLower.contains('kontak') ||
            titleLower.contains('profil') ||
            titleLower.contains('login') ||
            titleLower.contains('logout') ||
            titleLower.contains('temukan')) {
          return false;
        }
        return true;
      }).take(limit).toList();

      if (filteredList.isEmpty) {
        // Ambil sektor preferensi pengguna dari user_interests
        final profileId = await _getProfileIdentifier();
        List<String> preferredSectors = [];
        try {
          final userData = await _client
              .from('user_all')
              .select('id_user')
              .eq('email', profileId)
              .maybeSingle();
          if (userData != null) {
            final userId = userData['id_user'] as String;
            final List<dynamic> interests = await _client
                .from('user_interests')
                .select('categories(category)')
                .eq('user_id', userId);
            preferredSectors = interests
                .map((i) => (i['categories']?['category'] ?? '').toString())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } catch (_) {}

        if (preferredSectors.isNotEmpty) {
          return preferredSectors.take(limit).map((s) => _getDefaultItemForSector(s)).toList();
        }

        // Fallback default jika belum ada preferensi
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

      return filteredList.map((item) {
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

  static RecommendedItem _getDefaultItemForSector(String sector) {
    switch (sector.toLowerCase()) {
      case 'perekonomian':
      case 'ekonomi':
        return RecommendedItem(
          title: 'Laju Pertumbuhan Ekonomi (LPE)',
          route: '/LajuPertumbuhan',
          icon: 'ekonomi.png',
          description: 'Perkembangan laju pertumbuhan ekonomi Kota Malang terbaru.',
        );
      case 'tenaga_kerja':
      case 'ketenagakerjaan':
        return RecommendedItem(
          title: 'Tingkat Pengangguran Terbuka',
          route: '/TingkatPengangguran',
          icon: 'ketenagakerjaan.png',
          description: 'Data dan persentase pengangguran di Kota Malang.',
        );
      case 'ipm':
        return RecommendedItem(
          title: 'Usia Harapan Hidup',
          route: '/UsiaHarapanHidup',
          icon: 'ipm.png',
          description: 'Perkembangan angka harapan hidup masyarakat Kota Malang.',
        );
      case 'kemiskinan':
        return RecommendedItem(
          title: 'Tingkat Kemiskinan',
          route: '/TingkatKemiskinan',
          icon: 'kemiskinan.png',
          description: 'Persentase dan perkembangan kemiskinan Kota Malang.',
        );
      case 'kependudukan':
        return RecommendedItem(
          title: 'Penduduk Menurut Kecamatan',
          route: '/PendudukKec',
          icon: 'kependudukan.png',
          description: 'Informasi jumlah penduduk di tiap kecamatan Kota Malang.',
        );
      case 'kesejahteraan':
        return RecommendedItem(
          title: 'Gini Rasio',
          route: '/GiniRasio',
          icon: 'kesejahteraan.png',
          description: 'Tingkat ketimpangan pendapatan penduduk Kota Malang.',
        );
      case 'pertanian':
        return RecommendedItem(
          title: 'Produksi Padi & Beras',
          route: '/ProduksiPadi',
          icon: 'pertanian.png',
          description: 'Data luas panen dan produksi padi di Kota Malang.',
        );
      default:
        return RecommendedItem(
          title: 'Penduduk Menurut Kecamatan',
          route: '/PendudukKec',
          icon: 'kependudukan.png',
          description: 'Informasi demografi Kota Malang terbaru.',
        );
    }
  }

  // 5. Ambil data aktivitas Terakhir Dilihat (Recently Viewed)
  static Future<List<Map<String, dynamic>>> getRecentlyViewed({int limit = 5}) async {
    try {
      final user = _client.auth.currentUser;
      final userEmail = user?.email;
      final userId = user?.id;

      // Filter terisolasi: Hanya ambil riwayat untuk akun pengguna yang sedang login.
      final filterOr = <String>[];
      if (userEmail != null && userEmail.isNotEmpty) {
        filterOr.add('user_id.eq.$userEmail');
      }
      if (userId != null && userId.isNotEmpty) {
        filterOr.add('user_id.eq.$userId');
      }

      // Jika belum login (Pengguna Anonim / Guest), tidak bisa menampilkan riwayat
      if (filterOr.isEmpty) {
        return [];
      }

      final filterStr = filterOr.join(',');

      final List<dynamic> response = await _client
          .from('activity_logs')
          .select('title, category_id, module_name, timestamp, action_type, contents_id_content, categories(category)')
          .or(filterStr)
          .inFilter('action_type', ['view_pdf', 'view_brs_pdf', 'view_publikasi_pdf', 'download_file', 'view_page'])
          .order('timestamp', ascending: false)
          .limit(limit * 4)
          .timeout(const Duration(seconds: 8));

      const validSectors = {
        'perekonomian', 'ekonomi',
        'tenaga_kerja', 'ketenagakerjaan',
        'ipm',
        'kemiskinan',
        'kependudukan',
        'pertanian',
        'kesejahteraan',
      };

      // De-duplikasi nama item konten dalam memori
      final seen = <String>{};
      final uniqueList = <Map<String, dynamic>>[];
      for (var item in response) {
        final name = (item['title'] as String? ?? '').trim();
        final nameLower = name.toLowerCase();
        final sector = (item['categories']?['category'] ?? item['module_name'] ?? '').toString().toLowerCase();

        if (name.isEmpty) continue;
        if (!validSectors.contains(sector)) continue;
        if (nameLower.startsWith('halaman') ||
            nameLower.contains('kontak') ||
            nameLower.contains('profil') ||
            nameLower.contains('login') ||
            nameLower.contains('logout') ||
            nameLower.contains('temukan')) {
          continue;
        }

        if (!seen.contains(name)) {
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

  /// Sync list item BPS API ke tabel 'contents' Supabase (dikelola oleh centralized sync)
  static Future<void> syncContentItems(List<Map<String, dynamic>> items, String actionType) async {
    // Database contents disinkronkan secara terpusat oleh sync script / backend cron
  }
}
