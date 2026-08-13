import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class GarisKemiskinanPage extends StatelessWidget {
  const GarisKemiskinanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Garis Kemiskinan',
      varId: 431,
    );
  }
}