import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

/// Mengukur waktu eksekusi murni dari proses Splash Screen hingga seluruh konten Beranda siap tampil penuh
Future<int> measureSplashScreenToHome({String deviceId = '12345'}) async {
  final totalStopwatch = Stopwatch()..start();

  try {
    // -------------------------------------------------------------
    // FASE 1: PROSES SPLASH SCREEN (MURNI API & LOGIKA)
    // (Pengecekan query status profil di database)
    // -------------------------------------------------------------
    final splashStopwatch = Stopwatch()..start();

    // 1. Query cek status profil pengguna / onboarding
    await supabaseClient
        .from('device_profiles')
        .select('onboarding_sectors')
        .eq('device_id', deviceId)
        .maybeSingle();

    splashStopwatch.stop();
    final splashTime = splashStopwatch.elapsedMilliseconds;

    // -------------------------------------------------------------
    // FASE 2: MEMUAT KONTEN BERANDA HINGGA TAMPIL PENUH
    // (Data Rekomendasi RPC + Urutan Menu Sektor + Riwayat Terakhir)
    // -------------------------------------------------------------
    final homeContentStopwatch = Stopwatch()..start();

    // 1. Data Rekomendasi Personalisasi (RPC)
    final recFuture = supabaseClient.rpc(
      'get_personalized_recommendations_by_device',
      params: {
        'input_device_id': deviceId,
        'rec_limit': 6,
      },
    );

    // 2. Data Skor Urutan Menu Sektor
    final sectorFuture = supabaseClient
        .from('activity_logs')
        .select('sector_category')
        .eq('device_id', deviceId);

    // 3. Data Riwayat Terakhir Dilihat
    final historyFuture = supabaseClient
        .from('activity_logs')
        .select('*')
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(5);
    // 4. Pengecekan Live Stream YouTube (dari HomePage initState)
    final youtubeLiveFuture = supabaseClient
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
      youtubeLiveFuture,
    ]);

    homeContentStopwatch.stop();
    final homeContentTime = homeContentStopwatch.elapsedMilliseconds;

    totalStopwatch.stop();
    final totalTime = totalStopwatch.elapsedMilliseconds;

    final recCount = (results[0] as List).length;

    print(
        '  -> Waktu Splash (Cek Profil): $splashTime ms | Waktu Load Konten Beranda: $homeContentTime ms (Item: $recCount) | Total: $totalTime ms');
    return totalTime;
  } catch (e) {
    totalStopwatch.stop();
    final totalTime = totalStopwatch.elapsedMilliseconds;
    print('  -> Gagal saat memuat: $totalTime ms, Error: $e');
    return totalTime;
  }
}

void main() {
  test('Uji waktu dari splash screen hingga konten Beranda tampil penuh',
      () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    print('\n=============================================================');
    print('  PENGUKURAN WAKTU EKSEKUSI MURNI: SPLASH SCREEN -> BERANDA');
    print('=============================================================\n');

    List<int> durations = [];

    // Menjalankan pengukuran sebanyak 5 kali
    for (int i = 1; i <= 5; i++) {
      print('Percobaan #$i:');
      final duration = await measureSplashScreenToHome(deviceId: '12345');
      durations.add(duration);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Hitung statistik rata-rata, min, dan max
    final double rataRata =
        durations.reduce((a, b) => a + b) / durations.length;
    final int tercepat = durations.reduce((a, b) => a < b ? a : b);
    final int terlama = durations.reduce((a, b) => a > b ? a : b);

    print('\n=============================================================');
    print('Ringkasan Hasil Eksekusi Murni:');
    print('• Waktu Tercepat : $tercepat ms');
    print('• Waktu Terlama  : $terlama ms');
    print('• Rata-rata      : ${rataRata.toStringAsFixed(2)} ms');
    print('=============================================================\n');
  });
}
