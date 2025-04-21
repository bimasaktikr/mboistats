//import 'dart:js';
import 'package:flutter/material.dart';
import 'package:mboistats/pages/brs_pages.dart';
import 'package:mboistats/pages/contact.dart';
import 'package:mboistats/pages/ekonomi/ekonomi_pages.dart';
import 'package:mboistats/pages/ekonomi/perekonomian_deteksi_dini_inflasi.dart';
import 'package:mboistats/pages/more_pages.dart';
import 'package:mboistats/pages/publikasi.dart';
import 'package:mboistats/pages/tentang_pages.dart';
import 'package:mboistats/pages/informasi_pelayanan_pages.dart';
import 'package:mboistats/splash-screen.dart';
import 'package:mboistats/pages/home_page.dart';
import 'package:mboistats/pages/infografis_pages.dart';
import 'package:mboistats/pages/kemiskinan/kemiskinan.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_pages.dart';
import 'package:mboistats/pages/kesejahteraan/kesejahteraan_pages.dart';
import 'package:mboistats/pages/ketenagakerjaan/ketenagakerjaan_pages.dart';
import 'package:mboistats/pages/pertanian/pertanian_pages.dart';
import 'package:mboistats/pages/IPM/ipm.dart';
import 'package:mboistats/pages/IPM/ipm_uhh.dart';
import 'package:mboistats/pages/IPM/ipm_pages.dart';
import 'package:mboistats/pages/IPM/ipm_daya_beli.dart';
import 'package:mboistats/pages/IPM/ipm_rls.dart';
import 'package:mboistats/pages/IPM/ipm_hls.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_jenis_kelamin.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_kecamatan.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_blimbing.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_kedungkandang.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_klojen.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_sukun.dart';
import 'package:mboistats/pages/kependudukan/kependudukan_lowokwaru.dart';
import 'package:mboistats/pages/ekonomi/perekonomian_inflasi_bulanan.dart';
import 'package:mboistats/pages/ekonomi/perekonomian_inflasi_tahunan.dart';
import 'package:mboistats/pages/ekonomi/perekonomian_lpe.dart';
import 'package:mboistats/pages/ekonomi/perekonomian_pdrb.dart';
import 'package:mboistats/pages/kemiskinan/kemiskinan_garis.dart';
import 'package:mboistats/pages/kemiskinan/kemiskinan_indeks_kedalaman.dart';
import 'package:mboistats/pages/kemiskinan/kemiskinan_indeks_keparahan.dart';
import 'package:mboistats/pages/kemiskinan/kemiskinan_tingkat.dart';
import 'package:mboistats/pages/ketenagakerjaan/ketenagakerjaan_ak_pendidikan.dart';
import 'package:mboistats/pages/ketenagakerjaan/ketenagakerjaan_penganggur_pendidikan.dart';
import 'package:mboistats/pages/ketenagakerjaan/ketenagakerjaan_tpt.dart';
import 'package:mboistats/pages/ketenagakerjaan/ketenagakerjaan_tpak.dart';
import 'package:mboistats/pages/kesejahteraan/kesejahteraan_gini_rasio.dart';
import 'package:mboistats/pages/kesejahteraan/kesejahteraan_pengeluaran_perkapita.dart';
import 'package:mboistats/pages/pertanian/pertanian_luas_panen_padi.dart';
import 'package:mboistats/pages/pertanian/pertanian_produksi_beras.dart';
import 'package:mboistats/pages/pertanian/pertanian_produksi_padi.dart';
import 'package:mboistats/pages/pertanian/pertanian_produktivitas_padi.dart';

class RouteManager {
  static Map<String, Widget Function(BuildContext)> routes = {
    '/splash': (context) => SplashScreen(),
    '/main': (context) => HomePage(),
    '/berita': (context) => BeritaPages(),
    '/infografis': (context) => InfografisPages(),
    '/tentang': (context) => TentangPages(),
    '/informasipelayanan': (context) => InformasiPelayananPages(),
    '/publikasi': (context) => PublikasiPage(),
    '/contact': (context) => Contact(),
    '/kependudukan': (context) => KependudukanPages(),

    '/ekonomi': (context) => EkonomiPages(),
    '/ipm': (context) => IPMPages(),
    '/kesejahteraan': (context) => KesejahteraanPages(),
    '/ketenagakerjaan': (context) => KetenagakerjaanPages(),
    '/pertanian': (context) => PertanianPages(),
    '/more': (context) => MorePages(),

    //IPM
    '/PendudukBekerja': (context) => IndexPembangunanManusiaPage(),
    '/UsiaHarapanHidup': (context) => UsiaHarapanHidupPage(),
    '/HarapanLamaSekolah': (context) => HarapanLamaSekolahPage(),
    '/RataRataLamaSekolah': (context) => RataRataLamaSekolahPage(),
    '/DayaBeli': (context) => DayaBeliPage(),

    //Kependudukan
    '/PendudukJK': (context) => KependudukanMenurutJKPage(),
    '/PendudukKec': (context) => KependudukanMenurutKecamatanPage(),
    '/PKedungkandang': (context) => PendudukKedungkandangPage(),
    '/PSukun': (context) => PendudukSukunPage(),
    '/PKlojen': (context) => PendudukKlojenPage(),
    '/PBlimbing': (context) => PendudukBlimbingPage(),
    '/PLowokwaru': (context) => PendudukLowokwaruPage(),

    //Ekonomi
    '/LajuPertumbuhan': (context) => LajuPertumbuhan(),
    '/Ekonomi': (context) => EkonomiPages(),
    '/PDRB': (context) => PDRB(),
    '/InflasiTahunKalender': (context) => InflasiTahunanPage(),
    '/InflasiBulanan': (context) => InflasiBulananPage(),
    '/DeteksiDiniInflasi': (context) => DeteksiDiniInflasiPage(),

    //Kemiskinan
    '/kemiskinan': (context) => KemiskinanPages(),
    '/TingkatKemiskinan': (context) => TingkatKemiskinanPage(),
    '/IndeksKedalamanKemiskinan': (context) => IndeksKedalamanKemiskinanPage(),
    '/IndeksKeparahanKemiskinan': (context) => IndeksKeparahanKemiskinan(),
    '/GarisKemiskinan': (context) => GarisKemiskinanPage(),

    //Ketenagakerjaan
    '/AKMenurutPendidikan': (context) => AngkatanKerjaMenurutPendidikanPage(),
    '/PartisipasiAngkatanKerja': (context) =>
        TingkatPartisipasiAngkatanKerjaPage(),
    '/TingkatPengangguran': (context) =>
        PersentasePengangguranMenurutPendidikanPage(),
    '/PengangguranMenurutPendidikan': (context) => PengangguranMenurutPendidikan(),

    //Kesejahteraan
    '/GiniRasio': (context) => GiniRasioPage(),
    '/PengeluaranPerkapita': (context) => PengeluaranPerkapitaPage(),

    //Pertanian
    '/LuasPanenPadi': (context) => LuasPanenPadiPage(),
    '/ProduksiPadi': (context) => ProduksiPadiPage(),
    '/ProduktivitasPadi': (context) => ProduktivitasPadiPage(),
    '/ProduksiBeras': (context) => ProduksiBerasPage(),
  };
}
