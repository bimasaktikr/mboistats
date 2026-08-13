import 'package:flutter/material.dart';
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
                final title = item['item_name'] as String? ?? 'Berkas Data';
                final sector = item['sector_category'] as String? ?? 'umum';
                final description = item['item_name'] as String? ?? '';
                final iconName = _getIconForSector(sector);
                final targetRoute = _getRouteForSector(sector);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () {
                      final contentUrl = item['content_url'] as String?;
                      if (contentUrl != null && contentUrl.isNotEmpty) {
                        if (contentUrl.toLowerCase().contains('.pdf') || sector.toLowerCase() == 'berita' || sector.toLowerCase() == 'publikasi') {
                          Navigator.of(context).pushNamed(
                            '/pdf_viewer',
                            arguments: {
                              'pdfUrl': contentUrl,
                              'title': title,
                            },
                          );
                        } else if (contentUrl.toLowerCase().contains('.jpg') || contentUrl.toLowerCase().contains('.png') || contentUrl.toLowerCase().contains('.jpeg') || sector.toLowerCase() == 'infografis') {
                          Navigator.of(context).pushNamed('/image_viewer', arguments: {'imageUrl': contentUrl, 'title': title});
                        } else {
                          Navigator.of(context).pushNamed(targetRoute);
                        }
                      } else {
                        Navigator.of(context).pushNamed(targetRoute);
                      }
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
                            child: item['cover_url'] != null && (item['cover_url'] as String).isNotEmpty
                                ? Image.network(
                                    item['cover_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset('assets/icons/$iconName'),
                                  )
                                : Image.asset(
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
