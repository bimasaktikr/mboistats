import 'package:flutter/material.dart';
import 'dart:async';
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
  List<Map<String, dynamic>> _rawResults = [];
  bool _isLoading = false;
  String _currentQuery = '';
  Timer? _debounceTimer;

  // Selected Sector Filter
  String _selectedSector = 'semua';

  // Selected Content Type Filter ('semua', 'view_pdf', 'download_file')
  String _selectedContentType = 'semua';

  final List<Map<String, String>> _sectorFilters = [
    {'key': 'semua', 'label': 'Semua Sektor'},
    {'key': 'pertanian', 'label': 'Pertanian'},
    {'key': 'perekonomian', 'label': 'Perekonomian'},
    {'key': 'tenaga_kerja', 'label': 'Tenaga Kerja'},
    {'key': 'ipm', 'label': 'IPM'},
    {'key': 'kemiskinan', 'label': 'Kemiskinan'},
    {'key': 'kependudukan', 'label': 'Kependudukan'},
    {'key': 'kesejahteraan', 'label': 'Kesejahteraan'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _currentQuery = widget.initialQuery;
    if (widget.initialQuery.trim().isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
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

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _rawResults = [];
        _isLoading = false;
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _currentQuery = query.trim();
    });

    try {
      // Query Supabase contents table directly (Full Database of ~740+ items)
      final response = await Supabase.instance.client
          .from('contents')
          .select('*, contents_has_categories(categories(category))')
          .ilike('title', '%$cleanQuery%')
          .order('created_at', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(response);
      list.sort(_compareByNewest);

      if (mounted) {
        setState(() {
          _rawResults = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Supabase search error: $e");
      if (mounted) {
        setState(() {
          _rawResults = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Helper: Extract category names from contents_has_categories junction data
  List<String> _extractCategories(Map<String, dynamic> item) {
    final chc = item['contents_has_categories'];
    if (chc is List && chc.isNotEmpty) {
      return chc
          .where((e) => e is Map && e['categories'] is Map && e['categories']['category'] != null)
          .map<String>((e) => e['categories']['category'].toString().toLowerCase())
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get _filteredResults {
    final list = _rawResults.where((item) {
      // 1. Sector filter
      if (_selectedSector != 'semua') {
        final categories = _extractCategories(item);
        if (!categories.contains(_selectedSector.toLowerCase())) return false;
      }

      // 2. Content type filter
      if (_selectedContentType != 'semua') {
        final cType = (item['content_type'] ?? '').toString();
        final actionType = (item['action_type'] ?? '').toString();
        if (_selectedContentType == 'infografis') {
          if (cType != 'infografis' && actionType != 'download_file') return false;
        } else if (_selectedContentType == 'dokumen') {
          if (cType != 'brs' && cType != 'publikasi' &&
              actionType != 'view_pdf' &&
              actionType != 'view_brs_pdf' &&
              actionType != 'view_publikasi_pdf') return false;
        }
      }

      return true;
    }).toList();

    list.sort(_compareByNewest);
    return list;
  }

  String _getSectorLabel(dynamic itemOrCategories) {
    if (itemOrCategories is List && itemOrCategories.isNotEmpty) {
      return itemOrCategories.map((s) => _capitalize(s.toString())).join(', ');
    }
    return 'Statistik';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  String _getIconForSector(dynamic itemOrSectors) {
    String sector = '';
    if (itemOrSectors is Map && itemOrSectors['categories'] is Map && itemOrSectors['categories']['category'] != null) {
      sector = itemOrSectors['categories']['category'].toString().toLowerCase();
    } else if (itemOrSectors is List && itemOrSectors.isNotEmpty) {
      sector = itemOrSectors[0].toString().toLowerCase();
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
    final title = item['title'] as String? ?? item['item_name'] as String? ?? 'Data Statistik';
    final categories = _extractCategories(item);
    final sectorLabel = categories.isNotEmpty 
        ? categories[0].toUpperCase()
        : 'STATISTIK';
    final actionType = item['action_type'] as String? ?? 'view_pdf';
    final contentType = item['content_type'] as String?;

    LoggerService.logActivity(
      actionType: actionType,
      contentType: contentType,
      sectorCategory: sectorLabel,
      itemName: title,
      coverUrl: item['cover_url'] as String? ?? '',
      contentUrl: contentUrl,
    );

    if (contentUrl.isEmpty) return;

    if (actionType == 'download_file' ||
        contentUrl.toLowerCase().contains('.jpg') ||
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
    final results = _filteredResults;

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
          onChanged: (text) {
            if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (text.trim() != _currentQuery) {
                _performSearch(text.trim());
              }
            });
          },
          style: pjsRegular14.copyWith(color: isDark ? Colors.white : dark1),
          decoration: InputDecoration(
            hintText: 'Cari BRS, Publikasi, Infografis...',
            hintStyle: pjsRegular14.copyWith(color: dark3),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: dark3, size: 20),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Filter Chips Sektoral (7 Sektor + Semua)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _sectorFilters.map((sector) {
                  final isSelected = _selectedSector == sector['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        sector['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : dark1),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: blueNormal,
                      backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F4F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? blueNormal : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedSector = sector['key']!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2. Type Filter Pills (Semua, BRS / Publikasi, Infografis)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _buildTypePill('semua', 'Semua Data', isDark),
                const SizedBox(width: 8),
                _buildTypePill('dokumen', 'BRS & Publikasi', isDark),
                const SizedBox(width: 8),
                _buildTypePill('infografis', 'Infografis', isDark),
              ],
            ),
          ),

          // 3. Status Hasil Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              _isLoading
                  ? 'Mencari data...'
                  : '${results.length} hasil ditemukan ${_currentQuery.isNotEmpty ? 'untuk "$_currentQuery"' : ''}',
              style: pjsMedium12.copyWith(color: dark3),
            ),
          ),

          // 4. List Hasil Pencarian
          Expanded(
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: isDark ? Colors.white38 : dark4),
                            const SizedBox(height: 16),
                            Text(
                              _currentQuery.isEmpty
                                  ? 'Ketik kata kunci untuk mencari seluruh data BPS'
                                  : 'Tidak ditemukan data untuk\n"$_currentQuery"${_selectedSector != 'semua' ? ' di sektor ini' : ''}',
                              style: pjsRegular14.copyWith(color: dark3),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          final title = item['title'] as String? ?? item['item_name'] as String? ?? '';
                          final sectors = _extractCategories(item);
                          final coverUrl = item['cover_url'] as String? ?? '';
                          final actionType = item['action_type'] as String? ?? 'view_pdf';
                          final isInfografis = actionType == 'download_file';

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
                                      width: 46,
                                      height: 46,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: coverUrl.isNotEmpty
                                          ? Image.network(
                                              coverUrl,
                                              headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
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
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isInfografis
                                                      ? Colors.amber.shade100
                                                      : Colors.blue.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isInfografis ? 'Infografis' : 'PDF',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isInfografis
                                                        ? Colors.amber.shade900
                                                        : Colors.blue.shade900,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  _getSectorLabel(sectors),
                                                  style: pjsRegular12.copyWith(color: dark3),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
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

  Widget _buildTypePill(String typeKey, String label, bool isDark) {
    final isSelected = _selectedContentType == typeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContentType = typeKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : dark1)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : dark2),
          ),
        ),
      ),
    );
  }
}
