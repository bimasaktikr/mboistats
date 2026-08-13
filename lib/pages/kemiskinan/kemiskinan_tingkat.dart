import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class TingkatKemiskinanPage extends StatelessWidget {
  const TingkatKemiskinanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Tingkat Kemiskinan',
      varId: 428,
    );
  }
}