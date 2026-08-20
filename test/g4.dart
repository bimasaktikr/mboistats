import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

// Jumlah pengguna yang membuka Beranda pada saat yang BERSAMAAN
const int CONCURRENT_USERS = 50;

/// Simulasi 1 pengguna yang membuka Beranda
Future<Map<String, dynamic>> simulateSingleUserLoad(int userIndex) async {
  final deviceId = 'concurrent_user_$userIndex';
  final stopwatch = Stopwatch()..start();

  try {
    // 1. Splash check
    await supabaseClient
        .from('device_profiles')
        .select('onboarding_sectors')
        .eq('device_id', deviceId)
        .maybeSingle();

    // 2. Load Beranda (Rekomendasi RPC + Skor Sektor + Riwayat + Cek YouTube)
    final recFuture = supabaseClient.rpc(
      'get_personalized_recommendations_by_device',
      params: {'input_device_id': deviceId, 'rec_limit': 6},
    );

    final sectorFuture = supabaseClient.rpc(
      'get_sector_scores_for_device',
      params: {'input_device_id': deviceId},
    );

    final historyFuture = supabaseClient
        .from('activity_logs')
        .select(
            'item_name, sector_category, created_at, action_type, cover_url, content_url')
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(5);

    final youtubeFuture = supabaseClient
        .from('youtube_streams')
        .select()
        .eq('is_live', true)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    await Future.wait<dynamic>([
      recFuture,
      sectorFuture,
      historyFuture,
      youtubeFuture,
    ]);
    stopwatch.stop();

    return {
      'user': 'User #$userIndex',
      'duration': stopwatch.elapsedMilliseconds,
      'success': true,
    };
  } catch (e) {
    stopwatch.stop();
    return {
      'user': 'User #$userIndex',
      'duration': stopwatch.elapsedMilliseconds,
      'success': false,
      'error': e.toString(),
    };
  }
}

void main() {
  test('Uji Akses Bersamaan (Concurrency Test) Beranda', () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    print('\n=============================================================');
    print('  UJI AKSES BERSAMAAN: $CONCURRENT_USERS PENGGUNA SERENTAK');
    print('=============================================================\n');

    final batchStopwatch = Stopwatch()..start();

    // Tembakkan request $CONCURRENT_USERS pengguna secara BERSAMAAN pada detik yang sama
    final List<Future<Map<String, dynamic>>> tasks = List.generate(
      CONCURRENT_USERS,
      (index) => simulateSingleUserLoad(index + 1),
    );

    final results = await Future.wait(tasks);
    batchStopwatch.stop();

    // Analisis Hasil
    final successfulResults =
        results.where((r) => r['success'] == true).toList();
    final failedResults = results.where((r) => r['success'] == false).toList();

    final List<int> durations =
        successfulResults.map((r) => r['duration'] as int).toList();
    durations.sort();

    final double avgDuration =
        durations.reduce((a, b) => a + b) / durations.length;
    final int minDuration = durations.first;
    final int maxDuration = durations.last;
    final int medianDuration = durations[durations.length ~/ 2];

    print('HASIL EKSEKUSI PER PENGGUNA:');
    for (var res in results) {
      if (res['success'] == true) {
        print('  • ${res['user']} : ${res['duration']} ms (Sukses)');
      } else {
        print('  • ${res['user']} : GAGAL (${res['error']})');
      }
    }

    print('\n=============================================================');
    print('RINGKASAN UJI KONKURENSI ($CONCURRENT_USERS PENGGUNA BERSAMAAN):');
    print(
        '• Total Waktu Selesai Semua : ${batchStopwatch.elapsedMilliseconds} ms');
    print(
        '• Berhasil / Gagal          : ${successfulResults.length} / ${failedResults.length}');
    print('• Response Tercepat         : $minDuration ms');
    print('• Response Terlama          : $maxDuration ms');
    print('• Rata-rata per Pengguna    : ${avgDuration.toStringAsFixed(2)} ms');
    print('• Median (Nilai Tengah)     : $medianDuration ms');
    print('=============================================================\n');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
