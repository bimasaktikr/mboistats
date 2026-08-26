import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class IndeksKedalamanKemiskinanPage extends StatelessWidget {
  const IndeksKedalamanKemiskinanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Indeks Kedalaman Kemiskinan',
      varId: 432,
    );
  }
}