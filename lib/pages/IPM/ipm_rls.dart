import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class RataRataLamaSekolahPage extends StatelessWidget {
  const RataRataLamaSekolahPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Rata-Rata Lama Sekolah',
      varId: 585,
    );
  }
}