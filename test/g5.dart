import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

// ============================================================================
// KONFIGURASI PENGUJIAN KOMBINASI (DATA BESAR + AKSES BERSAMAAN)
// ============================================================================
const int CONCURRENT_USERS = 20; // Jumlah pengguna yang mengakses serentak
const int LOGS_PER_USER = 100;   // Jumlah riwayat log per pengguna (Total: 20 x 100 = 2.000 log)
const String DEVICE_PREFIX = 'heavy_concurrent_user_';

/// 1. TAHAP SEED: Injeksi Volume Data Riwayat Besar untuk Tiap Pengguna
Future<void> seedHeavyDataForConcurrentUsers({
  required int userCount,
  required int logsPerUser,
}) async {
  final totalLogs = userCount * logsPerUser;
  print('⏳ [SEEK & INJEKSI] Menyiapkan total $totalLogs data log untuk $userCount pengguna...');

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

  for (int u = 1; u <= userCount; u++) {
    final deviceId = '$DEVICE_PREFIX$u';

    // 1. Buat profil preferensi onboarding untuk tiap user
    await supabaseClient.from('device_profiles').upsert({
      'device_id': deviceId,
      'major': 'Statistika',
      'onboarding_sectors': ['perekonomian', 'ipm', 'kemiskinan'],
    });

    // 2. Buat log aktivitas untuk user tersebut
    final List<Map<String, dynamic>> userLogs = [];
    for (int j = 0; j < logsPerUser; j++) {
      final sector = sectors[random.nextInt(sectors.length)];
      final action = actions[random.nextInt(actions.length)];
      final createdAt = now.subtract(Duration(minutes: (j + 1) * 10)).toIso8601String();

      userLogs.add({
        'device_id': deviceId,
        'action_type': action,
        'sector_category': sector,
        'item_name': 'Data Simulasi $sector #$j',
        'platform': 'android',
        'created_at': createdAt,
      });
    }

    await supabaseClient.from('activity_logs').insert(userLogs);
    if (u % 5 == 0 || u == userCount) {
      print('   -> Terinjeksi: ${u * logsPerUser}/$totalLogs log ($u/$userCount user siap)...');
    }
  }

  print(' Injeksi data selesai! Database siap untuk pengujian beban berat.\n');
}

/// 2. SIMULASI: Satu Pengguna Membuka Beranda
Future<Map<String, dynamic>> simulateSingleUserLoad(int userIndex) async {
  final deviceId = '$DEVICE_PREFIX$userIndex';
  final stopwatch = Stopwatch()..start();

  try {
    // A. Cek Profil Splash
    await supabaseClient
        .from('device_profiles')
        .select('onboarding_sectors')
        .eq('device_id', deviceId)
        .maybeSingle();

    // B. Pemuatan Konten Beranda secara Paralel
    // 1. Rekomendasi Personalisasi RPC
    final recFuture = supabaseClient.rpc(
      'get_personalized_recommendations_by_device',
      params: {'input_device_id': deviceId, 'rec_limit': 6},
    );

    // 2. Skor Urutan Menu Sektor RPC
    final sectorFuture = supabaseClient.rpc(
      'get_sector_scores_for_device',
      params: {'input_device_id': deviceId},
    );

    // 3. Riwayat Terakhir Dilihat
    final historyFuture = supabaseClient
        .from('activity_logs')
        .select('item_name, sector_category, created_at, action_type, cover_url, content_url')
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(5);

    // 4. Pengecekan Live YouTube
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

    stopwatch.stop();
    final recCount = (results[0] as List).length;

    return {
      'user': 'User #$userIndex',
      'duration': stopwatch.elapsedMilliseconds,
      'recCount': recCount,
      'success': true,
    };
  } catch (e) {
    stopwatch.stop();
    return {
      'user': 'User #$userIndex',
      'duration': stopwatch.elapsedMilliseconds,
      'recCount': 0,
      'success': false,
      'error': e.toString(),
    };
  }
}

/// 3. TAHAP CLEANUP: Bersihkan Data Uji dari Supabase
Future<void> cleanupHeavyDummyData(int userCount) async {
  print('\n🧹 Membersihkan data simulasi dari database Supabase...');
  for (int u = 1; u <= userCount; u++) {
    final deviceId = '$DEVICE_PREFIX$u';
    await supabaseClient.from('activity_logs').delete().eq('device_id', deviceId);
    await supabaseClient.from('device_profiles').delete().eq('device_id', deviceId);
  }
  print(' Pembersihan selesai.');
}

// ============================================================================
// MAIN TEST RUNNER
// ============================================================================
void main() {
  test('Kombinasi Uji Beban: Volume Data Besar + Akses Bersamaan', () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    final totalLogs = CONCURRENT_USERS * LOGS_PER_USER;

    print('\n=============================================================');
    print('  STRESS TEST GABUNGAN: $CONCURRENT_USERS PENGGUNA SERENTAK');
    print('  DATABASE MEMUAT: $totalLogs LOG AKTIVITAS RIWAYAT');
    print('=============================================================\n');

    try {
      // 1. Injeksi data riwayat simulasi
      await seedHeavyDataForConcurrentUsers(
        userCount: CONCURRENT_USERS,
        logsPerUser: LOGS_PER_USER,
      );

      print('🚀 Memulai pengujian akses serentak $CONCURRENT_USERS pengguna...');
      final batchStopwatch = Stopwatch()..start();

      // 2. Eksekusi request seluruh pengguna BERSAMAAN pada detik yang sama
      final List<Future<Map<String, dynamic>>> tasks = List.generate(
        CONCURRENT_USERS,
        (index) => simulateSingleUserLoad(index + 1),
      );

      final results = await Future.wait(tasks);
      batchStopwatch.stop();

      // 3. Analisis Hasil
      final successfulResults = results.where((r) => r['success'] == true).toList();
      final failedResults = results.where((r) => r['success'] == false).toList();

      final List<int> durations = successfulResults.map((r) => r['duration'] as int).toList();
      durations.sort();

      final double avgDuration = durations.reduce((a, b) => a + b) / durations.length;
      final int minDuration = durations.first;
      final int maxDuration = durations.last;
      final int medianDuration = durations[durations.length ~/ 2];

      print('\nHASIL EKSEKUSI PER PENGGUNA:');
      for (var res in results) {
        if (res['success'] == true) {
          print('  • ${res['user']} : ${res['duration']} ms (Rekomendasi: ${res['recCount']} item)');
        } else {
          print('  • ${res['user']} : GAGAL (${res['error']})');
        }
      }

      print('\n=============================================================');
      print('RINGKASAN UJI KOMBINASI (DATA BESAR + KONKURENSI):');
      print('• Pengguna Serentak         : $CONCURRENT_USERS user');
      print('• Total Data Log Terproses  : $totalLogs baris log');
      print('• Total Waktu Selesai Semua : ${batchStopwatch.elapsedMilliseconds} ms');
      print('• Berhasil / Gagal          : ${successfulResults.length} / ${failedResults.length}');
      print('• Response Tercepat         : $minDuration ms');
      print('• Response Terlama          : $maxDuration ms');
      print('• Rata-rata per Pengguna    : ${avgDuration.toStringAsFixed(2)} ms');
      print('• Median (Nilai Tengah)     : $medianDuration ms');
      print('=============================================================\n');
    } finally {
      // 4. Pembersihan otomatis
      await cleanupHeavyDummyData(CONCURRENT_USERS);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
