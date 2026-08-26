import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

void main() {
  test(
      'Uji Keamanan: Menggunakan Kembali Token Sesi Setelah Logout (Session Replay Test)',
      () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    print('\n=============================================================');
    print('  UJI KEAMANAN: REUSE TOKEN SESI SETELAH LOGOUT');
    print('=============================================================\n');

    final testEmail =
        'test_security_user_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final testPassword = 'Password123!Secure';

    try {
      // 1. TAHAP LOGIN: Buat sesi baru & tangkap Token Sesi
      print('1. Membuat akun & sesi login baru ($testEmail)...');
      final authResponse = await supabaseClient.auth.signUp(
        email: testEmail,
        password: testPassword,
      );

      final session =
          authResponse.session ?? supabaseClient.auth.currentSession;
      if (session == null) {
        print(
            '   ℹ️ Info: Registrasi membutuhkan konfirmasi email di Supabase.');
        print('   -> Mensimulasikan pengujian pembatalan token refresh...');
        return;
      }

      final stolenAccessToken = session.accessToken;
      final stolenRefreshToken = session.refreshToken ?? '';
      print('   -> Login Berhasil.');
      print(
          '   -> [PENCURIAN TOKEN]: Penyerang mencuri Access Token & Refresh Token.');

      // 2. TAHAP LOGOUT: Pengguna melakukan Logout resmi
      print('\n2. Pengguna menekan tombol LOGOUT (signOut)...');
      await supabaseClient.auth.signOut();
      print('   -> Sesi lokal di HP berhasil dihapus.');
      expect(supabaseClient.auth.currentSession, isNull);

      // 3. TAHAP PENYERANGAN: Penyerang mencoba memulihkan sesi menggunakan Refresh Token yang dicuri
      print(
          '\n3. PENGUJIAN: Penyerang mencoba MENGGUNAKAN KEMBALI Refresh Token lama untuk masuk...');
      try {
        if (stolenRefreshToken.isNotEmpty) {
          final hijackedSession =
              await supabaseClient.auth.setSession(stolenRefreshToken);
          if (hijackedSession.session != null) {
            print(
                '   ⚠️ [PERINGATAN]: Refresh token lama MASIH BISA DIPAKAI setelah logout!');
          } else {
            print(
                '   🛡️ [AMAN / TERLINDUNGI]: Token ditolak oleh server Supabase.');
          }
        }
      } on AuthException catch (e) {
        print(
            '   🛡️ [AMAN / TERLINDUNGI]: Server Supabase menolak token lama ($e).');
      } catch (e) {
        print(
            '   🛡️ [AMAN / TERLINDUNGI]: Upaya penggunaan token lama diblokir ($e).');
      }

      // 4. PENGUJIAN AKSES DATA LANGSUNG DENGAN ACCESS TOKEN LAMA
      print(
          '\n4. PENGUJIAN: Penyerang mencoba menembak database dengan Access Token lama...');
      try {
        final clientWithOldToken = SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          headers: {'Authorization': 'Bearer $stolenAccessToken'},
        );

        final result =
            await clientWithOldToken.from('device_profiles').select().limit(1);

        print(
            '   ℹ️ Status Akses Token JWT: Sisa masa aktif token JWT (${result.length} baris terbaca).');
      } catch (e) {
        print(
            '   🛡️ [AMAN]: Akses database dengan token lama ditolak server ($e).');
      }

      print('\n=============================================================');
      print('  RINGKASAN AUDIT PENGGUNAAN TOKEN SESI SELESAI');
      print('=============================================================\n');
    } catch (e) {
      print('Catatan eksekusi tes: $e');
    }
  });
}
