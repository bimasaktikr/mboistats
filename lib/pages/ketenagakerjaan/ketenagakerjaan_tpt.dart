import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class TPTPage extends StatelessWidget {
  const TPTPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Tingkat Pengangguran Terbuka (TPT)',
      varId: 441,
    );
  }
}