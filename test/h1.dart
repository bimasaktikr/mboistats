import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

late SupabaseClient supabaseClient;

const String VICTIM_DEVICE_ID = 'victim_device_secret_123';
const String ATTACKER_DEVICE_ID = 'attacker_device_hacker_999';

void main() {
  test('Uji Keamanan: Akses Tidak Sah ke activity_logs Perangkat Lain',
      () async {
    supabaseClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );

    print('\n=============================================================');
    print('  UJI KEAMANAN: AKSES DATA LOG MILIK DEVICE LAIN');
    print('=============================================================\n');

    try {
      // 1. SETUP: Simulasikan ada data rahasia milik "Victim Device" di database
      print(
          '1. Menyiapkan data privat milik Device Korban ($VICTIM_DEVICE_ID)...');
      await supabaseClient.from('activity_logs').insert([
        {
          'device_id': VICTIM_DEVICE_ID,
          'action_type': 'view_pdf',
          'sector_category': 'kemiskinan',
          'item_name': 'Data Rahasia Kemiskinan Kecamatan Klojen',
          'platform': 'android',
        },
        {
          'device_id': VICTIM_DEVICE_ID,
          'action_type': 'download_file',
          'sector_category': 'perekonomian',
          'item_name': 'Laporan Sensitif Pertumbuhan Ekonomi 2026',
          'platform': 'android',
        }
      ]);
      print('   -> Data privat korban berhasil disimpan.\n');

      // 2. PENGUJIAN 1: Penyerang mencoba membaca (SELECT) data milik korban
      print(
          '2. PENGUJIAN: Device Lain ($ATTACKER_DEVICE_ID) mencoba MEMBACA data korban...');
      final leakedData = await supabaseClient
          .from('activity_logs')
          .select('item_name, sector_category, created_at')
          .eq('device_id', VICTIM_DEVICE_ID);

      print(
          '   -> Hasil Query: Ditemukan ${(leakedData as List).length} baris data.');
      if ((leakedData).isEmpty) {
        print(
            '   🛡️ [AMAN / TERLINDUNGI]: Data tidak bocor (RLS aktif memblokir akses).');
      } else {
        print('   ⚠️ [PERINGATAN]: Data berhasil terbaca oleh pihak lain!');
        for (var row in leakedData) {
          print(
              '      • Bocor: ${row['item_name']} (${row['sector_category']})');
        }
      }

      // 3. PENGUJIAN 2: Penyerang mencoba MENGHAPUS (DELETE) data milik korban
      print('\n3. PENGUJIAN: Device Lain mencoba MENGHAPUS data korban...');
      try {
        final deleteResponse = await supabaseClient
            .from('activity_logs')
            .delete()
            .eq('device_id', VICTIM_DEVICE_ID)
            .select();

        if ((deleteResponse as List).isEmpty) {
          print(
              '   🛡️ [AMAN / TERLINDUNGI]: 0 data terhapus. Permintaan DELETE diblokir oleh RLS.');
        } else {
          print(
              '   ⚠️ [PERINGATAN]: Penyerang berhasil menghapus ${deleteResponse.length} baris data.');
        }
      } catch (e) {
        print(
            '   🛡️ [AMAN / TERLINDUNGI]: Akses delete ditolak oleh database ($e).');
      }

      // 4. PENGUJIAN 3: Penyerang mencoba MEMANIPULASI / MENYUNTIK data palsu atas nama korban
      print(
          '\n4. PENGUJIAN: Device Lain mencoba MENULIS log palsu atas nama korban...');
      try {
        await supabaseClient.from('activity_logs').insert({
          'device_id': VICTIM_DEVICE_ID, // Menyamar jadi victim
          'action_type': 'view_page',
          'sector_category': 'pertanian',
          'item_name': 'Log Palsu Disuntik Penyerang',
          'platform': 'attacker_script',
        });
        print(
            '   ℹ️ Catatan: Anonymous device log injection berhasil/diizinkan.');
      } catch (e) {
        print(
            '   🛡️ [AMAN / TERLINDUNGI]: Penulisan log palsu ditolak server ($e).');
      }

      print('\n=============================================================');
      print('  RINGKASAN AUDIT KEAMANAN SELESAI');
      print('=============================================================\n');
    } finally {
      // CLEANUP
      await supabaseClient
          .from('activity_logs')
          .delete()
          .eq('device_id', VICTIM_DEVICE_ID);
    }
  });
}
