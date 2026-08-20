import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

Future<int> fetchRecommendations(
    {String deviceId = '12345', int limit = 5}) async {
  // 1. Mulai stopwatch
  final stopwatch = Stopwatch()..start();

  try {
    // 2. Panggil RPC Supabase
    final response = await supabaseClient.rpc(
      'get_personalized_recommendations_by_device',
      params: {
        'input_device_id': deviceId,
        'rec_limit': limit,
      },
    );

    // 3. Hentikan stopwatch & cetak hasilnya
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    print(
        'Waktu eksekusi RPC: $elapsed ms (Jumlah data: ${(response as List).length})');
    return elapsed;
  } catch (e) {
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    print('RPC Gagal. Waktu hingga gagal: $elapsed ms, Error: $e');
    return elapsed;
  }
}

void main() {
  test('Uji waktu eksekusi fetchRecommendations', () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    print('\n--- Memulai Pengujian RPC (5 Kali Eksekusi) ---');

    List<int> durations = [];

    // Menjalankan fetchRecommendations sebanyak 5 kali
    for (int i = 1; i <= 5; i++) {
      print('Percobaan #$i:');
      final duration = await fetchRecommendations(deviceId: '12345', limit: 5);
      durations.add(duration);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Hitung rata-rata
    final double rataRata =
        durations.reduce((a, b) => a + b) / durations.length;

    print('\n=========================================');
    print('Ringkasan Hasil Eksekusi:');
    print('• Waktu Tercepat : ${durations.reduce((a, b) => a < b ? a : b)} ms');
    print('• Waktu Terlama  : ${durations.reduce((a, b) => a > b ? a : b)} ms');
    print('• Rata-rata      : ${rataRata.toStringAsFixed(2)} ms');
    print('=========================================\n');
  });
}
