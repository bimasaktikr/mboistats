import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class InflasiTahunanPage extends StatelessWidget {
  const InflasiTahunanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Inflasi Tahun Kalender',
      varId: 437,
    );
  }
}