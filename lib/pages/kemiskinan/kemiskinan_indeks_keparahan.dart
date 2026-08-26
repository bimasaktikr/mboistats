import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class IndeksKeparahanKemiskinanPage extends StatelessWidget {
  const IndeksKeparahanKemiskinanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Indeks Keparahan Kemiskinan',
      varId: 433,
    );
  }
}