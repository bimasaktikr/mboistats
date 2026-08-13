import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PenganggurPendidikanPage extends StatelessWidget {
  const PenganggurPendidikanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penganggur Menurut Pendidikan',
      varId: 444,
    );
  }
}