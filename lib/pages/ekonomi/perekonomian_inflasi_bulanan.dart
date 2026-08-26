import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class InflasiBulananPage extends StatelessWidget {
  const InflasiBulananPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Inflasi Bulanan',
      varId: 438,
    );
  }
}