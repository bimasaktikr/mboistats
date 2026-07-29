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
    {'title': 'Kesejahteraan', 'icon': 'assets_v2/icons/kesejahteraan.png', 'route': '/kesejahteraan'},
    {'title': 'Pertanian', 'icon': 'assets_v2/icons/pertanian.png', 'route': '/pertanian'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCategories = _isExpanded
        ? [..._mainCategories, ..._extraCategories]
        : _mainCategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final cat = displayCategories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, cat['route']!);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FDFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          cat['icon']!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.category, color: blueNormal),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['title']!,
                        style: pjsMedium12.copyWith(
                          color: isDark ? Colors.white : dark2,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: orangeNormal,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isExpanded ? 'Sembunyikan' : 'Lainnya',
                      style: pjsSemiBold12.copyWith(color: orangeNormal),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
