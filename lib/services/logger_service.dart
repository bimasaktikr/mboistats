import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

class LoggerService {
  static String? _deviceId;
  static bool _isInitialized = false;

  /// Inisialisasi Supabase client. Dipanggil sekali saat app startup (`main.dart`).
  static Future<void> init() async {
    if (_isInitialized) return;
    
    // Periksa apakah credentials sudah diisi
    if (SupabaseConfig.url == 'YOUR_SUPABASE_URL' || 
        SupabaseConfig.anonKey == 'YOUR_SUPABASE_ANON_KEY') {
      print('Warning: Supabase credentials are not set. Logging to Supabase will be bypassed (simulation only).');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _isInitialized = true;
      print('Supabase logger service initialized successfully.');
    } catch (e) {
      print('Error initializing Supabase: $e');
    }
  }

  /// Mengambil Unique Device ID secara aman untuk Android & iOS.
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // androidInfo.id mengembalikan ID perangkat unik yang konsisten
        _deviceId = androidInfo.id; 
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // identifierForVendor mengembalikan ID vendor unik perangkat iOS
        _deviceId = iosInfo.identifierForVendor; 
      } else {
        _deviceId = 'desktop_or_web';
      }
    } catch (e) {
      _deviceId = 'unknown_device_err_${e.toString().hashCode}';
    }
    return _deviceId ?? 'unknown_device';
  }

  /// Mengirimkan log aktivitas pengguna ke Supabase secara asinkron (tidak memblokir UI thread).
  /// [sectorCategory] : nama kategori menu/sektor (contoh: kependudukan, kemiskinan, pertanian).
  /// [itemName] : sub menu/fitur yang diklik/diakses (contoh: 'Penduduk Menurut JK').
  /// [actionType] : aksi yang dilakukan (contoh: 'view_page', 'download_pdf').
  /// [userId] : kolom opsional untuk diisi User ID setelah SSO diintegrasikan (Checkpoint 3).
  static Future<void> logActivity({
    required String sectorCategory,
    required String itemName,
    required String actionType,
    String? userId,
    String? coverUrl,
    String? contentUrl,
  }) async {
    final deviceId = await getDeviceId();
    final platformName = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
    final currentUser = Supabase.instance.client.auth.currentUser;
    final activeUserId = userId ?? currentUser?.email ?? currentUser?.id;
    final accountIdentifier = currentUser?.email ?? currentUser?.id ?? "Anonymous";

    // Selalu cetak log lokal untuk keperluan debugging pengembang
    print('Activity Logged -> Platform: $platformName | Account: $accountIdentifier | Device: $deviceId | Sektor: $sectorCategory | Item: $itemName | Aksi: $actionType | Cover: $coverUrl | Content: $contentUrl');

    if (!_isInitialized) {
      return;
    }

    // Eksekusi POST request secara non-blocking
    Supabase.instance.client.from('activity_logs').insert({
      'device_id': deviceId,
      'action_type': actionType,
      'sector_category': sectorCategory,
      'item_name': itemName,
      'platform': platformName,
      'user_id': activeUserId,
      'cover_url': coverUrl,
      'content_url': contentUrl,
    }).then((_) {
      print('Activity successfully synced with Supabase.');
    }).catchError((error) {
      print('Failed to sync log to Supabase: $error');
    });
  }

  /// Mengklasifikasikan sektor berdasarkan judul/nama item secara otomatis.
  /// Digunakan agar log dari BRS/Infografis/Publikasi tercatat dengan sektor yang tepat.
  static String classifySector(String title) {
    final text = title.toLowerCase();
    // PEREKONOMIAN
    if (text.contains('inflasi') || text.contains('pdrb') || text.contains('ekonomi') ||
        text.contains('hotel') || text.contains('penghunian') || text.contains('tpk') ||
        text.contains('pariwisata') || text.contains('wisatawan') || text.contains('industri') ||
        text.contains('perusahaan') || text.contains('usaha') || text.contains('perdagangan') ||
        text.contains('ekspor') || text.contains('impor') || text.contains('konstruksi') ||
        text.contains('transportasi') || text.contains('laju pertumbuhan')) {
      return 'PEREKONOMIAN';
    }
    // KEMISKINAN
    if (text.contains('kemiskinan') || text.contains('miskin')) return 'KEMISKINAN';
    // KETENAGAKERJAAN
    if (text.contains('kerja') || text.contains('pengangguran') || text.contains('tpt') ||
        text.contains('tenaga') || text.contains('upah') || text.contains('buruh')) {
      return 'KETENAGAKERJAAN';
    }
    // IPM
    if (text.contains('ipm') || text.contains('pembangunan manusia') ||
        text.contains('sekolah') || text.contains('harapan hidup') ||
        text.contains('melek huruf') || text.contains('pendidikan') ||
        text.contains('gender') || text.contains('ketimpangan')) {
      return 'IPM';
    }
    // KEPENDUDUKAN
    if (text.contains('penduduk') || text.contains('kecamatan') || text.contains('dalam angka') ||
        text.contains('demografi') || text.contains('kelahiran') || text.contains('kematian') ||
        text.contains('migrasi') || text.contains('sensus') || text.contains('potensi desa') ||
        text.contains('statistik daerah')) {
      return 'KEPENDUDUKAN';
    }
    // PERTANIAN
    if (text.contains('panen') || text.contains('padi') || text.contains('beras') ||
        text.contains('pertanian') || text.contains('tanaman') || text.contains('ternak') ||
        text.contains('perikanan') || text.contains('hortikultura')) {
      return 'PERTANIAN';
    }
    // KESEJAHTERAAN
    if (text.contains('pengeluaran') || text.contains('kesejahteraan') || text.contains('gini') ||
        text.contains('konsumsi') || text.contains('sosial') || text.contains('rumah tangga') ||
        text.contains('susenas')) {
      return 'KESEJAHTERAAN';
    }
    return 'BERITA';
  }
}
