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
  final List<Map<String, String>> _allCategories = [
    {'key': 'tenaga_kerja', 'title': 'Tenaga Kerja', 'icon': 'assets_v2/icons/tenaga_kerja.png', 'route': '/ketenagakerjaan'},
    {'key': 'ipm', 'title': 'IPM', 'icon': 'assets_v2/icons/IPM.png', 'route': '/ipm'},
    {'key': 'perekonomian', 'title': 'Perekonomian', 'icon': 'assets_v2/icons/perekonomian.png', 'route': '/ekonomi'},
    {'key': 'kemiskinan', 'title': 'Kemiskinan', 'icon': 'assets_v2/icons/kemiskinan.png', 'route': '/kemiskinan'},
    {'key': 'kependudukan', 'title': 'Kependudukan', 'icon': 'assets_v2/icons/kependudukan.png', 'route': '/kependudukan'},
    {'key': 'pertanian', 'title': 'Pertanian', 'icon': 'assets_v2/icons/pertanian.png', 'route': '/pertanian'},
    {'key': 'kesejahteraan', 'title': 'Kesejahteraan', 'icon': 'assets_v2/icons/kesejahteraan.png', 'route': '/kesejahteraan'},
  ];

  List<Map<String, String>> _topCategories = [];

  @override
  void initState() {
    super.initState();
    // Default order first
    _topCategories = _allCategories.take(3).toList();
    _loadDynamicOrder();
  }

  Future<void> _loadDynamicOrder() async {
    try {
      final sectorScores = await RecommendationService.getSectorScoresForUser();
      if (sectorScores.isEmpty) return;
      
      final sorted = List<Map<String, String>>.from(_allCategories);
      sorted.sort((a, b) {
        final scoreA = sectorScores[a['key']] ?? 0.0;
        final scoreB = sectorScores[b['key']] ?? 0.0;
        if (scoreB != scoreA) {
          return scoreB.compareTo(scoreA);
        }
        final indexA = _allCategories.indexWhere((element) => element['key'] == a['key']);
        final indexB = _allCategories.indexWhere((element) => element['key'] == b['key']);
        return indexA.compareTo(indexB);
      });
      
      if (mounted) {
        setState(() {
          _topCategories = sorted.take(3).toList();
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
        width: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              cat['icon']!,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.category, color: blueNormal, size: 42),
            ),
            const SizedBox(height: 6),
            Text(
              cat['title']!,
              style: pjsMedium12.copyWith(
                color: isDark ? Colors.white : dark2,
                fontSize: 11.5,
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
        padding: const EdgeInsets.only(top: 20.0, left: 8.0, right: 8.0, bottom: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _topCategories
              .map((cat) => _buildCategoryItem(cat, isDark))
              .toList(),
        ),
      ),
    );
  }
}
