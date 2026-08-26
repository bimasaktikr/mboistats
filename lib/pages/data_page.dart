import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'dart:convert';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/services/youtube_service.dart';
import 'package:mboistats/theme.dart';

class DataPage extends StatefulWidget {
  const DataPage({Key? key}) : super(key: key);

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _brsItems = [];
  List<Map<String, dynamic>> _infografisItems = [];
  List<Map<String, dynamic>> _publikasiItems = [];
  List<Map<String, dynamic>> _youtubeItems = [];

  // Inline Search Results
  List<Map<String, dynamic>> _searchBrsResults = [];
  List<Map<String, dynamic>> _searchInfografisResults = [];
  List<Map<String, dynamic>> _searchPublikasiResults = [];

  bool _loadingBrs = true;
  bool _loadingInfografis = true;
  bool _loadingPublikasi = true;
  bool _loadingYoutube = true;
  bool _isSearching = false;

  String _searchQuery = '';

  final List<Map<String, String>> _categories = const [
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
    _fetchYoutubeData();

    _searchController.addListener(_onSearchInputChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  int _extractYear(String title) {
    final matches = RegExp(r'\b(20\d{2}|19\d{2})\b').allMatches(title);
    if (matches.isNotEmpty) {
      return int.tryParse(matches.last.group(0) ?? '') ?? 0;
    }
    return 0;
  }

  int _compareByNewest(Map<String, dynamic> a, Map<String, dynamic> b) {
    final dateA = (a['created_at'] ?? a['rl_date'] ?? a['date'] ?? '').toString();
    final dateB = (b['created_at'] ?? b['rl_date'] ?? b['date'] ?? '').toString();
    final comp = dateB.compareTo(dateA);
    if (comp != 0) return comp;

    final yearA = _extractYear((a['title'] ?? a['item_name'] ?? '').toString());
    final yearB = _extractYear((b['title'] ?? b['item_name'] ?? '').toString());
    return yearB.compareTo(yearA);
  }

  void _onSearchInputChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchBrsResults = [];
        _searchInfografisResults = [];
        _searchPublikasiResults = [];
      });
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _performInlineSearch(query);
    });
  }

  Future<void> _performInlineSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('contents')
          .select()
          .ilike('title', '%$query%')
          .order('created_at', ascending: false)
          .limit(60);

      final List<Map<String, dynamic>> allMatches = List<Map<String, dynamic>>.from(response);
      allMatches.sort(_compareByNewest);

      final brsList = <Map<String, dynamic>>[];
      final pubList = <Map<String, dynamic>>[];
      final infList = <Map<String, dynamic>>[];

      for (var item in allMatches) {
        final cType = (item['content_type'] ?? '').toString();
        final actionType = (item['action_type'] ?? '').toString();
        if (cType == 'infografis' || actionType == 'download_file') {
          infList.add(item);
        } else if (cType == 'brs' || actionType == 'view_brs_pdf') {
          brsList.add(item);
        } else if (cType == 'publikasi' || actionType == 'view_publikasi_pdf') {
          pubList.add(item);
        } else {
          brsList.add(item);
          pubList.add(item);
        }
      }

      if (mounted) {
        setState(() {
          _searchBrsResults = brsList;
          _searchInfografisResults = infList;
          _searchPublikasiResults = pubList;
          _isSearching = false;
        });
      }
    } catch (e) {
      print("Inline search error: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchBrsData() async {
    try {
      final response = await Supabase.instance.client
          .from('contents')
          .select()
          .or('content_type.eq.brs,action_type.eq.view_brs_pdf')
          .order('created_at', ascending: false)
          .limit(30)
          .timeout(const Duration(seconds: 4));

      final list = List<Map<String, dynamic>>.from(response);
      list.sort(_compareByNewest);

      if (list.isNotEmpty) {
        if (mounted) {
          setState(() {
            _brsItems = list;
            _loadingBrs = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback BPS API
    try {
      final response = await http.get(
        Uri.parse('https://webapi.bps.go.id/v1/api/list/model/pressrelease/lang/ind/domain/3573/page/1/key/9db89e91c3c142df678e65a78c4e547f'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(parsed['data'][1]);
        list.sort(_compareByNewest);
        if (mounted) {
          setState(() {
            _brsItems = list;
            _loadingBrs = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBrs = false);
    }
  }

  Future<void> _fetchInfografisData() async {
    try {
      final response = await Supabase.instance.client
          .from('contents')
          .select()
          .or('content_type.eq.infografis,action_type.eq.download_file')
          .order('created_at', ascending: false)
          .limit(30)
          .timeout(const Duration(seconds: 4));

      final list = List<Map<String, dynamic>>.from(response);
      list.sort(_compareByNewest);

      if (list.isNotEmpty) {
        if (mounted) {
          setState(() {
            _infografisItems = list;
            _loadingInfografis = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback BPS API
    try {
      final response = await http.get(
        Uri.parse('https://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/page/1/key/9db89e91c3c142df678e65a78c4e547f'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(parsed['data'][1]);
        list.sort(_compareByNewest);
        if (mounted) {
          setState(() {
            _infografisItems = list;
            _loadingInfografis = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInfografis = false);
    }
  }

  Future<void> _fetchPublikasiData() async {
    try {
      final response = await Supabase.instance.client
          .from('contents')
          .select()
          .or('content_type.eq.publikasi,action_type.eq.view_publikasi_pdf')
          .order('created_at', ascending: false)
          .limit(30)
          .timeout(const Duration(seconds: 4));

      final list = List<Map<String, dynamic>>.from(response);
      list.sort(_compareByNewest);

      if (list.isNotEmpty) {
        if (mounted) {
          setState(() {
            _publikasiItems = list;
            _loadingPublikasi = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback BPS API
    try {
      final response = await http.get(
        Uri.parse('https://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/1/key/9db89e91c3c142df678e65a78c4e547f'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(parsed['data'][1]);
        list.sort(_compareByNewest);
        if (mounted) {
          setState(() {
            _publikasiItems = list;
            _loadingPublikasi = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPublikasi = false);
    }
  }

  Future<void> _fetchYoutubeData() async {
    try {
      final items = await YouTubeService.getRecentStreams(limit: 3).timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _youtubeItems = items;
          _loadingYoutube = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingYoutube = false);
    }
  }

  List<Map<String, dynamic>> get _filteredBrsItems {
    final source = _searchQuery.isNotEmpty ? _searchBrsResults : _brsItems;
    if (_searchQuery.isEmpty) return source.take(5).toList();
    return source;
  }

  List<Map<String, dynamic>> get _filteredInfografisItems {
    final source = _searchQuery.isNotEmpty ? _searchInfografisResults : _infografisItems;
    if (_searchQuery.isEmpty) return source.take(5).toList();
    return source;
  }

  List<Map<String, dynamic>> get _filteredPublikasiItems {
    final source = _searchQuery.isNotEmpty ? _searchPublikasiResults : _publikasiItems;
    if (_searchQuery.isEmpty) return source.take(5).toList();
    return source;
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
                      child: Image.asset(
                        'assets_v2/icons/search_bar.png',
                        width: 22,
                        height: 22,
                      ),
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
                    if (_isSearching)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_searchController.text.isNotEmpty)
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
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
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
                    SingleChildScrollView(
                      controller: _categoryScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: _categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildCategoryGridTile(context, cat, isDark),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _categoryScrollController,
                      builder: (context, child) {
                        double progress = 0.0;
                        try {
                          if (_categoryScrollController.hasClients &&
                              _categoryScrollController.position.hasContentDimensions &&
                              _categoryScrollController.position.maxScrollExtent > 0) {
                            progress = (_categoryScrollController.offset /
                                    _categoryScrollController.position.maxScrollExtent)
                                .clamp(0.0, 1.0);
                          }
                        } catch (_) {
                          progress = 0.0;
                        }
                        const double trackWidth = 52.0;
                        const double thumbWidth = 26.0;
                        final double leftOffset = progress * (trackWidth - thumbWidth);

                        return Container(
                          width: trackWidth,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: leftOffset,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: thumbWidth,
                                  decoration: BoxDecoration(
                                    color: blueNormal,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BRS Section (Clean header)
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

              // Infografis Section (Clean header)
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

              // Publikasi Section (Clean header)
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

              // YouTube Siaran Pers Section
              _buildSectionHeader(
                context: context,
                title: 'Live Youtube Siaran Pers',
                linkText: 'Lainnya ▶',
                onLinkTap: () {
                  LoggerService.logActivity(
                    actionType: 'view_youtube_list',
                    sectorCategory: 'youtube',
                    itemName: 'Lihat arsip Live Youtube',
                  );
                  Navigator.pushNamed(context, '/youtube_archive');
                },
              ),
              const SizedBox(height: 12),
              _buildYoutubeList(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  Widget _buildCategoryGridTile(BuildContext context, Map<String, String> cat, bool isDark) {
    final title = cat['title'] ?? 'Kategori';
    final route = cat['route'] ?? '';
    final icon = cat['icon'] ?? '';

    return GestureDetector(
      onTap: () {
        LoggerService.logActivity(
          actionType: 'view_page',
          sectorCategory: title,
          itemName: title,
        );
        if (route.isNotEmpty) {
          Navigator.pushNamed(context, route);
        }
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.category, color: blueNormal, size: 38),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: pjsMedium12.copyWith(
                color: isDark ? Colors.white : dark2,
                fontSize: 10.5,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
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
          final title = item['title'] ?? item['item_name'] ?? item['judul'] ?? 'BRS Item';
          final thumbnail = item['cover_url'] ?? item['thumbnail'] ?? item['img'] ?? item['cover'] ?? '';
          final pdfUrl = item['content_url'] ?? item['pdf'] ?? item['dl'] ?? '';

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
                  _showPdfConfirmDialog(
                    context: context,
                    title: title,
                    pdfUrl: pdfUrl,
                    contentType: 'brs',
                    coverUrl: thumbnail,
                    abstractText: item['abstract'] ?? item['ringkasan'],
                    releaseDate: item['rl_date'] ?? item['created_at']?.toString().split('T')[0],
                    size: item['size'],
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
                              headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
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
          final title = item['title'] ?? item['item_name'] ?? item['judul'] ?? 'Infografis Item';
          final imgUrl = item['cover_url'] ?? item['img'] ?? item['thumbnail'] ?? item['cover'] ?? '';
          final contentUrl = item['content_url'] ?? item['dl'] ?? item['img'] ?? '';

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
                final displayUrl = imgUrl.isNotEmpty ? imgUrl : contentUrl;
                if (displayUrl.isNotEmpty) {
                  LoggerService.logActivity(
                    actionType: 'download_file',
                    sectorCategory: LoggerService.classifySector(title),
                    itemName: title,
                    coverUrl: displayUrl,
                    contentUrl: displayUrl,
                  );
                  Navigator.pushNamed(context, '/image_viewer', arguments: {'imageUrl': displayUrl, 'title': title});
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
                              headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
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
          final title = item['title'] ?? item['item_name'] ?? item['judul'] ?? 'Publikasi Item';
          final thumbnail = item['cover_url'] ?? item['cover'] ?? item['img'] ?? item['thumbnail'] ?? '';
          final pdfUrl = item['content_url'] ?? item['pdf'] ?? item['dl'] ?? '';

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
                  _showPdfConfirmDialog(
                    context: context,
                    title: title,
                    pdfUrl: pdfUrl,
                    coverUrl: thumbnail,
                    abstractText: item['abstract'] ?? item['ringkasan'],
                    releaseDate: item['rl_date'] ?? item['created_at']?.toString().split('T')[0],
                    size: item['size'],
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
                      child: thumbnail.isNotEmpty
                          ? Image.network(
                              thumbnail,
                              headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: blueLighter, child: const Icon(Icons.book, color: blueNormal)),
                            )
                          : Container(color: blueLighter, child: const Icon(Icons.book, color: blueNormal)),
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

  Widget _buildYoutubeList(BuildContext context) {
    if (_loadingYoutube) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_youtubeItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text('Belum ada arsip live streaming siaran pers.', style: pjsRegular12.copyWith(color: dark3)),
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _youtubeItems.length,
        itemBuilder: (context, index) {
          final item = _youtubeItems[index];
          final title = item['title'] ?? 'Live Stream';
          final thumbnail = item['thumbnail_url'] ?? '';
          final videoId = item['video_id'] ?? '';
          final isLive = item['is_live'] == true;

          return Container(
            width: 140,
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
                LoggerService.logActivity(
                  actionType: 'view_youtube_stream',
                  sectorCategory: 'youtube',
                  itemName: title,
                );
                Navigator.pushNamed(context, '/youtube_player', arguments: {
                  'videoId': videoId,
                  'title': title,
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: thumbnail.isNotEmpty
                                ? Image.network(
                                    thumbnail,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: Colors.red.shade50, child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 36)),
                                  )
                                : Container(color: Colors.red.shade50, child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 36)),
                          ),
                        ),
                        if (isLive)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildFallbackCards(String category, VoidCallback onTap) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark4),
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.refresh, color: blueNormal),
          label: Text('Muat data $category', style: pjsMedium14.copyWith(color: blueNormal)),
        ),
      ),
    );
  }

  void _showPdfConfirmDialog({
    required BuildContext context,
    required String title,
    required String pdfUrl,
    String? contentType,
    String? coverUrl,
    String? abstractText,
    String? releaseDate,
    String? size,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: pjsBold16.copyWith(color: dark1),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (abstractText != null && abstractText.isNotEmpty)
                  Text(
                    abstractText,
                    style: TextStyle(fontSize: 13, color: dark1),
                    textAlign: TextAlign.justify,
                  )
                else
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, color: dark1),
                    textAlign: TextAlign.justify,
                  ),
                const SizedBox(height: 8),
                if (size != null && size.isNotEmpty)
                  Text(
                    "Ukuran Berkas: ${size.replaceAll('.', ',')}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (releaseDate != null && releaseDate.isNotEmpty)
                  Text(
                    "Tanggal Rilis: $releaseDate",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tutup"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _downloadAndOpenPdf(pdfUrl, title, coverUrl);
                  },
                  child: const Text("Unduh"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final resolvedType = contentType ?? (title.toLowerCase().contains('berita resmi') ? 'brs' : 'publikasi');
                    LoggerService.logActivity(
                      actionType: 'view_pdf',
                      contentType: resolvedType,
                      sectorCategory: LoggerService.classifySector(title),
                      itemName: title,
                      coverUrl: coverUrl,
                      contentUrl: pdfUrl,
                    );
                    Navigator.pushNamed(
                      context,
                      '/pdf_viewer',
                      arguments: {'pdfUrl': pdfUrl, 'title': title},
                    );
                  },
                  child: const Text("Buka PDF"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndOpenPdf(String pdfUrl, String fileName, String? coverUrl) async {
    final cleanSector = LoggerService.classifySector(fileName);

    if (Platform.isIOS) {
      try {
        Fluttertoast.showToast(
          msg: "Menyiapkan berkas...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        final response = await http.get(Uri.parse(pdfUrl));
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
          final filePath = '${dir.path}/$cleanName.pdf';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          LoggerService.logActivity(
            actionType: 'download_file',
            sectorCategory: cleanSector,
            itemName: fileName,
            coverUrl: coverUrl,
            contentUrl: pdfUrl,
          );

          await OpenFile.open(filePath);
        } else {
          throw Exception("Gagal mengunduh berkas dari server.");
        }
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Gagal mengunduh: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      return;
    }

    try {
      Fluttertoast.showToast(
        msg: "Memulai unduhan...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      await FileDownloader.downloadFile(
        url: pdfUrl,
        name: cleanName.endsWith('.pdf') ? cleanName : '$cleanName.pdf',
        onDownloadCompleted: (String path) {
          LoggerService.logActivity(
            actionType: 'download_file',
            sectorCategory: cleanSector,
            itemName: fileName,
            coverUrl: coverUrl,
            contentUrl: pdfUrl,
          );
          Fluttertoast.showToast(
            msg: "Unduhan selesai.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          );
        },
        onDownloadError: (String error) {
          Fluttertoast.showToast(
            msg: "Gagal mengunduh: $error",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        },
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Gagal mengunduh: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
