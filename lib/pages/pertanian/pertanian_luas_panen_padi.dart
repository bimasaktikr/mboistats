import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class LuasPanenPadiPage extends StatelessWidget {
  const LuasPanenPadiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Luas Panen Padi',
      varId: 492,
    );
  }
}