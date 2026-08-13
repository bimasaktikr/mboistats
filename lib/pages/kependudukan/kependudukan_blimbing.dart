import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class PendudukBlimbingPage extends StatelessWidget {
  const PendudukBlimbingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Penduduk Blimbing',
      varId: 55,
    );
  }
}