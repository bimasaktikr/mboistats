import 'package:flutter/material.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'package:mboistats/theme.dart';

class RecommendationSection extends StatefulWidget {
  const RecommendationSection({Key? key}) : super(key: key);

  @override
  _RecommendationSectionState createState() => _RecommendationSectionState();
}

class _RecommendationSectionState extends State<RecommendationSection> {
  late Future<List<RecommendedItem>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = RecommendationService.getSectorRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
          child: Text(
            'Rekomendasi Untuk Anda',
            style: pjsBold16.copyWith(
              color: isDark ? Colors.white : dark1,
            ),
          ),
        ),
        FutureBuilder<List<RecommendedItem>>(
          future: _recommendationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gagal memuat rekomendasi',
                  style: pjsRegular14.copyWith(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final items = snapshot.data!.take(3).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () {
                      final contentUrl = item.contentUrl;
                      final coverUrl = item.coverUrl;
                      final title = item.title;

                      if (contentUrl != null && contentUrl.isNotEmpty) {
                        final urlLower = contentUrl.toLowerCase();
                        final isBrs = item.route == '/berita' || urlLower.contains('pressrelease') || title.toLowerCase().contains('berita resmi');
                        final isInfografis = item.route == '/infografis' || urlLower.contains('infographic');
                        final inferredType = isBrs ? 'brs' : (isInfografis ? 'infografis' : 'publikasi');

                        if (urlLower.contains('.pdf') ||
                            urlLower.contains('download.php') ||
                            urlLower.contains('publication') ||
                            item.route == '/berita' ||
                            item.route == '/publikasi') {
                          LoggerService.logActivity(
                            actionType: isInfografis ? 'download_file' : 'view_pdf',
                            contentType: inferredType,
                            sectorCategory: LoggerService.classifySector(title),
                            itemName: title,
                            coverUrl: coverUrl,
                            contentUrl: contentUrl,
                          );
                          Navigator.of(context).pushNamed(
                            '/pdf_viewer',
                            arguments: {
                              'pdfUrl': contentUrl,
                              'title': title,
                            },
                          );
                        } else if (urlLower.contains('.jpg') ||
                            urlLower.contains('.png') ||
                            urlLower.contains('.jpeg') ||
                            urlLower.contains('cover.php') ||
                            item.route == '/infografis') {
                          LoggerService.logActivity(
                            actionType: 'download_file',
                            sectorCategory: LoggerService.classifySector(title),
                            itemName: title,
                            coverUrl: coverUrl,
                            contentUrl: contentUrl,
                          );
                          Navigator.of(context).pushNamed('/image_viewer', arguments: {'imageUrl': contentUrl, 'title': title});
                        } else {
                          LoggerService.logActivity(
                            actionType: 'view_page',
                            sectorCategory: LoggerService.classifySector(title),
                            itemName: title,
                          );
                          Navigator.of(context).pushNamed(item.route);
                        }
                      } else {
                        LoggerService.logActivity(
                          actionType: 'view_page',
                          sectorCategory: LoggerService.classifySector(title),
                          itemName: title,
                        );
                        Navigator.of(context).pushNamed(item.route);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                            padding: item.coverUrl != null && item.coverUrl!.isNotEmpty
                                ? EdgeInsets.zero
                                : const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                                ? Image.network(
                                    item.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset('assets/icons/${item.icon}'),
                                  )
                                : Image.asset(
                                    'assets/icons/${item.icon}',
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.analytics, color: Colors.blue, size: 20);
                                    },
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: pjsSemiBold14.copyWith(
                                    color: isDark ? Colors.white : dark1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.description,
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
            );
          },
        ),
      ],
    );
  }
}
