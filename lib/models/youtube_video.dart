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

  // Factory "pintar" ini sekarang dapat mem-parsing DUA jenis JSON
  // dari YouTube API:
  // 1. Hasil dari `search.list` (untuk video LIVE)
  // 2. Hasil dari `playlistItems.list` (untuk video playlist)
  factory YoutubeVideo.fromJson(Map<String, dynamic> item) {
    
    try {
      // Cek apakah ini item dari `search.list` (punya key 'id.videoId')
      if (item.containsKey('id') && item['id'] is Map && item['id'].containsKey('videoId')) {
        // Ini adalah item hasil 'Search' (Kemungkinan video LIVE)
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
      // Cek apakah ini item dari `playlistItems.list` (punya key 'snippet.resourceId')
      else if (item.containsKey('snippet') && item['snippet'].containsKey('resourceId')) {
        // Ini adalah item hasil 'Playlist'
        
        // Logika untuk mengambil thumbnail terbaik yang tersedia
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
          isLive: false, // Video dari playlist tidak pernah 'live'
          channelTitle: item['snippet']['videoOwnerChannelTitle'] ?? 'BPS Kota Malang',
          publishedAt: item['snippet']['publishedAt'] ?? '',
          description: item['snippet']['description'] ?? 'Tidak ada deskripsi.',
        );
      } 
      // Fallback jika format tidak dikenali
      else {
        log("Format JSON YouTube tidak dikenali: ${item.toString()}", name: "YoutubeVideoModel");
        throw const FormatException('Format JSON YouTube tidak dikenali.');
      }
    } catch (e) {
      log("Error parsing YoutubeVideo.fromJson: $e \nData: ${item.toString()}", name: "YoutubeVideoModel");
      // Kembalikan video "rusak" agar tidak crash, tapi UI bisa menampilkannya sbg error
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
}

// --- PERUBAHAN BESAR DI MODEL RESULT ---
// Kita tidak lagi menggunakan token, tapi pagination angka
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

  // Factory untuk mem-parsing respons dari server PHP kita
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
// --- AKHIR PERUBAHAN ---