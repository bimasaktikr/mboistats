import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';

class PublikasiFullPage extends StatefulWidget {
  const PublikasiFullPage({Key? key}) : super(key: key);

  @override
  State<PublikasiFullPage> createState() => _PublikasiFullPageState();
}

class _PublikasiFullPageState extends State<PublikasiFullPage> {
  List<Map<String, dynamic>> _dataPublikasi = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDataPublikasi();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchDataPublikasi();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataPublikasi() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final String apiUrl =
        "https://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/$_currentPage/key/9db89e91c3c142df678e65a78c4e547f";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        if (parsedResponse["data"] != null && parsedResponse["data"][1] != null) {
          final List<dynamic> publikasi = parsedResponse["data"][1];
          if (publikasi.isEmpty) {
            setState(() => _hasMore = false);
          } else {
            setState(() {
              _currentPage++;
              _dataPublikasi.addAll(List<Map<String, dynamic>>.from(publikasi));
            });
          }
        } else {
          setState(() => _hasMore = false);
        }
      } else {
        setState(() => _hasMore = false);
      }
    } catch (_) {
      // Handle error quietly
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom header matching mockup: back arrow + title text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: isDark ? blueLighter : blueHover),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Publikasi',
                    style: pjsBold20.copyWith(
                      color: isDark ? blueLighter : blueHover,
                    ),
                  ),
                ],
              ),
            ),
            // Grid content
            Expanded(
              child: _dataPublikasi.isEmpty && _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.58,
                      ),
                      itemCount: _dataPublikasi.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _dataPublikasi.length) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final item = _dataPublikasi[index];
                        final String coverUrl = item['cover'] ?? '';
                        final String pdfUrl = item['pdf'] ?? '';
                        final String title = item['title'] ?? 'Publikasi BPS';

                        return InkWell(
                          onTap: () {
                            if (pdfUrl.isNotEmpty) {
                              LoggerService.logActivity(
                                actionType: 'view_pdf',
                                sectorCategory: 'publikasi',
                                itemName: title,
                                coverUrl: coverUrl,
                                contentUrl: pdfUrl,
                              );
                              Navigator.pushNamed(
                                context,
                                '/pdf_viewer',
                                arguments: {
                                  'pdfUrl': pdfUrl,
                                  'title': title,
                                },
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image card — gray rounded rectangle
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: coverUrl.isNotEmpty
                                      ? Image.network(
                                          coverUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Center(
                                            child: Icon(
                                              Icons.menu_book,
                                              color: dark3,
                                              size: 40,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.menu_book,
                                            color: dark3,
                                            size: 40,
                                          ),
                                        ),
                                ),
                              ),
                              // Title text below — max 3 lines with ellipsis
                              const SizedBox(height: 8),
                              Text(
                                title,
                                style: pjsRegular14.copyWith(
                                  color: isDark ? Colors.white : dark1,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
