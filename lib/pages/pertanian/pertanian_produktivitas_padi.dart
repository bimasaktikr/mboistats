import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class ProduktivitasPadiPage extends StatelessWidget {
  const ProduktivitasPadiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Produktivitas Padi',
      varId: 499,
    );
  }
}