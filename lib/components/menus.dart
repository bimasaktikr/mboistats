import 'package:flutter/material.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'package:mboistats/theme.dart';

class Menus extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  const Menus({
    Key? key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  }) : super(key: key);

  @override
  State<Menus> createState() => _MenusState();
}

class _MenusState extends State<Menus> {
  bool _isExpanded = false;

  final List<Map<String, String>> _allCategories = [
    {'key': 'tenaga_kerja', 'title': 'Tenaga Kerja', 'icon': 'assets_v2/icons/tenaga_kerja.png', 'route': '/ketenagakerjaan'},
    {'key': 'ipm', 'title': 'IPM', 'icon': 'assets_v2/icons/IPM.png', 'route': '/ipm'},
    {'key': 'perekonomian', 'title': 'Perekonomian', 'icon': 'assets_v2/icons/perekonomian.png', 'route': '/ekonomi'},
    {'key': 'kemiskinan', 'title': 'Kemiskinan', 'icon': 'assets_v2/icons/kemiskinan.png', 'route': '/kemiskinan'},
    {'key': 'kependudukan', 'title': 'Kependudukan', 'icon': 'assets_v2/icons/kependudukan.png', 'route': '/kependudukan'},
    {'key': 'pertanian', 'title': 'Pertanian', 'icon': 'assets_v2/icons/pertanian.png', 'route': '/pertanian'},
    {'key': 'kesejahteraan', 'title': 'Kesejahteraan', 'icon': 'assets_v2/icons/kesejahteraan.png', 'route': '/kesejahteraan'},
  ];

  List<Map<String, String>> _mainCategories = [];
  List<Map<String, String>> _extraCategories = [];

  @override
  void initState() {
    super.initState();
    // Default order first
    _mainCategories = _allCategories.take(4).toList();
    _extraCategories = _allCategories.skip(4).toList();
    _loadDynamicOrder();
  }

  Future<void> _loadDynamicOrder() async {
    try {
      final sectorScores = await RecommendationService.getSectorScoresForDevice();
      if (sectorScores.isEmpty) return;
      
      final sorted = List<Map<String, String>>.from(_allCategories);
      sorted.sort((a, b) {
        final scoreA = sectorScores[a['key']] ?? 0.0;
        final scoreB = sectorScores[b['key']] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });
      
      if (mounted) {
        setState(() {
          _mainCategories = sorted.take(4).toList();
          _extraCategories = sorted.skip(4).toList();
        });
      }
    } catch (e) {
      print('Error loading dynamic category order: $e');
    }
  }

  void refreshCategories() {
    _loadDynamicOrder();
  }

  Widget _buildCategoryItem(Map<String, String> cat, bool isDark) {
    return GestureDetector(
      onTap: () {
        LoggerService.logActivity(
          actionType: 'view_page',
          sectorCategory: cat['title']!,
          itemName: cat['title']!,
        );
        Navigator.pushNamed(context, cat['route']!).then((_) {
          _loadDynamicOrder();
        });
      },
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              cat['icon']!,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.category, color: blueNormal, size: 36),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  cat['title']!,
                  style: pjsMedium12.copyWith(
                    color: isDark ? Colors.white : dark2,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 20.0, left: 12.0, right: 12.0, bottom: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: 4 items spaceEvenly
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _mainCategories
                  .map((cat) => _buildCategoryItem(cat, isDark))
                  .toList(),
            ),

            // Row 2: 3 items centered (shown when _isExpanded is true)
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 20),
                  ..._extraCategories
                      .map((cat) => _buildCategoryItem(cat, isDark))
                      .toList(),
                  const SizedBox(width: 20),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Toggle button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFFFF8F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: orangeNormal,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isExpanded ? 'Lebih Sedikit' : 'Lainnya',
                        style: pjsSemiBold14.copyWith(color: orangeNormal),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
