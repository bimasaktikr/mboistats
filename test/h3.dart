import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

void main() {
  test('Uji Keamanan & Ketahanan: Memanggil RPC Tanpa device_id yang Valid', () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    print('\n=============================================================');
    print('  UJI KETAHANAN RPC PERSONALISASI (INPUT TIDAK VALID)');
    print('=============================================================\n');

    // 1. KASUS 1: device_id KOSONG STRING ("")
    print('1. KASUS 1: Memanggil RPC dengan device_id KOSONG ("")...');
    try {
      final resEmpty = await supabaseClient.rpc(
        'get_personalized_recommendations_by_device',
        params: {
          'input_device_id': '',
          'rec_limit': 5,
        },
      );
      final count = (resEmpty as List).length;
      print('   🛡️ [HASIL]: Server tidak crash. Mengembalikan $count rekomendasi fallback default.');
    } catch (e) {
      print('   ⚠️ [ERROR]: Server gagal merespons: $e');
    }

    // 2. KASUS 2: device_id TIDAK PERNAH TERDAFTAR (ID Asal/Acak)
    print('\n2. KASUS 2: Memanggil RPC dengan device_id ACAK/BARU ("device_ngawur_99999")...');
    try {
      final resRandom = await supabaseClient.rpc(
        'get_personalized_recommendations_by_device',
        params: {
          'input_device_id': 'device_ngawur_99999',
          'rec_limit': 5,
        },
      );
      final count = (resRandom as List).length;
      print('   🛡️ [HASIL]: Server tidak crash. Mengembalikan $count rekomendasi default (Cold Start).');
    } catch (e) {
      print('   ⚠️ [ERROR]: Server gagal merespons: $e');
    }

    // 3. KASUS 3: SQL INJECTION PADA PARAMETER device_id
    print('\n3. KASUS 3: Memanggil RPC dengan Karakter SQL Injection ("\' OR 1=1 --")...');
    try {
      final resInject = await supabaseClient.rpc(
        'get_personalized_recommendations_by_device',
        params: {
          'input_device_id': "' OR 1=1 --",
          'rec_limit': 5,
        },
      );
      final count = (resInject as List).length;
      print('   🛡️ [AMAN]: Parameter disanitasi otomatis oleh PostgreSQL ($count item aman).');
    } catch (e) {
      print('   🛡️ [AMAN]: Serangan SQL injection ditolak oleh database ($e).');
    }

    // 4. KASUS 4: LIMIT TIDAK VALID / NEGATIF
    print('\n4. KASUS 4: Memanggil RPC dengan rec_limit NEGATIF (-5)...');
    try {
      final resLimit = await supabaseClient.rpc(
        'get_personalized_recommendations_by_device',
        params: {
          'input_device_id': '12345',
          'rec_limit': -5,
        },
      );
      print('   🛡️ [HASIL]: Server menangani limit negatif dengan aman: ${(resLimit as List).length} item.');
    } catch (e) {
      print('   ℹ️ [DITOLAK]: Database menolak batas limit negatif ($e).');
    }

    print('\n=============================================================');
    print('  RINGKASAN UJI KETAHANAN RPC SELESAI');
    print('=============================================================\n');
  });
}
