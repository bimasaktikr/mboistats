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
    LoggerService.logActivity(
      actionType: 'view_page',
      sectorCategory: 'publikasi',
      itemName: 'Halaman Utama Publikasi',
    );
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
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [headerTealStart, headerTealEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Publikasi',
          style: pjsBold18.copyWith(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: _dataPublikasi.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
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
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: dark4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: coverUrl.isNotEmpty
                              ? Image.network(
                                  coverUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Icon(
                                      Icons.book,
                                      color: dark3,
                                      size: 40,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.book,
                                    color: dark3,
                                    size: 40,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            title,
                            style: pjsBold14.copyWith(
                              fontSize: 11,
                              color: isDark ? Colors.white : dark1,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: const Footer(),
    );
  }
}
