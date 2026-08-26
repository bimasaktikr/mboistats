import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PDRB extends StatelessWidget {
  const PDRB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'PDRB Menurut Lapangan Usaha',
      varId: 436,
    );
  }
}