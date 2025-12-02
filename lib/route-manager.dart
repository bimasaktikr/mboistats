import 'package:flutter/material.dart';
import 'package:mboistats/splash-screen.dart';
import 'package:mboistats/pages/home_page.dart';
import 'package:mboistats/pages/login_page.dart';
import 'package:mboistats/pages/brs_pages.dart';
import 'package:mboistats/pages/infografis_pages.dart';
import 'package:mboistats/pages/publikasi.dart';
import 'package:mboistats/pages/tentang_pages.dart';
import 'package:mboistats/pages/informasi_pelayanan_pages.dart';
import 'package:mboistats/pages/contact.dart';
import 'package:mboistats/pages/favorit_page.dart';
import 'package:mboistats/pages/youtube_list_page.dart';
import 'package:mboistats/pages/youtube_player_page.dart';

// --- KOMPONEN GENERIK BARU ---
import 'package:mboistats/components/generic_webview_page.dart';
import 'package:mboistats/pages/generic_menu_page.dart';

// --- DATA UNTUK MENU (Diimport agar bisa dipassing ke GenericMenuPage) ---
import 'package:mboistats/datas/ekonomi.dart';
import 'package:mboistats/datas/ipm.dart';
import 'package:mboistats/datas/kemiskinan.dart';
import 'package:mboistats/datas/kependudukan.dart';
import 'package:mboistats/datas/kesejahteraan.dart';
import 'package:mboistats/datas/ketenagakerjaan.dart';
import 'package:mboistats/datas/pertanian.dart';
import 'package:mboistats/datas/more.dart';

class RouteManager {
  static List<GenericMenuItem> _mapItems(List<dynamic> sourceList) {
    return sourceList.map((item) {
      return GenericMenuItem(
        title: item.title,
        iconPath: 'assets/icons/${item.icons}',
        route: item.route,
      );
    }).toList();
  }

  static Map<String, Widget Function(BuildContext)> routes = {
    '/splash': (context) => SplashScreen(),
    '/login': (context) => const LoginPage(),
    '/main': (context) => const HomePage(),
    '/berita': (context) => const BeritaPages(),
    '/infografis': (context) => const InfografisPages(),
    '/tentang': (context) => const TentangPages(),
    '/informasipelayanan': (context) => InformasiPelayananPages(),
    '/publikasi': (context) => const PublikasiPage(),
    '/contact': (context) => const Contact(),
    '/ekonomi': (context) => GenericMenuPage(
          pageTitle: 'Data Perekonomian',
          items: _mapItems(ekonomi),
        ),
    '/ipm': (context) => GenericMenuPage(
          pageTitle: 'Data IPM',
          items: _mapItems(ipm),
        ),
    '/kemiskinan': (context) => GenericMenuPage(
          pageTitle: 'Data Kemiskinan',
          items: _mapItems(kemiskinan),
        ),
    '/kependudukan': (context) => GenericMenuPage(
          pageTitle: 'Data Kependudukan',
          items: _mapItems(kependudukan),
        ),
    '/kesejahteraan': (context) => GenericMenuPage(
          pageTitle: 'Data Kesejahteraan',
          items: _mapItems(kesejahteraan),
        ),
    '/ketenagakerjaan': (context) => GenericMenuPage(
          pageTitle: 'Data Ketenagakerjaan',
          items: _mapItems(ketenagakerjaan),
        ),
    '/pertanian': (context) => GenericMenuPage(
          pageTitle: 'Data Pertanian',
          items: _mapItems(pertanian),
        ),
    '/more': (context) => GenericMenuPage(
      pageTitle: 'Menu Lainnya',
      items: more.map((item) {
        String? url;
        if (item.title == 'Galeri InovaZI') url = 'https://s.bps.go.id/mboistats_galeri_inovazi';
        if (item.title == 'PENGADUAN') url = 'https://s.bps.go.id/mboistats_lapor3573';
        if (item.title == 'Feedback') url = 'https://s.bps.go.id/mboistats_feedback';
        
        return GenericMenuItem(
          title: item.title,
          iconPath: 'assets/icons/${item.icons}',
          externalUrl: url,
        );
      }).toList(),
    ),
    '/DeteksiDiniInflasi': (context) => const GenericWebViewPage(
          title: 'Deteksi Dini Inflasi',
          url: 'https://s.bps.go.id/deteksi_dini_inflasi', 
        ),
    '/PendudukBekerja': (context) => const GenericWebViewPage(
          title: 'IPM',
          htmlAssetPath: 'assets/web/ipm.html',
          backgroundImagePath: 'assets/images/back_ipm.png',
        ),
    '/UsiaHarapanHidup': (context) => const GenericWebViewPage(
          title: 'Usia Harapan Hidup',
          htmlAssetPath: 'assets/web/ipm_uhh.html',
          backgroundImagePath: 'assets/images/back_ipm.png',
        ),
    '/HarapanLamaSekolah': (context) => const GenericWebViewPage(
          title: 'Harapan Lama Sekolah',
          htmlAssetPath: 'assets/web/ipm_hls.html',
          backgroundImagePath: 'assets/images/back_ipm.png',
        ),
    '/RataRataLamaSekolah': (context) => const GenericWebViewPage(
          title: 'Rata - Rata Lama Sekolah',
          htmlAssetPath: 'assets/web/ipm_rls.html',
          backgroundImagePath: 'assets/images/back_ipm.png',
        ),
    '/DayaBeli': (context) => const GenericWebViewPage(
          title: 'Daya Beli',
          htmlAssetPath: 'assets/web/ipm_daya_beli.html',
          backgroundImagePath: 'assets/images/back_ipm.png',
        ),
    '/PendudukJK': (context) => const GenericWebViewPage(
          title: 'Kependudukan',
          htmlAssetPath: 'assets/web/kependudukan_jenis_kelamin.html',
          backgroundImagePath: 'assets/images/back_kependudukan.png',
        ),
    '/PendudukKec': (context) => const GenericWebViewPage(
          title: 'Kependudukan',
          htmlAssetPath: 'assets/web/kependudukan_kecamatan.html',
          backgroundImagePath: 'assets/images/back_kependudukan.png',
        ),
    '/PKedungkandang': (context) => const GenericWebViewPage(
          title: 'Kependudukan',
          htmlAssetPath: 'assets/web/kependudukan_kedungkandang.html',
          backgroundImagePath: 'assets/images/back_kependudukan.png',
        ),
    '/PSukun': (context) => const GenericWebViewPage(
          title: 'Kependudukan',
          htmlAssetPath: 'assets/web/kependudukan_sukun.html',
          backgroundImagePath: 'assets/images/back_kependudukan.png',
        ),
    '/PKlojen': (context) => const GenericWebViewPage(
          title: 'Kependudukan',
          htmlAssetPath: 'assets/web/kependudukan_klojen.html',
          backgroundImagePath: 'assets/images/back_kependudukan.png',
        ),
    '/PBlimbing': (context) => const GenericWebViewPage(
          title: 'Kependudukan',
          htmlAssetPath: 'assets/web/kependudukan_blimbing.html',
          backgroundImagePath: 'assets/images/back_kependudukan.png',
        ),
    '/PLowokwaru': (context) => const GenericWebViewPage(
          title: 'Kependudukan',
          htmlAssetPath: 'assets/web/kependudukan_lowokwaru.html',
          backgroundImagePath: 'assets/images/back_kependudukan.png',
        ),
    '/LajuPertumbuhan': (context) => const GenericWebViewPage(
          title: 'Laju Pertumbuhan Ekonomi',
          htmlAssetPath: 'assets/web/perekonomian_lpe.html',
          backgroundImagePath: 'assets/images/back_perekonomian.png',
        ),
    '/PDRB': (context) => const GenericWebViewPage(
          title: 'PDRB',
          htmlAssetPath: 'assets/web/perekonomian_pdrb_lapus.html',
          backgroundImagePath: 'assets/images/back_perekonomian.png',
        ),
    '/InflasiTahunKalender': (context) => const GenericWebViewPage(
          title: 'Inflasi Tahun Kalender',
          htmlAssetPath: 'assets/web/perekonomian_inflasi_tahunan.html',
          backgroundImagePath: 'assets/images/back_perekonomian.png',
        ),
    '/InflasiBulanan': (context) => const GenericWebViewPage(
          title: 'Inflasi Bulanan',
          htmlAssetPath: 'assets/web/perekonomian_inflasi_bulanan.html',
          backgroundImagePath: 'assets/images/back_perekonomian.png',
        ),
    '/TingkatKemiskinan': (context) => const GenericWebViewPage(
          title: 'Tingkat Kemiskinan',
          htmlAssetPath: 'assets/web/kemiskinan_tingkat.html',
          backgroundImagePath: 'assets/images/back_kemiskinan.png',
        ),
    '/IndeksKedalamanKemiskinan': (context) => const GenericWebViewPage(
          title: 'Indeks Kedalaman Kemiskinan',
          htmlAssetPath: 'assets/web/kemiskinan_indeks_kedalaman.html',
          backgroundImagePath: 'assets/images/back_kemiskinan.png',
        ),
    '/IndeksKeparahanKemiskinan': (context) => const GenericWebViewPage(
          title: 'Indeks Keparahan Kemiskinan',
          htmlAssetPath: 'assets/web/kemiskinan_indeks_keparahan.html',
          backgroundImagePath: 'assets/images/back_kemiskinan.png',
        ),
    '/GarisKemiskinan': (context) => const GenericWebViewPage(
          title: 'Garis Kemiskinan',
          htmlAssetPath: 'assets/web/kemiskinan_garis.html',
          backgroundImagePath: 'assets/images/back_kemiskinan.png',
        ),
    '/AKMenurutPendidikan': (context) => const GenericWebViewPage(
          title: 'Angkatan Kerja Pendidikan',
          htmlAssetPath: 'assets/web/ketenagakerjaan_ak_pendidikan.html',
          backgroundImagePath: 'assets/images/back_ketenagakerjaan.png',
        ),
    '/PartisipasiAngkatanKerja': (context) => const GenericWebViewPage(
          title: 'TPAK',
          htmlAssetPath: 'assets/web/ketenagakerjaan_tpak.html',
          backgroundImagePath: 'assets/images/back_ketenagakerjaan.png',
        ),
    '/TingkatPengangguran': (context) => const GenericWebViewPage(
          title: 'TPT',
          htmlAssetPath: 'assets/web/ketenagakerjaan_tpt.html',
          backgroundImagePath: 'assets/images/back_ketenagakerjaan.png',
        ),
    '/PengangguranMenurutPendidikan': (context) => const GenericWebViewPage(
          title: 'Pengangguran',
          htmlAssetPath: 'assets/web/ketenagakerjaan_penganggur_pendidikan.html',
          backgroundImagePath: 'assets/images/back_ketenagakerjaan.png',
        ),
    '/GiniRasio': (context) => const GenericWebViewPage(
          title: 'Gini Rasio',
          htmlAssetPath: 'assets/web/kesejahteraan_gini_rasio.html',
          backgroundImagePath: 'assets/images/back_kesejahteraan.png',
        ),
    '/PengeluaranPerkapita': (context) => const GenericWebViewPage(
          title: 'Pengeluaran Perkapita',
          htmlAssetPath: 'assets/web/kesejahteraan_pengeluaran_perkapita.html',
          backgroundImagePath: 'assets/images/back_kesejahteraan.png',
        ),
    '/LuasPanenPadi': (context) => const GenericWebViewPage(
          title: 'Luas Panen Padi',
          htmlAssetPath: 'assets/web/pertanian_luas_panen_padi.html',
          backgroundImagePath: 'assets/images/back_pertanian.png',
        ),
    '/ProduksiPadi': (context) => const GenericWebViewPage(
          title: 'Produksi Padi',
          htmlAssetPath: 'assets/web/pertanian_produksi_padi.html',
          backgroundImagePath: 'assets/images/back_pertanian.png',
        ),
    '/ProduktivitasPadi': (context) => const GenericWebViewPage(
          title: 'Produktivitas Padi',
          htmlAssetPath: 'assets/web/pertanian_produktivitas_padi.html',
          backgroundImagePath: 'assets/images/back_pertanian.png',
        ),
    '/ProduksiBeras': (context) => const GenericWebViewPage(
          title: 'Produksi Beras',
          htmlAssetPath: 'assets/web/pertanian_produksi_beras.html',
          backgroundImagePath: 'assets/images/back_pertanian.png',
        ),
        
    '/favorit': (context) => const FavoritPage(),
    '/youtube_list': (context) => const YoutubeListPage(),
    '/youtube_player': (context) => const YoutubePlayerPage(),
  };
}