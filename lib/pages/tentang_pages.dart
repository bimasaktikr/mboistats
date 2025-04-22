import 'package:flutter/material.dart';
import 'package:mboistats/datas/tentang.dart';
import 'package:mboistats/theme.dart';

class TentangPages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 24,
            ),
            Center(
              child: Container(
                width: 200, // Lebar container sesuai dengan lebar ikon telepon
                height:
                    200, // Tinggi container sesuai dengan tinggi ikon telepon
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/icons/office.png'), // Path ikon telepon
                    fit: BoxFit.cover, // Sesuaikan dengan tata letak gambar
                  ),
                ),
              ),
            ),
            const SizedBox(
                height:
                    10), // Tambahkan SizedBox dengan ketinggian yang diinginkan
            const Center(
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: 16.0), // Jarak di bawah judul
                child: Column(),
              ),
            ),
            ...tentang.map((item) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 24, left: 16, right: 16),
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
                      title: Center(
                        child: Text(
                          item.title,
                          style: bold16.copyWith(color: dark1),
                        ),
                      ),
                      subtitle: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          item.description,
                          style: regular14.copyWith(color: dark2),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
