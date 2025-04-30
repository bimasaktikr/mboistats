import 'package:flutter/material.dart';
import 'package:mboistats/datas/more.dart';
import 'package:mboistats/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MorePages extends StatelessWidget {
  const MorePages({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Lainnya'),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/left-arrow.png',
            height: 25,
          ),
          onPressed: () {
            Navigator.of(context)
                .pop(); // Menavigasi kembali ke halaman sebelumnya
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 24,
          ),
          // News
          ...more.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: InkWell(
                  onTap: () {
                    if (item.title == 'Galeri InovaZI') {
                      launchUrlString('https://s.bps.go.id/mboistats_galeri_inovazi');
                    } else if (item.title == 'PENGADUAN') {
                      launchUrlString('https://s.bps.go.id/mboistats_lapor3573');
                    }
                  },
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: dark4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.2 * 255).round()),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      leading: Image.asset('assets/icons/${item.icons}'),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: bold16.copyWith(color: dark1),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/icons/right-arrow.png',
                              height: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
