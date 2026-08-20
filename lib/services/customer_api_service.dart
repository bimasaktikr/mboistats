import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mboistats/config/api_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data Model Customer yang didapatkan dari API Buku Tamu
class CustomerProfileData {
  final String? name;
  final String? email;
  final String? phone;
  final int? age;
  final String? gender;
  final int? workId;
  final int? educationId;
  final int? universityId;
  final int? institutionId;

  // Nama Asli Relasi Tabel (Pekerjaan, Pendidikan, Universitas, Instansi)
  final String? workName;
  final String? educationName;
  final String? universityName;
  final String? institutionName;

  CustomerProfileData({
    this.name,
    this.email,
    this.phone,
    this.age,
    this.gender,
    this.workId,
    this.educationId,
    this.universityId,
    this.institutionId,
    this.workName,
    this.educationName,
    this.universityName,
    this.institutionName,
  });

  factory CustomerProfileData.fromJson(Map<String, dynamic> json) {
    return CustomerProfileData(
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender'] as String?,
      workId: json['work_id'] is int
          ? json['work_id'] as int
          : int.tryParse(json['work_id']?.toString() ?? ''),
      educationId: json['education_id'] is int
          ? json['education_id'] as int
          : int.tryParse(json['education_id']?.toString() ?? ''),
      universityId: json['university_id'] is int
          ? json['university_id'] as int
          : int.tryParse(json['university_id']?.toString() ?? ''),
      institutionId: json['institution_id'] is int
          ? json['institution_id'] as int
          : int.tryParse(json['institution_id']?.toString() ?? ''),
          
      // Ekstrak Nama Relasi (Mendukung Format Flat API maupun Nested Object Supabase)
      workName: json['work_name'] ?? (json['works'] is Map ? json['works']['name'] : null),
      educationName: json['education_name'] ?? (json['education'] is Map ? json['education']['name'] : null),
      universityName: json['university_name'] ?? (json['universities'] is Map ? json['universities']['name'] : null),
      institutionName: json['institution_name'] ?? (json['institutions'] is Map ? json['institutions']['name'] : null),
    );
  }
}

/// Service untuk menghubungkan Aplikasi Flutter dengan API Buku Tamu
class CustomerApiService {
  /// Mengambil data customer berdasarkan email dari API Endpoint
  static Future<CustomerProfileData?> getCustomerByEmail(String email) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.customerEndpoint}?email=${Uri.encodeComponent(email)}');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);

        // Menangani jika API mengembalikan format { "data": {...} } atau langsung json object
        final dataJson = (body is Map<String, dynamic> && body.containsKey('data'))
            ? body['data']
            : body;

        if (dataJson != null && dataJson is Map<String, dynamic>) {
          return CustomerProfileData.fromJson(dataJson);
        }
      }
    } catch (_) {
      // Jika server PHP lokal offline / Connection refused, fallback otomatis ke Supabase
    }
    return await getCustomerFromSupabase(email);
  }

  /// Mengambil data customer langsung dari Supabase Cloud (tabel user_all)
  static Future<CustomerProfileData?> getCustomerFromSupabase(String email) async {
    try {
      final data = await Supabase.instance.client
          .from('user_all')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (data != null) {
        return CustomerProfileData.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print("getCustomerFromSupabase Error: $e");
      return null;
    }
  }

  /// Mengambil data customer milik user yang sedang aktif login
  static Future<CustomerProfileData?> getCurrentUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) return null;
    return await getCustomerFromSupabase(user.email!);
  }

  /// Memperbarui data pengguna di tabel user_all berdasarkan email
  static Future<bool> updateCustomerInSupabase({
    required String email,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      await Supabase.instance.client
          .from('user_all')
          .update(updateData)
          .eq('email', email);
      return true;
    } catch (e) {
      print("updateCustomerInSupabase Error: $e");
      return false;
    }
  }
}
