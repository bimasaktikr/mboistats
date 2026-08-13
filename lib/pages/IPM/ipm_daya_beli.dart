import 'package:flutter/material.dart';
import 'package:mboistats/components/bps_native_data_page.dart';

class DayaBeliPage extends StatelessWidget {
  const DayaBeliPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BpsNativeDataPage(
      title: 'Pengeluaran Perkapita / Daya Beli',
      varId: 586,
    );
  }
}