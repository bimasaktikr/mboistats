import 'dart:developer';

class YoutubeVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final bool isLive;
  final String channelTitle;
  final String publishedAt;
  final String description;

  YoutubeVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.isLive,
    required this.channelTitle,
    required this.publishedAt,
    required this.description,
  });

  // Factory lama (dari API Python) - Biarkan saja, tidak mengganggu
  factory YoutubeVideo.fromJson(Map<String, dynamic> item) {
    try {
      // Cek apakah ini item dari `search.list`
      if (item.containsKey('id') && item['id'] is Map && item['id'].containsKey('videoId')) {
        return YoutubeVideo(
          id: item['id']['videoId'],
          title: item['snippet']['title'] ?? 'Tanpa Judul',
          thumbnailUrl: item['snippet']['thumbnails']['high']['url'] ?? '',
          isLive: item['snippet']['liveBroadcastContent'] == 'live',
          channelTitle: item['snippet']['channelTitle'] ?? 'BPS Kota Malang',
          publishedAt: item['snippet']['publishedAt'] ?? '',
          description: item['snippet']['description'] ?? 'Tidak ada deskripsi.',
        );
      } 
      // Cek apakah ini item dari `playlistItems.list`
      else if (item.containsKey('snippet') && item['snippet'].containsKey('resourceId')) {
        String thumbUrl = '';
        if (item['snippet']['thumbnails'] != null) {
          if (item['snippet']['thumbnails']['high'] != null) {
            thumbUrl = item['snippet']['thumbnails']['high']['url'];
          } else if (item['snippet']['thumbnails']['medium'] != null) {
            thumbUrl = item['snippet']['thumbnails']['medium']['url'];
          } else if (item['snippet']['thumbnails']['default'] != null) {
            thumbUrl = item['snippet']['thumbnails']['default']['url'];
          }
        }

        return YoutubeVideo(
          id: item['snippet']['resourceId']['videoId'] ?? '',
          title: item['snippet']['title'] ?? 'Tanpa Judul',
          thumbnailUrl: thumbUrl,
          isLive: false, 
          channelTitle: item['snippet']['videoOwnerChannelTitle'] ?? 'BPS Kota Malang',
          publishedAt: item['snippet']['publishedAt'] ?? '',
          description: item['snippet']['description'] ?? 'Tidak ada deskripsi.',
        );
      } 
      else {
        log("Format JSON YouTube tidak dikenali: ${item.toString()}", name: "YoutubeVideoModel");
        throw const FormatException('Format JSON YouTube tidak dikenali.');
      }
    } catch (e) {
      log("Error parsing YoutubeVideo.fromJson: $e \nData: ${item.toString()}", name: "YoutubeVideoModel");
       return YoutubeVideo(
          id: '',
          title: 'Error Parsing Video',
          thumbnailUrl: '',
          isLive: false,
          channelTitle: '',
          publishedAt: '',
          description: 'Data video ini rusak.',
        );
    }
  }

  // --- FACTORY UNTUK SUPABASE (YANG DIPERBARUI) ---
  factory YoutubeVideo.fromSupabase(Map<String, dynamic> item) {
    try {
      return YoutubeVideo(
        id: item['video_id'] ?? '',
        title: item['title'] ?? 'Tanpa Judul',
        thumbnailUrl: item['thumbnail_url'] ?? '',
        
        // --- PERUBAHAN DI SINI ---
        // Kita sekarang membaca kolom baru dari Supabase
        isLive: item['is_live'] ?? false, 
        description: item['description'] ?? 'Tidak ada deskripsi.',
        // --- AKHIR PERUBAHAN ---

        channelTitle: 'BPS Kota Malang', // Tetap hardcode, karena tidak ada di tabel
        publishedAt: item['created_at'] ?? DateTime.now().toIso8601String(), // Gunakan 'created_at' sebagai fallback
      );
    } catch (e) {
      log("Error parsing YoutubeVideo.fromSupabase: $e \nData: ${item.toString()}", name: "YoutubeVideoModel");
       return YoutubeVideo(
          id: '',
          title: 'Error Parsing Video',
          thumbnailUrl: '',
          isLive: false,
          channelTitle: '',
          publishedAt: '',
          description: 'Data video ini rusak.',
        );
    }
  }
  // --- AKHIR FACTORY SUPABASE ---
}

// Model ini (YoutubeVideoResult) tidak perlu diubah.
class YoutubeVideoResult {
  final List<YoutubeVideo> videos;
  final int currentPage;
  final int totalPages;
  final int totalResults;

  YoutubeVideoResult({
    required this.videos,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
  });

  // Factory ini (fromJson) tidak digunakan lagi oleh service Supabase,
  // tapi biarkan saja, tidak mengganggu.
  factory YoutubeVideoResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> items = json['items'] ?? [];
    final List<YoutubeVideo> videos = items
        .map((item) => YoutubeVideo.fromJson(item))
        .toList();

    final Map<String, dynamic> pagination = json['pagination'] ?? {};
    
    return YoutubeVideoResult(
      videos: videos,
      currentPage: pagination['currentPage'] ?? 1,
      totalPages: pagination['totalPages'] ?? 1,
      totalResults: pagination['totalResults'] ?? 0,
    );
  }
}