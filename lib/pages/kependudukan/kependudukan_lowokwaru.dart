import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PendudukLowokwaruPage extends StatelessWidget {
  const PendudukLowokwaruPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penduduk Lowokwaru',
      varId: 56,
    );
  }
}