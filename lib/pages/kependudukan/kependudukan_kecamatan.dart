import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class KependudukanMenurutKecamatanPage extends StatelessWidget {
  const KependudukanMenurutKecamatanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penduduk Menurut Kecamatan',
      varId: 48,
    );
  }
}