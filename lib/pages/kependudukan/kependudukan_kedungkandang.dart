import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PendudukKedungkandangPage extends StatelessWidget {
  const PendudukKedungkandangPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penduduk Kedungkandang',
      varId: 52,
    );
  }
}