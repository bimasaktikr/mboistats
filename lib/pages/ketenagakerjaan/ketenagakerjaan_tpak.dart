import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class TPAKPage extends StatelessWidget {
  const TPAKPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Tingkat Partisipasi Angkatan Kerja (TPAK)',
      varId: 440,
    );
  }
}