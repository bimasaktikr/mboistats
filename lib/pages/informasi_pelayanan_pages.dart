import 'package:flutter/material.dart';

class InformasiPelayananPages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Pelayanan'),
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

      body: ListView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // 8 px space top & bottom
            child: Image.network(
              imageUrls[index],
              height: 600,
              width: 300,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  List<String> imageUrls = [
    'http://s.bps.go.id/standar_pelayanan_3573_1',
    'http://s.bps.go.id/standar_pelayanan_3573_2',
    'http://s.bps.go.id/standar_pelayanan_3573_3',
    'http://s.bps.go.id/maklumat_pelayanan_3573',
  ];
}
