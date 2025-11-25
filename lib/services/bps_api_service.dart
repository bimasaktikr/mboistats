import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service terpusat untuk semua panggilan ke webapi.bps.go.id
class BpsApiService {
  final String _baseUrl = "http://webapi.bps.go.id/v1/api/list";
  
  // Ambil API key dari .env, BUKAN hardcode
  final String _apiKey = dotenv.env['BPS_API_KEY'] ?? '';

  /// Fungsi helper generik untuk mengambil data dari API BPS
  Future<List<Map<String, dynamic>>> _fetchData(String model, int page) async {
    // Pemeriksaan keamanan
    if (_apiKey.isEmpty) {
      print("FATAL: BPS_API_KEY tidak ditemukan di file .env");
      throw Exception('BPS_API_KEY tidak ditemukan di file .env');
    }

    final String apiUrl =
        "$_baseUrl/model/$model/lang/ind/domain/3573/page/$page/key/$_apiKey";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        // Validasi struktur data BPS
        if (parsed['data'] != null && parsed['data'].length > 1 && parsed['data'][1] is List) {
          return List<Map<String, dynamic>>.from(parsed["data"][1]);
        }
        return []; // Kembalikan list kosong jika data[1] tidak ada
      } else {
        // Gagal mengambil data dari server
        throw Exception('Gagal memuat data $model. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Error koneksi atau lainnya
      print("Error di BpsApiService._fetchData: $e");
      throw Exception('Error: $e');
    }
  }

  /// Mengambil daftar publikasi
  Future<List<Map<String, dynamic>>> getPublikasi(int page) {
    return _fetchData('publication', page);
  }

  /// Mengambil daftar Berita Resmi Statistik (BRS)
  Future<List<Map<String, dynamic>>> getBrs(int page) {
    return _fetchData('pressrelease', page);
  }

  /// Mengambil daftar infografis
  Future<List<Map<String, dynamic>>> getInfografis(int page) {
    return _fetchData('infographic', page);
  }
}