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
    LoggerService.logActivity(
      actionType: 'view_page',
      sectorCategory: 'infografis',
      itemName: 'Halaman Utama Infografis',
    );
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
          'Infografis',
          style: pjsBold18.copyWith(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: _dataInfografis.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
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
                        actionType: 'view_infografis_item',
                        sectorCategory: 'infografis',
                        itemName: title,
                        coverUrl: imageUrl,
                        contentUrl: imageUrl,
                      );
                      Navigator.pushNamed(
                        context,
                        '/image_viewer',
                        arguments: imageUrl,
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
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: dark3,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: dark3,
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
                            maxLines: 2,
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
