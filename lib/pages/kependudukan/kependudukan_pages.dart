import 'package:flutter/material.dart';
import 'package:mboistats/datas/kependudukan.dart';
import 'package:mboistats/theme.dart';

class KependudukanPages extends StatelessWidget {
  const KependudukanPages({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kependudukan'),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/left-arrow.png',
            height: 25,
          ),
          onPressed: () {
            Navigator.of(context)
                .pop(); // Menavigasi kembali ke halaman sebelumnya
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 24,
            ),
            //News
            ...kependudukan.map((item) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  child: InkWell(
                    onTap: () {
                      if (item.route != null) {
                        Navigator.of(context).pushNamed(item.route!);
                      }
                    },
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: dark4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey
                                .withValues(alpha: 0.2), // Warna abu-abu transparan
                            spreadRadius: 2, // Seberapa tersebar bayangannya
                            blurRadius: 4, // Seberapa kabur bayangannya
                            offset: const Offset(
                                0, 2), // Perpindahan bayangan dari widget
                          ),
                        ],
                      ),
                      child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      leading: GestureDetector(
                        onTap: () {
                          if (item.route != null) {
                            Navigator.of(context).pushNamed(item.route!);
                          }
                        },
                        child: Image.asset('assets/icons/${item.icons}'),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: bold16.copyWith(color: dark1),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/icons/right-arrow.png',
                              height: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
