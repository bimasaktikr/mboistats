import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class AKPendidikanPage extends StatelessWidget {
  const AKPendidikanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Angkatan Kerja Menurut Pendidikan',
      varId: 442,
    );
  }
}