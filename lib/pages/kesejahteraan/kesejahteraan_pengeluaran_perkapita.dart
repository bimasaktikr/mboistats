import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PengeluaranPerkapitaPage extends StatelessWidget {
  const PengeluaranPerkapitaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Pengeluaran Perkapita',
      varId: 427,
    );
  }
}