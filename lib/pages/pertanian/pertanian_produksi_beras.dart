import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class ProduksiBerasPage extends StatelessWidget {
  const ProduksiBerasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Produksi Beras',
      varId: 496,
    );
  }
}