import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class ProduksiPadiPage extends StatelessWidget {
  const ProduksiPadiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Produksi Padi',
      varId: 493,
    );
  }
}