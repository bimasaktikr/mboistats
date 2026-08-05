import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';

class DataPage extends StatefulWidget {
  const DataPage({Key? key}) : super(key: key);

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _brsItems = [];
  List<Map<String, dynamic>> _infografisItems = [];
  List<Map<String, dynamic>> _publikasiItems = [];

  bool _loadingBrs = true;
  bool _loadingInfografis = true;
  bool _loadingPublikasi = true;

  String _searchQuery = '';

  final List<Map<String, String>> _categories = [
    {'title': 'Tenaga Kerja', 'icon': 'assets_v2/icons/tenaga_kerja.png', 'route': '/ketenagakerjaan'},
    {'title': 'IPM', 'icon': 'assets_v2/icons/IPM.png', 'route': '/ipm'},
    {'title': 'Perekonomian', 'icon': 'assets_v2/icons/perekonomian.png', 'route': '/ekonomi'},
    {'title': 'Kemiskinan', 'icon': 'assets_v2/icons/kemiskinan.png', 'route': '/kemiskinan'},
    {'title': 'Kependudukan', 'icon': 'assets_v2/icons/kependudukan.png', 'route': '/kependudukan'},
    {'title': 'Pertanian', 'icon': 'assets_v2/icons/pertanian.png', 'route': '/pertanian'},
    {'title': 'Kesejahteraan', 'icon': 'assets_v2/icons/kesejahteraan.png', 'route': '/kesejahteraan'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchBrsData();
    _fetchInfografisData();
    _fetchPublikasiData();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrsData() async {
    try {
      final response = await http.get(Uri.parse(
        'https://webapi.bps.go.id/v1/api/list/model/pressrelease/lang/ind/domain/3573/page/1/key/9db89e91c3c142df678e65a78c4e547f',
      ));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(parsed['data'][1]);
        if (mounted) {
          setState(() {
            _brsItems = list;
            _loadingBrs = false;
          });
        }
        _syncItemsToContents(list, 'view_pdf');
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBrs = false);
    }
  }

  Future<void> _fetchInfografisData() async {
    try {
      final response = await http.get(Uri.parse(
        'https://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/page/1/key/9db89e91c3c142df678e65a78c4e547f',
      ));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(parsed['data'][1]);
        if (mounted) {
          setState(() {
            _infografisItems = list;
            _loadingInfografis = false;
          });
        }
        _syncItemsToContents(list, 'view_pdf');
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInfografis = false);
    }
  }

  Future<void> _fetchPublikasiData() async {
    try {
      final response = await http.get(Uri.parse(
        'https://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/1/key/9db89e91c3c142df678e65a78c4e547f',
      ));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(parsed['data'][1]);
        if (mounted) {
          setState(() {
            _publikasiItems = list;
            _loadingPublikasi = false;
          });
        }
        _syncItemsToContents(list, 'view_pdf');
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPublikasi = false);
    }
  }

  Future<void> _syncItemsToContents(List<Map<String, dynamic>> items, String actionType) async {
    RecommendationService.syncContentItems(items, actionType);
  }

  List<Map<String, dynamic>> get _filteredBrsItems {
    final query = _searchQuery.trim();
    if (query.isEmpty) return _brsItems.take(3).toList();
    return _brsItems.where((item) {
      final title = (item['title'] ?? item['judul'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredInfografisItems {
    final query = _searchQuery.trim();
    if (query.isEmpty) return _infografisItems.take(3).toList();
    return _infografisItems.where((item) {
      final title = (item['title'] ?? item['judul'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPublikasiItems {
    final query = _searchQuery.trim();
    if (query.isEmpty) return _publikasiItems.take(3).toList();
    return _publikasiItems.where((item) {
      final title = (item['title'] ?? item['judul'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Text & Search Bar
              Text(
                'Mau cari data apa?',
                style: pjsBold20.copyWith(color: isDark ? Colors.white : blueDark),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: blueNormal.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_searchController.text.trim().isNotEmpty) {
                          Navigator.pushNamed(context, '/search', arguments: _searchController.text.trim());
                        }
                      },
                      child: const Icon(Icons.search, color: blueNormal),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: pjsRegular14.copyWith(color: isDark ? Colors.white : dark1),
                        decoration: InputDecoration(
                          hintText: 'Cari BRS, Publikasi, Infografis...',
                          hintStyle: pjsRegular14.copyWith(color: dark3),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            Navigator.pushNamed(context, '/search', arguments: query.trim());
                          }
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Icon(Icons.clear, color: dark3, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Kategori Section
              Text(
                'Kategori',
                style: pjsBold16.copyWith(color: isDark ? Colors.white : dark1),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 20.0, left: 12.0, right: 12.0, bottom: 16.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Row 1: 4 items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _categories
                          .take(4)
                          .map((cat) => _buildCategoryGridTile(context, cat, isDark))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    // Row 2: 3 items (centered)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 20),
                        ..._categories
                            .skip(4)
                            .map((cat) => _buildCategoryGridTile(context, cat, isDark))
                            .toList(),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BRS Section
              _buildSectionHeader(
                context: context,
                title: 'Berita Resmi Statistik (BRS)',
                linkText: 'Lainnya ▶',
                onLinkTap: () {
                  LoggerService.logActivity(
                    actionType: 'view_brs_list',
                    sectorCategory: 'berita',
                    itemName: 'Temukan BRS lainnya',
                  );
                  Navigator.pushNamed(context, '/berita');
                },
              ),
              const SizedBox(height: 12),
              _buildBrsList(context),
              const SizedBox(height: 24),

              // Infografis Section
              _buildSectionHeader(
                context: context,
                title: 'Infografis',
                linkText: 'Lainnya ▶',
                onLinkTap: () {
                  LoggerService.logActivity(
                    actionType: 'view_infografis_list',
                    sectorCategory: 'infografis',
                    itemName: 'Temukan Infografis lainnya',
                  );
                  Navigator.pushNamed(context, '/infografis_full');
                },
              ),
              const SizedBox(height: 12),
              _buildInfografisList(context),
              const SizedBox(height: 24),

              // Publikasi Section
              _buildSectionHeader(
                context: context,
                title: 'Publikasi',
                linkText: 'Lainnya ▶',
                onLinkTap: () {
                  LoggerService.logActivity(
                    actionType: 'view_publikasi_list',
                    sectorCategory: 'publikasi',
                    itemName: 'Temukan Publikasi lainnya',
                  );
                  Navigator.pushNamed(context, '/publikasi_full');
                },
              ),
              const SizedBox(height: 12),
              _buildPublikasiList(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  Widget _buildCategoryGridTile(BuildContext context, Map<String, String> cat, bool isDark) {
    return GestureDetector(
      onTap: () {
        LoggerService.logActivity(
          actionType: 'view_page',
          sectorCategory: cat['title']!,
          itemName: cat['title']!,
        );
        Navigator.pushNamed(context, cat['route']!);
      },
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              cat['icon']!,
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.category, color: blueNormal, size: 44),
            ),
            const SizedBox(height: 6),
            Text(
              cat['title']!,
              style: pjsMedium12.copyWith(
                color: isDark ? Colors.white : dark2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String linkText,
    required VoidCallback onLinkTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: pjsBold16.copyWith(color: isDark ? Colors.white : dark1),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: onLinkTap,
          child: Text(
            linkText,
            style: pjsSemiBold12.copyWith(color: blueNormal),
          ),
        ),
      ],
    );
  }

  Widget _buildBrsList(BuildContext context) {
    if (_loadingBrs) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filteredBrsItems;

    if (items.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text('Tidak ada BRS yang cocok dengan "$_searchQuery"', style: pjsRegular12.copyWith(color: dark3)),
        );
      }
      return _buildFallbackCards('BRS', () => Navigator.pushNamed(context, '/berita'));
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item['title'] ?? 'BRS Item';
          final thumbnail = item['thumbnail'] ?? '';
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dark4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final pdfUrl = item['pdf'] as String? ?? '';
                LoggerService.logActivity(
                  actionType: 'view_pdf',
                  sectorCategory: 'berita',
                  itemName: title,
                  coverUrl: thumbnail,
                  contentUrl: pdfUrl,
                );
                if (pdfUrl.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    '/pdf_viewer',
                    arguments: {'pdfUrl': pdfUrl, 'title': title},
                  );
                } else {
                  Navigator.pushNamed(context, '/berita');
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: thumbnail.isNotEmpty
                          ? Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: blueLighter, child: const Icon(Icons.newspaper, color: blueNormal)),
                            )
                          : Container(color: blueLighter, child: const Icon(Icons.newspaper, color: blueNormal)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      title,
                      style: pjsSemiBold12.copyWith(fontSize: 10, color: dark1),
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
    );
  }

  Widget _buildInfografisList(BuildContext context) {
    if (_loadingInfografis) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filteredInfografisItems;

    if (items.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text('Tidak ada Infografis yang cocok dengan "$_searchQuery"', style: pjsRegular12.copyWith(color: dark3)),
        );
      }
      return _buildFallbackCards('Infografis', () => Navigator.pushNamed(context, '/infografis_full'));
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item['title'] ?? 'Infografis Item';
          final imgUrl = item['img'] ?? '';
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dark4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (imgUrl.isNotEmpty) {
                  LoggerService.logActivity(
                    actionType: 'view_pdf',
                    sectorCategory: 'infografis',
                    itemName: title,
                    coverUrl: imgUrl,
                    contentUrl: imgUrl,
                  );
                  Navigator.pushNamed(context, '/image_viewer', arguments: {'imageUrl': imgUrl, 'title': title});
                } else {
                  Navigator.pushNamed(context, '/infografis_full');
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: imgUrl.isNotEmpty
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: blueLighter, child: const Icon(Icons.image, color: blueNormal)),
                            )
                          : Container(color: blueLighter, child: const Icon(Icons.image, color: blueNormal)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      title,
                      style: pjsSemiBold12.copyWith(fontSize: 10, color: dark1),
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
    );
  }

  Widget _buildPublikasiList(BuildContext context) {
    if (_loadingPublikasi) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filteredPublikasiItems;

    if (items.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text('Tidak ada Publikasi yang cocok dengan "$_searchQuery"', style: pjsRegular12.copyWith(color: dark3)),
        );
      }
      return _buildFallbackCards('Publikasi', () => Navigator.pushNamed(context, '/publikasi_full'));
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item['title'] ?? 'Publikasi Item';
          final coverUrl = item['cover'] ?? '';
          final pdfUrl = item['pdf'] ?? '';
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dark4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
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
                    arguments: {'pdfUrl': pdfUrl, 'title': title},
                  );
                } else {
                  Navigator.pushNamed(context, '/publikasi_full');
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: coverUrl.isNotEmpty
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: blueLighter, child: const Icon(Icons.menu_book, color: blueNormal)),
                            )
                          : Container(color: blueLighter, child: const Icon(Icons.menu_book, color: blueNormal)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      title,
                      style: pjsSemiBold12.copyWith(fontSize: 10, color: dark1),
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
    );
  }

  Widget _buildFallbackCards(String type, VoidCallback onTap) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dark4),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == 'BRS'
                          ? Icons.newspaper
                          : (type == 'Infografis' ? Icons.image : Icons.menu_book),
                      color: blueNormal,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$type ${index + 1}',
                      style: pjsMedium12.copyWith(color: dark2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
