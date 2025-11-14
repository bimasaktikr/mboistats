import 'package:flutter/material.dart';
import 'package:mboistats/datas/tentang.dart';
import 'package:mboistats/theme.dart';

class TentangPages extends StatelessWidget {
  const TentangPages({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tentangItem = tentang[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang BPS Kota Malang'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Padding untuk seluruh konten
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 24,
            ),
            Center(
              child: Container(
                width: 200, 
                height:
                    200, 
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/icons/office.png'), 
                    fit: BoxFit.contain, // Gunakan .contain agar tidak terpotong
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Beri jarak lebih
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Padding lebih besar
                child: Column(
                  children: [
                    Text(
                      tentangItem.title,
                      style: bold18.copyWith(color: dark1), // Judul lebih besar
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300]), // Pemisah visual
                    const SizedBox(height: 16),
                    Text(
                      tentangItem.description,
                      style: regular14.copyWith(color: dark2, height: 1.5), // Beri line-height
                      textAlign: TextAlign.justify, // Ratakan paragraf
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24), // Jarak di bawah
          ],
        ),
      ),
    );
  }
}
