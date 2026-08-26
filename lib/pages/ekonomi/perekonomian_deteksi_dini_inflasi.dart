import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class DeteksiDiniInflasiPage extends StatelessWidget {
  const DeteksiDiniInflasiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Deteksi Dini Inflasi',
      varId: 438,
    );
  }
}