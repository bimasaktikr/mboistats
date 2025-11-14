import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/datas/contact.dart';
import 'package:mboistats/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Contact extends StatefulWidget {
  const Contact({Key? key}) : super(key: key);

  @override
  _ContactState createState() => _ContactState();
}

class _ContactState extends State<Contact> {
  String appVersion = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  Future<void> getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        automaticallyImplyLeading: false,
        leading: null, 
        centerTitle: false, 
        title: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Image.asset(
              'assets/images/Mbois-stat Logo_Fix Putih.png',
              width: 40, 
              height: 40,
            ),
            const SizedBox(width: 8), // Jarak konsisten 8
            const Text(
              'MBOIStatS+',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/icons/communication.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        Text(
                          'Kontak Kami',
                          style: bold18.copyWith(color: dark1, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Kami siap membantu Anda. Hubungi kami untuk informasi lebih lanjut',
                          style: regular14.copyWith(color: dark2, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...contact.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: InkWell(
                          onTap: () {
                            if (item.title == 'Telepon') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                    title: const Text(
                                      'Konfirmasi Panggilan',
                                      style: TextStyle(color: Colors.blue),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Text(
                                        'Apakah Anda ingin menghubungi BPS Kota Malang pada nomor telepon ${item.description}?',
                                        textAlign: TextAlign.justify),
                                    actions: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(false);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Colors.blue),
                                              ),
                                              child: const Text('Batal',
                                                  style: TextStyle(
                                                      color: Colors.blue)),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 120,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                launchUrlString(
                                                    'tel:${item.description}');
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Colors.blue),
                                              ),
                                              child: const Text('Hubungi',
                                                  style: TextStyle(
                                                      color: Colors.blue)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                              );
                            } else if (item.title == 'Alamat') {
                              launchUrlString(
                                  'https://www.google.com/maps/place/Jl.+Janti+Barat+No+47,+Sukun');
                            } else if (item.title == 'Email') {
                              launchUrlString('mailto:bps3573@bps.go.id');
                            } else if (item.title == 'Instagram') {
                              launchUrlString(
                                  'https://instagram.com/bpskotamalang');
                            } else if (item.title == 'WhatsApp') {
                              launchUrlString('https://wa.me/+6281250503573');
                            } else if (item.title == 'Website') {
                              launchUrlString('https://malangkota.bps.go.id/');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Image.asset(
                                'assets/icons/${item.icons}',
                              ),
                              title: Text(
                                item.title,
                                style: bold16.copyWith(
                                    color: dark1, fontSize: 14),
                              ),
                              subtitle: Text(
                                item.description,
                                style: regular14.copyWith(color: dark2),
                              ),
                              trailing: Image.asset(
                                'assets/icons/right-arrow.png',
                                height: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'App Version: $appVersion + $buildNumber',
                        style: regular14.copyWith(color: dark2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Footer(),
          ),
        ],
      ),
    );
  }
}