import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PendudukSukunPage extends StatelessWidget {
  const PendudukSukunPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penduduk Sukun',
      varId: 53,
    );
  }
}