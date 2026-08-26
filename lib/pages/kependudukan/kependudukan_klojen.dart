import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PendudukKlojenPage extends StatelessWidget {
  const PendudukKlojenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penduduk Klojen',
      varId: 54,
    );
  }
}