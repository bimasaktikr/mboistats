import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk membaca data YouTube dari tabel Supabase `youtube_streams`.
/// Tidak ada panggilan langsung ke YouTube API dari Flutter.
/// Semua data YouTube disinkronkan otomatis oleh Supabase pg_cron.
class YouTubeService {
  static final _client = Supabase.instance.client;

  /// Mengambil data live stream yang sedang aktif.
  /// Mengembalikan null jika tidak ada siaran langsung.
  static Future<Map<String, dynamic>?> getLiveStream() async {
    try {
      final response = await _client
          .from('youtube_streams')
          .select()
          .eq('is_live', true)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching live stream: $e');
      return null;
    }
  }

  /// Mengambil daftar rekaman siaran pers (arsip video) dari Supabase.
  /// Filter opsional berdasarkan bulan dan tahun.
  static Future<List<Map<String, dynamic>>> getArchivedStreams({
    int? month,
    int? year,
  }) async {
    try {
      var query = _client
          .from('youtube_streams')
          .select()
          .eq('is_live', false)
          .order('published_at', ascending: false);

      final List<dynamic> response = await query;

      // Filter bulan & tahun di Dart karena Supabase PostgREST filter
      // untuk EXTRACT(MONTH FROM ...) tidak trivial
      List<Map<String, dynamic>> results =
          response.map((e) => Map<String, dynamic>.from(e)).toList();

      if (year != null) {
        results = results.where((item) {
          final publishedAt = item['published_at'];
          if (publishedAt == null) return false;
          final date = DateTime.tryParse(publishedAt.toString());
          return date != null && date.year == year;
        }).toList();
      }

      if (month != null) {
        results = results.where((item) {
          final publishedAt = item['published_at'];
          if (publishedAt == null) return false;
          final date = DateTime.tryParse(publishedAt.toString());
          return date != null && date.month == month;
        }).toList();
      }

      return results;
    } catch (e) {
      print('Error fetching archived streams: $e');
      return [];
    }
  }

  /// Mengambil beberapa video terbaru untuk section di Data Page.
  static Future<List<Map<String, dynamic>>> getRecentStreams({int limit = 2}) async {
    try {
      final List<dynamic> response = await _client
          .from('youtube_streams')
          .select()
          .eq('is_live', false)
          .order('published_at', ascending: false)
          .limit(limit);

      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error fetching recent streams: $e');
      return [];
    }
  }

  /// Mengambil daftar tahun unik yang tersedia di arsip.
  static Future<List<int>> getAvailableYears() async {
    try {
      final List<dynamic> response = await _client
          .from('youtube_streams')
          .select('published_at')
          .eq('is_live', false)
          .order('published_at', ascending: false);

      final years = <int>{};
      for (final item in response) {
        final publishedAt = item['published_at'];
        if (publishedAt != null) {
          final date = DateTime.tryParse(publishedAt.toString());
          if (date != null) years.add(date.year);
        }
      }
      return years.toList()..sort((a, b) => b.compareTo(a));
    } catch (e) {
      print('Error fetching available years: $e');
      return [DateTime.now().year];
    }
  }
}
