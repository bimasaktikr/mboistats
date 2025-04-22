import 'package:flutter/material.dart';

class InformasiPelayananPages extends StatefulWidget {
  @override
  _InformasiPelayananPagesState createState() => _InformasiPelayananPagesState();
}

class _InformasiPelayananPagesState extends State<InformasiPelayananPages> {
  List<String> imageUrls = [
    'https://s.bps.go.id/standar_pelayanan_3573_1',
    'https://s.bps.go.id/standar_pelayanan_3573_2',
    'https://s.bps.go.id/standar_pelayanan_3573_3',
    'https://s.bps.go.id/maklumat_pelayanan_3573',
  ];

  void reloadPage() {
    setState(() {});  // Triggers a rebuild
  }

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
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Image.network(
              imageUrls[index],
              height: 600,
              width: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  children: [
                    const Text(
                      'Failed to load image.',
                      style: TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: reloadPage,
                      child: const Text('Retry'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

