import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class IPMPage extends StatelessWidget {
  const IPMPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Indeks Pembangunan Manusia',
      varId: 582,
    );
  }
}