import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

const String TEST_DEVICE_ID = 'test_dulu_ya';
const int TOTAL_DUMMY_LOGS =
    2000; // Jumlah log yang ingin disimulasikan (misal: 1000, 2000, 5000)

/// 1. FUNGSI SEED: Memasukkan Ribuan Log Simulasi ke Supabase
Future<void> seedLargeActivityLogs({required int count}) async {
  print(
      '⏳ Menyiapkan $count data log aktivitas simulasi untuk device: $TEST_DEVICE_ID...');

  // Setup Device Profile dummy
  await supabaseClient.from('device_profiles').upsert({
    'device_id': TEST_DEVICE_ID,
    'major': 'Statistika',
    'onboarding_sectors': ['perekonomian', 'ipm', 'kemiskinan'],
  });

  final sectors = [
    'perekonomian',
    'ketenagakerjaan',
    'ipm',
    'kemiskinan',
    'kependudukan',
    'pertanian',
    'kesejahteraan',
  ];

  final actions = ['view_page', 'view_pdf', 'download_file'];
  final random = Random();
  final now = DateTime.now();

  // Kirim dalam batch per 250 data agar tidak melebihi payload limit Supabase
  const int batchSize = 250;
  for (int i = 0; i < count; i += batchSize) {
    final int currentBatchCount =
        (i + batchSize > count) ? (count - i) : batchSize;
    final List<Map<String, dynamic>> batchData = [];

    for (int j = 0; j < currentBatchCount; j++) {
      final sector = sectors[random.nextInt(sectors.length)];
      final action = actions[random.nextInt(actions.length)];
      // Buat timestamp mundur bertahap
      final createdAt =
          now.subtract(Duration(minutes: (i + j) * 5)).toIso8601String();

      batchData.add({
        'device_id': TEST_DEVICE_ID,
        'action_type': action,
        'sector_category': sector,
        'item_name': 'Data Simulasi $sector #${i + j + 1}',
        'platform': 'android',
        'created_at': createdAt,
      });
    }

    await supabaseClient.from('activity_logs').insert(batchData);
    print('   -> Terinjeksi: ${i + currentBatchCount}/$count log...');
  }
  print(' Selesai injeksi data simulasi!\n');
}

/// 2. FUNGSI BENCHMARK: Mengukur Waktu Load Beranda
Future<int> measureHeavyHomeLoad() async {
  final totalStopwatch = Stopwatch()..start();

  try {
    // FASE 1: SPLASH SCREEN (Cek Profil)
    final splashStopwatch = Stopwatch()..start();
    await supabaseClient
        .from('device_profiles')
        .select('onboarding_sectors')
        .eq('device_id', TEST_DEVICE_ID)
        .maybeSingle();
    splashStopwatch.stop();

    // FASE 2: LOAD KONTEN BERANDA (Paralel)
    final homeStopwatch = Stopwatch()..start();

    // 1. Rekomendasi RPC
    final recFuture = supabaseClient.rpc(
      'get_personalized_recommendations_by_device',
      params: {
        'input_device_id': TEST_DEVICE_ID,
        'rec_limit': 6,
      },
    );

    // 2. Skor Sektor RPC
    final sectorFuture = supabaseClient.rpc(
      'get_sector_scores_for_device',
      params: {
        'input_device_id': TEST_DEVICE_ID,
      },
    );

    // 3. Riwayat Terakhir Dilihat
    final historyFuture = supabaseClient
        .from('activity_logs')
        .select(
            'item_name, sector_category, created_at, action_type, cover_url, content_url')
        .eq('device_id', TEST_DEVICE_ID)
        .order('created_at', ascending: false)
        .limit(5);

    // 4. Cek Live YouTube
    final youtubeFuture = supabaseClient
        .from('youtube_streams')
        .select()
        .eq('is_live', true)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final results = await Future.wait<dynamic>([
      recFuture,
      sectorFuture,
      historyFuture,
      youtubeFuture,
    ]);

    homeStopwatch.stop();
    totalStopwatch.stop();

    final totalTime = totalStopwatch.elapsedMilliseconds;
    final homeTime = homeStopwatch.elapsedMilliseconds;
    final splashTime = splashStopwatch.elapsedMilliseconds;
    final recCount = (results[0] as List).length;

    print(
        '  -> Splash: $splashTime ms | Home Load: $homeTime ms (Item Rekomendasi: $recCount) | Total: $totalTime ms');
    return totalTime;
  } catch (e) {
    totalStopwatch.stop();
    print('  -> Error saat mengukur: $e');
    return totalStopwatch.elapsedMilliseconds;
  }
}

/// 3. FUNGSI CLEANUP: Bersihkan Data Uji dari Database
Future<void> cleanupDummyData() async {
  print('\n🧹 Membersihkan data simulasi dari Supabase...');
  await supabaseClient
      .from('activity_logs')
      .delete()
      .eq('device_id', TEST_DEVICE_ID);
  await supabaseClient
      .from('device_profiles')
      .delete()
      .eq('device_id', TEST_DEVICE_ID);
  print(' Pembersihan selesai.');
}

void main() {
  test('Stress Test Waktu Muat Beranda dengan Volume Log Besar', () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    print('\n=============================================================');
    print('  STRESS TEST BERANDA DENGAN $TOTAL_DUMMY_LOGS LOG AKTIVITAS');
    print('=============================================================\n');
    // 1. Injeksi data dummy
    await seedLargeActivityLogs(count: TOTAL_DUMMY_LOGS);

    // 2. Jalankan benchmark 5 kali
    List<int> durations = [];
    for (int i = 1; i <= 5; i++) {
      print('Percobaan #$i:');
      final duration = await measureHeavyHomeLoad();
      durations.add(duration);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 3. Rekap Hasil
    final double rataRata =
        durations.reduce((a, b) => a + b) / durations.length;
    final int tercepat = durations.reduce((a, b) => a < b ? a : b);
    final int terlama = durations.reduce((a, b) => a > b ? a : b);

    print('\n=============================================================');
    print('Ringkasan Hasil Uji Beban ($TOTAL_DUMMY_LOGS baris log):');
    print('• Waktu Tercepat : $tercepat ms');
    print('• Waktu Terlama  : $terlama ms');
    print('• Rata-rata      : ${rataRata.toStringAsFixed(2)} ms');
    print('=============================================================');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
