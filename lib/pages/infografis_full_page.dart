import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';

class InfografisFullPage extends StatefulWidget {
  const InfografisFullPage({Key? key}) : super(key: key);

  @override
  State<InfografisFullPage> createState() => _InfografisFullPageState();
}

class _InfografisFullPageState extends State<InfografisFullPage> {
  List<Map<String, dynamic>> _dataInfografis = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDataInfografis();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchDataInfografis();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataInfografis() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final String apiUrl =
        "https://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/page/$_currentPage/key/9db89e91c3c142df678e65a78c4e547f";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        if (parsedResponse["data"] != null && parsedResponse["data"][1] != null) {
          final List<dynamic> infografis = parsedResponse["data"][1];
          if (infografis.isEmpty) {
            setState(() => _hasMore = false);
          } else {
            setState(() {
              _currentPage++;
              _dataInfografis.addAll(List<Map<String, dynamic>>.from(infografis));
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
                    'Infografis',
                    style: pjsBold20.copyWith(
                      color: isDark ? blueLighter : blueHover,
                    ),
                  ),
                ],
              ),
            ),
            // Grid content
            Expanded(
              child: _dataInfografis.isEmpty && _isLoading
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
                      itemCount: _dataInfografis.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _dataInfografis.length) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final item = _dataInfografis[index];
                        final String imageUrl = item['img'] ?? '';
                        final String title = item['title'] ?? 'Infografis';

                        return InkWell(
                          onTap: () {
                            if (imageUrl.isNotEmpty) {
                              LoggerService.logActivity(
                                actionType: 'view_pdf',
                                sectorCategory: 'infografis',
                                itemName: title,
                                coverUrl: imageUrl,
                                contentUrl: imageUrl,
                              );
                              Navigator.pushNamed(
                                context,
                                '/image_viewer',
                                arguments: {'imageUrl': imageUrl, 'title': title},
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
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Center(
                                            child: Icon(
                                              Icons.image,
                                              color: dark3,
                                              size: 40,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.image,
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
