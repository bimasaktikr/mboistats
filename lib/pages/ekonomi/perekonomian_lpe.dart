import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class LajuPertumbuhan extends StatelessWidget {
  const LajuPertumbuhan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Laju Pertumbuhan Ekonomi',
      varId: 434,
    );
  }
}