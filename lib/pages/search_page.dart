import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;
  const SearchPage({Key? key, required this.initialQuery}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _currentQuery = widget.initialQuery;
    _performSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _currentQuery = query.trim();
    });

    try {
      final List<Map<String, dynamic>> combinedResults = [];
      final seenTitles = <String>{};

      // 1. Query Supabase contents table
      try {
        final response = await Supabase.instance.client
            .from('contents')
            .select()
            .ilike('item_name', '%$cleanQuery%')
            .order('created_at', ascending: false)
            .limit(20);

        for (var item in response) {
          final title = item['item_name']?.toString() ?? '';
          if (title.isNotEmpty && !seenTitles.contains(title)) {
            seenTitles.add(title);
            combinedResults.add(Map<String, dynamic>.from(item));
          }
        }
      } catch (e) {
        print("Supabase search error: $e");
      }

      // 2. Fetch live BPS API to supplement results
      final apiUrls = [
        'https://webapi.bps.go.id/v1/api/list/model/pressrelease/lang/ind/domain/3573/page/1/key/9db89e91c3c142df678e65a78c4e547f',
        'https://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/1/key/9db89e91c3c142df678e65a78c4e547f',
        'https://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/page/1/key/9db89e91c3c142df678e65a78c4e547f',
      ];

      for (var url in apiUrls) {
        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            final parsed = json.decode(res.body);
            final items = List<Map<String, dynamic>>.from(parsed['data']?[1] ?? []);
            for (var item in items) {
              final title = (item['title'] ?? item['judul'] ?? '').toString();
              if (title.toLowerCase().contains(cleanQuery) && !seenTitles.contains(title)) {
                seenTitles.add(title);
                final cover = (item['thumbnail'] ?? item['img'] ?? item['cover'] ?? '').toString();
                final pdf = (item['pdf'] ?? item['img'] ?? item['dl'] ?? '').toString();

                combinedResults.add({
                  'item_name': title,
                  'sector_categories': ['perekonomian'],
                  'action_type': 'view_pdf',
                  'cover_url': cover,
                  'content_url': pdf,
                });
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _results = combinedResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error performing search: $e");
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  String _getSectorLabel(dynamic sectorCategories) {
    if (sectorCategories is List && sectorCategories.isNotEmpty) {
      return sectorCategories.map((s) => _capitalize(s.toString())).join(', ');
    }
    return 'Statistik';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  String _getIconForSector(dynamic sectorCategories) {
    String sector = '';
    if (sectorCategories is List && sectorCategories.isNotEmpty) {
      sector = sectorCategories[0].toString().toLowerCase();
    }
    switch (sector) {
      case 'perekonomian':
        return 'assets_v2/icons/perekonomian.png';
      case 'tenaga_kerja':
        return 'assets_v2/icons/tenaga_kerja.png';
      case 'ipm':
        return 'assets_v2/icons/IPM.png';
      case 'kemiskinan':
        return 'assets_v2/icons/kemiskinan.png';
      case 'kependudukan':
        return 'assets_v2/icons/kependudukan.png';
      case 'pertanian':
        return 'assets_v2/icons/pertanian.png';
      case 'kesejahteraan':
        return 'assets_v2/icons/kesejahteraan.png';
      default:
        return 'assets_v2/icons/perekonomian.png';
    }
  }

  void _onItemTap(Map<String, dynamic> item) {
    final contentUrl = item['content_url'] as String? ?? '';
    final title = item['item_name'] as String? ?? 'Data Statistik';
    final sectors = item['sector_categories'];
    final sectorLabel = (sectors is List && sectors.isNotEmpty)
        ? sectors[0].toString().toUpperCase()
        : 'STATISTIK';

    LoggerService.logActivity(
      actionType: 'view_pdf',
      sectorCategory: sectorLabel,
      itemName: title,
      coverUrl: item['cover_url'] as String? ?? '',
      contentUrl: contentUrl,
    );

    if (contentUrl.isEmpty) return;

    if (contentUrl.toLowerCase().contains('.jpg') ||
        contentUrl.toLowerCase().contains('.png') ||
        contentUrl.toLowerCase().contains('.jpeg')) {
      Navigator.pushNamed(context, '/image_viewer', arguments: {
        'imageUrl': contentUrl,
        'title': title,
      });
    } else {
      Navigator.pushNamed(context, '/pdf_viewer', arguments: {
        'pdfUrl': contentUrl,
        'title': title,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7FDFF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Image.asset(
            'assets_v2/icons/back_arrow.png',
            width: 24,
            height: 24,
            color: isDark ? Colors.white : dark1,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: false,
          onSubmitted: _performSearch,
          style: pjsRegular14.copyWith(color: isDark ? Colors.white : dark1),
          decoration: InputDecoration(
            hintText: 'Cari BRS, Publikasi, Infografis...',
            hintStyle: pjsRegular14.copyWith(color: dark3),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets_v2/icons/search_bar.png',
              width: 22,
              height: 22,
              color: isDark ? Colors.white70 : dark2,
            ),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: isDark ? Colors.white38 : dark4),
                      const SizedBox(height: 16),
                      Text(
                        _currentQuery.isEmpty
                            ? 'Ketik kata kunci untuk mencari'
                            : 'Tidak ditemukan hasil untuk\n"$_currentQuery"',
                        style: pjsRegular14.copyWith(color: dark3),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '${_results.length} hasil ditemukan',
                        style: pjsMedium12.copyWith(color: dark3),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final title = item['item_name'] as String? ?? '';
                          final sectors = item['sector_categories'];
                          final coverUrl = item['cover_url'] as String? ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: InkWell(
                              onTap: () => _onItemTap(item),
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
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: coverUrl.isNotEmpty
                                          ? Image.network(
                                              coverUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Image.asset(
                                                    _getIconForSector(sectors),
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        const Icon(Icons.description, color: Colors.blue, size: 20),
                                                  ),
                                            )
                                          : Image.asset(
                                              _getIconForSector(sectors),
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.description, color: Colors.blue, size: 20),
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
                                              color: isDark ? Colors.white : dark1,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _getSectorLabel(sectors),
                                            style: pjsRegular12.copyWith(color: dark3),
                                            maxLines: 1,
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
                    ),
                  ],
                ),
    );
  }
}
