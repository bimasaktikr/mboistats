import 'package:flutter/material.dart';
import 'package:mboistats/theme.dart';

class Menus extends StatefulWidget {
  const Menus({Key? key}) : super(key: key);

  @override
  State<Menus> createState() => _MenusState();
}

class _MenusState extends State<Menus> {
  bool _isExpanded = false;

  final List<Map<String, String>> _mainCategories = [
    {'title': 'Tenaga Kerja', 'icon': 'assets_v2/icons/tenaga_kerja.png', 'route': '/ketenagakerjaan'},
    {'title': 'IPM', 'icon': 'assets_v2/icons/IPM.png', 'route': '/ipm'},
    {'title': 'Perekonomian', 'icon': 'assets_v2/icons/perekonomian.png', 'route': '/ekonomi'},
    {'title': 'Kemiskinan', 'icon': 'assets_v2/icons/kemiskinan.png', 'route': '/kemiskinan'},
  ];

  final List<Map<String, String>> _extraCategories = [
    {'title': 'Kependudukan', 'icon': 'assets_v2/icons/kependudukan.png', 'route': '/kependudukan'},
    {'title': 'Pertanian', 'icon': 'assets_v2/icons/pertanian.png', 'route': '/pertanian'},
    {'title': 'Kesejahteraan', 'icon': 'assets_v2/icons/kesejahteraan.png', 'route': '/kesejahteraan'},
  ];

  Widget _buildCategoryItem(Map<String, String> cat, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, cat['route']!),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
