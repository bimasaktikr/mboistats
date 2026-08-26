import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class HarapanLamaSekolahPage extends StatelessWidget {
  const HarapanLamaSekolahPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Harapan Lama Sekolah',
      varId: 583,
    );
  }
}