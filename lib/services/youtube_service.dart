import 'dart:convert';
import 'dart:developer';
import 'package:mboistats/models/youtube_video.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- IMPORT BARU UNTUK SUPABASE ---
import 'package:mboistats/main.dart'; // Untuk client 'supabase' global
import 'package:supabase_flutter/supabase_flutter.dart';


class YoutubeService {
  final String _tableName = 'youtube_links';
  Future<YoutubeVideoResult> getVideos({
    int page = 1,
    DateTime? publishedAfter,
    DateTime? publishedBefore,
  }) async {
    const int pageSize = 10; 
    final int from = (page - 1) * pageSize;
    final int to = from + pageSize - 1;

    log("Memanggil Supabase tabel '$_tableName': Halaman $page (baris $from-$to)", name: "YoutubeService");

    try {
      dynamic query = supabase
          .from(_tableName)
          .select('*');
      query = query.not('title', 'ilike', '%[Private video]%');
      if (publishedAfter != null) {
        query = query.gte('created_at', publishedAfter.toIso8601String());
      }
      if (publishedBefore != null) {
        query = query.lte('created_at', publishedBefore.toIso8601String());
      }
      query = query.order('created_at', ascending: false);
      query = query.range(from, to);
      final response = await query.count(CountOption.exact);
      final int totalResults = response.count ?? 0; 
      final List<dynamic> data = response.data;
      final List<YoutubeVideo> videos = data
          .map((item) => YoutubeVideo.fromSupabase(item as Map<String, dynamic>))
          .toList();
      int totalPages = 1;
      if (totalResults > 0) {
        totalPages = (totalResults / pageSize).ceil();
      }
      return YoutubeVideoResult(
        videos: videos,
        currentPage: page,
        totalPages: totalPages,
        totalResults: totalResults,
      );

    } catch (e) {
      log("Error koneksi ke Supabase: $e", name: "YoutubeService");
      if (e is PostgrestException) {
        log("Error Supabase Detail: ${e.message}", name: "YoutubeService");
        throw Exception(
            "Gagal mengambil data dari Supabase: ${e.message}. (Cek RLS/Nama Tabel?)");
      }
      throw Exception(
          "Gagal terhubung ke Server. Periksa koneksi internet Anda.");
    }
  }
}