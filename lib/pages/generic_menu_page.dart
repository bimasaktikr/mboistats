import 'package:flutter/material.dart';
import 'package:mboistats/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Model sederhana untuk item menu
class GenericMenuItem {
  final String title;
  final String iconPath; // Path lengkap ke aset icon (misal: assets/icons/ipm.png)
  final String? route;   // Route internal (misal: /ipm)
  final String? externalUrl; // URL eksternal untuk 'MorePages'

  GenericMenuItem({
    required this.title,
    required this.iconPath,
    this.route,
    this.externalUrl,
  });
}

class GenericMenuPage extends StatelessWidget {
  final String pageTitle;
  final List<GenericMenuItem> items;

  const GenericMenuPage({
    Key? key,
    required this.pageTitle,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/left-arrow.png',
            height: 25,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (item.externalUrl != null) {
                      launchUrlString(item.externalUrl!, mode: LaunchMode.externalApplication);
                    } else if (item.route != null) {
                      Navigator.of(context).pushNamed(item.route!);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Image.asset(
                          item.iconPath,
                          width: 40, 
                          height: 40,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.insert_chart, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.title,
                            style: bold16.copyWith(color: dark1, fontSize: 14),
                          ),
                        ),
                        Image.asset(
                          'assets/icons/right-arrow.png',
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}