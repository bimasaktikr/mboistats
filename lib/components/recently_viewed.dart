import 'package:flutter/material.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'package:mboistats/theme.dart';
import 'package:mboistats/main.dart';

class RecentlyViewedSection extends StatefulWidget {
  const RecentlyViewedSection({Key? key}) : super(key: key);

  @override
  _RecentlyViewedSectionState createState() => _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState extends State<RecentlyViewedSection> with RouteAware {
  late Future<List<Map<String, dynamic>>> _recentlyViewedFuture;

  @override
  void initState() {
    super.initState();
    _recentlyViewedFuture = RecommendationService.getRecentlyViewed(limit: 2);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      MyApp.routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _recentlyViewedFuture = RecommendationService.getRecentlyViewed(limit: 2);
    });
  }

  String _resolveRoute(String title, String sector) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('pengangguran') || titleLower.contains('tpt')) return '/TingkatPengangguran';
    if (titleLower.contains('angkatan kerja') || titleLower.contains('tpak')) return '/AngkatanKerja';
    if (titleLower.contains('garis kemiskinan')) return '/GarisKemiskinan';
    if (titleLower.contains('kedalaman')) return '/IndeksKedalaman';
    if (titleLower.contains('keparahan')) return '/IndeksKeparahan';
    if (titleLower.contains('kemiskinan')) return '/TingkatKemiskinan';
    if (titleLower.contains('kecamatan')) return '/PendudukKec';
    if (titleLower.contains('jenis kelamin')) return '/PendudukJK';
    if (titleLower.contains('pertumbuhan penduduk')) return '/LajuPertumbuhanPenduduk';
    if (titleLower.contains('kepadatan')) return '/KepadatanPenduduk';
    if (titleLower.contains('laju pertumbuhan') || titleLower.contains('lpe')) return '/LajuPertumbuhan';
    if (titleLower.contains('pdrb')) return '/Pdrb';
    if (titleLower.contains('inflasi')) return '/Inflasi';
    if (titleLower.contains('harapan hidup') || titleLower.contains('ahh')) return '/AngkaHarapanHidup';
    if (titleLower.contains('harapan lama sekolah') || titleLower.contains('hls')) return '/HarapanLamaSekolah';
    if (titleLower.contains('rata-rata lama') || titleLower.contains('rls')) return '/RataLamaSekolah';
    if (titleLower.contains('pengeluaran riil') || titleLower.contains('daya beli')) return '/PengeluaranRiil';
    if (titleLower.contains('ipm')) return '/Ipm';
    if (titleLower.contains('gini')) return '/GiniRasio';
    if (titleLower.contains('perkapita')) return '/PengeluaranPerkapita';
    if (titleLower.contains('padi')) return '/ProduksiPadi';
    if (titleLower.contains('panen')) return '/LuasPanen';
    return _getRouteForSector(sector);
  }

  // Helper Mapper Rute & Icon untuk Sektor
  String _getRouteForSector(String sector) {
    switch (sector.toLowerCase()) {
      case 'perekonomian':
      case 'ekonomi':
        return '/ekonomi';
      case 'tenaga_kerja':
      case 'ketenagakerjaan':
        return '/ketenagakerjaan';
      case 'ipm':
        return '/ipm';
      case 'kemiskinan':
        return '/kemiskinan';
      case 'kependudukan':
        return '/kependudukan';
      case 'kesejahteraan':
        return '/kesejahteraan';
      case 'pertanian':
        return '/pertanian';
      case 'berita':
        return '/berita';
      case 'publikasi':
        return '/publikasi';
      case 'infografis':
        return '/infografis';
      default:
        return '/main';
    }
  }

  String _getIconForSector(String sector) {
    switch (sector.toLowerCase()) {
      case 'perekonomian':
      case 'ekonomi':
        return 'ekonomi.png';
      case 'tenaga_kerja':
      case 'ketenagakerjaan':
        return 'ketenagakerjaan.png';
      case 'ipm':
        return 'ipm.png';
      case 'kemiskinan':
        return 'kemiskinan.png';
      case 'kependudukan':
        return 'kependudukan.png';
      case 'kesejahteraan':
        return 'kesejahteraan.png';
      case 'pertanian':
        return 'pertanian.png';
      default:
        return 'faq.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recentlyViewedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Ringkas saat loading
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Sembunyikan jika kosong
        }

        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'Terakhir Dilihat',
                style: pjsBold16.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : dark1),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final title = item['title'] as String? ?? 'Berkas Data';
                final description = item['title'] as String? ?? '';
                final sector = (item['categories']?['category'] ?? item['module_name'] ?? 'umum') as String;
                final actionType = item['action_type'] as String? ?? '';
                final iconName = _getIconForSector(sector);
                final targetRoute = _resolveRoute(title, sector);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () {
                      LoggerService.logActivity(
                        actionType: 'view_page',
                        sectorCategory: LoggerService.classifySector(title),
                        itemName: title,
                      );
                      Navigator.of(context).pushNamed(targetRoute);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dark4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.06),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                                    'assets/icons/$iconName',
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.description, color: Colors.blue, size: 20);
                                    },
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: pjsSemiBold14.copyWith(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : dark1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  description,
                                  style: pjsRegular12.copyWith(color: dark3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.play_arrow,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
