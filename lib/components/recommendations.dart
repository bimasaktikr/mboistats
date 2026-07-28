import 'package:flutter/material.dart';
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
    // Memanggil recommendation service (Device ID dihandle otomatis)
    _recommendationsFuture = RecommendationService.getSectorRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rekomendasi Sektoral Untuk Anda',
                style: bold16.copyWith(color: dark1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200, width: 0.5),
                ),
                child: Text(
                  'BETA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
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
                  style: regular14.copyWith(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final items = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                  child: InkWell(
                    onTap: () {
                      final contentUrl = item.contentUrl;
                      if (contentUrl != null && contentUrl.isNotEmpty) {
                        if (contentUrl.toLowerCase().contains('.pdf') || item.route == '/berita' || item.route == '/publikasi') {
                          Navigator.of(context).pushNamed(
                            '/pdf_viewer',
                            arguments: {
                              'pdfUrl': contentUrl,
                              'title': item.title,
                            },
                          );
                        } else if (contentUrl.toLowerCase().contains('.jpg') || contentUrl.toLowerCase().contains('.png') || contentUrl.toLowerCase().contains('.jpeg') || item.route == '/infografis') {
                          Navigator.of(context).pushNamed('/image_viewer', arguments: contentUrl);
                        } else {
                          Navigator.of(context).pushNamed(item.route);
                        }
                      } else {
                        Navigator.of(context).pushNamed(item.route);
                      }
                    },
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dark4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        leading: Container(
                          width: 40,
                          height: 40,
                          clipBehavior: Clip.hardEdge,
                          padding: item.coverUrl != null && item.coverUrl!.isNotEmpty ? EdgeInsets.zero : const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                              ? Image.network(
                                  item.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset('assets/icons/${item.icon}'),
                                )
                              : Image.asset(
                                  'assets/icons/${item.icon}',
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.analytics, color: Colors.blue);
                                  },
                                ),
                        ),
                        title: Text(
                          item.title,
                          style: semibold14.copyWith(color: dark1),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            item.description,
                            style: regular12_5.copyWith(color: dark2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
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
