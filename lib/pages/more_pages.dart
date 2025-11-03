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
      body: ListView( // Ganti Column ke ListView
        padding: const EdgeInsets.only(top: 24.0),
        children: [
          ...more.map((item) => Container(
                // --- PERUBAHAN TAMPILAN ---
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
                  child: InkWell(
                    onTap: () {
                      if (item.title == 'Galeri InovaZI') {
                        launchUrlString('https://s.bps.go.id/mboistats_galeri_inovazi');
                      } else if (item.title == 'PENGADUAN') {
                        launchUrlString('https://s.bps.go.id/mboistats_lapor3573');
                      }else if (item.title == 'Feedback') {
                        launchUrlString('https://s.bps.go.id/mboistats_feedback');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Image.asset('assets/icons/${item.icons}'),
                        title: Text(
                          item.title,
                          style: bold16.copyWith(color: dark1, fontSize: 14),
                        ),
                        trailing: Image.asset(
                          'assets/icons/right-arrow.png',
                          height: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                // --- AKHIR PERUBAHAN ---
              )),
        ],
      ),
    );
  }
}
