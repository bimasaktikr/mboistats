import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class KependudukanMenurutJKPage extends StatelessWidget {
  const KependudukanMenurutJKPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penduduk Menurut Jenis Kelamin',
      varId: 51,
    );
  }
}