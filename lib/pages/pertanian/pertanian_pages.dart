import 'package:flutter/material.dart';
import 'package:mboistats/datas/pertanian.dart';
import 'package:mboistats/theme.dart';

class PertanianPages extends StatelessWidget {
  const PertanianPages({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pertanian'),
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
          ...pertanian.map((item) => Container(
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
                      if (item.route != null) {
                        Navigator.of(context).pushNamed(item.route!);
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
