import 'package:flutter/material.dart';
import 'package:mboistats/services/logger_service.dart';

class ActivityLoggingObserver extends NavigatorObserver {
  // Pemetaan rute (route name) ke kategori sektoral dan nama fitur
  static const Map<String, Map<String, String>> _routeLogs = {
    // IPM
    '/PendudukBekerja': {'sector': 'ipm', 'item': 'Penduduk Bekerja (IPM)'},
    '/UsiaHarapanHidup': {'sector': 'ipm', 'item': 'Usia Harapan Hidup'},
    '/HarapanLamaSekolah': {'sector': 'ipm', 'item': 'Harapan Lama Sekolah'},
    '/RataRataLamaSekolah': {'sector': 'ipm', 'item': 'Rata-Rata Lama Sekolah'},
    '/DayaBeli': {'sector': 'ipm', 'item': 'Daya Beli'},

    // Kependudukan
    '/PendudukJK': {'sector': 'kependudukan', 'item': 'Penduduk Menurut Jenis Kelamin'},
    '/PendudukKec': {'sector': 'kependudukan', 'item': 'Penduduk Menurut Kecamatan'},
    '/PKedungkandang': {'sector': 'kependudukan', 'item': 'Penduduk Kedungkandang'},
    '/PSukun': {'sector': 'kependudukan', 'item': 'Penduduk Sukun'},
    '/PKlojen': {'sector': 'kependudukan', 'item': 'Penduduk Klojen'},
    '/PBlimbing': {'sector': 'kependudukan', 'item': 'Penduduk Blimbing'},
    '/PLowokwaru': {'sector': 'kependudukan', 'item': 'Penduduk Lowokwaru'},

    // Ekonomi
    '/LajuPertumbuhan': {'sector': 'ekonomi', 'item': 'Laju Pertumbuhan Ekonomi'},
    '/PDRB': {'sector': 'ekonomi', 'item': 'Produk Domestik Regional Bruto (PDRB)'},
    '/InflasiTahunKalender': {'sector': 'ekonomi', 'item': 'Inflasi Tahun Kalender'},
    '/InflasiBulanan': {'sector': 'ekonomi', 'item': 'Inflasi Bulanan'},
    '/DeteksiDiniInflasi': {'sector': 'ekonomi', 'item': 'Deteksi Dini Inflasi'},

    // Kemiskinan
    '/TingkatKemiskinan': {'sector': 'kemiskinan', 'item': 'Tingkat Kemiskinan'},
    '/IndeksKedalamanKemiskinan': {'sector': 'kemiskinan', 'item': 'Indeks Kedalaman Kemiskinan'},
    '/IndeksKeparahanKemiskinan': {'sector': 'kemiskinan', 'item': 'Indeks Keparahan Kemiskinan'},
    '/GarisKemiskinan': {'sector': 'kemiskinan', 'item': 'Garis Kemiskinan'},

    // Ketenagakerjaan
    '/AKMenurutPendidikan': {'sector': 'ketenagakerjaan', 'item': 'Angkatan Kerja Menurut Pendidikan'},
    '/PartisipasiAngkatanKerja': {'sector': 'ketenagakerjaan', 'item': 'Tingkat Partisipasi Angkatan Kerja'},
    '/TingkatPengangguran': {'sector': 'ketenagakerjaan', 'item': 'Tingkat Pengangguran'},
    '/PengangguranMenurutPendidikan': {'sector': 'ketenagakerjaan', 'item': 'Pengangguran Menurut Pendidikan'},

    // Kesejahteraan
    '/GiniRasio': {'sector': 'kesejahteraan', 'item': 'Gini Rasio'},
    '/PengeluaranPerkapita': {'sector': 'kesejahteraan', 'item': 'Pengeluaran Perkapita'},

    // Pertanian
    '/LuasPanenPadi': {'sector': 'pertanian', 'item': 'Luas Panen Padi'},
    '/ProduksiPadi': {'sector': 'pertanian', 'item': 'Produksi Padi'},
    '/ProduktivitasPadi': {'sector': 'pertanian', 'item': 'Produktivitas Padi'},
    '/ProduksiBeras': {'sector': 'pertanian', 'item': 'Produksi Beras'},
    
    // Fitur Tambahan Lainnya
    '/contact': {'sector': 'contact', 'item': 'Halaman Kontak Layanan'},
  };

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    final routeName = route.settings.name;
    if (routeName != null && _routeLogs.containsKey(routeName)) {
      final logInfo = _routeLogs[routeName]!;
      LoggerService.logActivity(
        sectorCategory: logInfo['sector']!,
        itemName: logInfo['item']!,
        actionType: 'view_page',
      );
    }
  }
}
