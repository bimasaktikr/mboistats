import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
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
        title: const Text(
          'MBOIStatS+',
          style: TextStyle(color: Colors.black),
        ),
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/images/Mbois-stat Logo_Fix Putih.png',
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding di dalam ScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 200, // Lebar container sesuai dengan lebar ikon telepon
                  height: 200, // Tinggi container sesuai dengan tinggi ikon telepon
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/icons/communication.png'), // Path ikon telepon
                      fit: BoxFit.cover, // Sesuaikan dengan tata letak gambar
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10), // Tambahkan SizedBox dengan ketinggian yang diinginkan
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // Jarak di bawah judul
                  child: Column(
                    children: [
                      Text(
                        'Kontak Kami', // Ganti dengan judul yang sesuai
                        style: bold16.copyWith(color: dark1, height: 1.5),
                        textAlign: TextAlign.center, // Sesuaikan gaya teks
                      ),
                      Text(
                        'Kami siap membantu Anda. Hubungi kami untuk informasi lebih lanjut', // Teks tambahan di bawah judul
                        style: regular14.copyWith(color: dark2, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Tambahkan SizedBox dengan ketinggian yang diinginkan
              ...contact.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: InkWell(
                  onTap: () {
                    if (item.title == 'Telepon') {
                      // Menampilkan konfirmasi sebelum meluncurkan panggilan telepon
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
                              textAlign: TextAlign.justify,
                          ),
                          actions: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
                                  child: const Text('Batal', style: TextStyle(color: Colors.blue)),
                                ),
                                const SizedBox(width: 16), // Space between buttons
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Tutup dialog
                                    launchUrlString('tel:${item.description}'); // Meluncurkan panggilan telepon
                                  },
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
                                  child: const Text('Hubungi', style: TextStyle(color: Colors.blue)),
                                ),
                              ],
                            ),
                          ],

                        ),
                      );
                    } else if (item.title == 'Alamat') {
                      launchUrlString('https://www.google.com/maps/place/Jl.+Janti+Barat+No+47,+Sukun');
                    } else if (item.title == 'Email') {
                      launchUrlString('mailto:bps3573@bps.go.id');
                    } else if (item.title == 'Instagram') {
                      launchUrlString('https://instagram.com/bpskotamalang');
                    } else if (item.title == 'WhatsApp') {
                      launchUrlString('https://wa.me/+6281250503573');
                    } else if (item.title == 'Website') {
                      launchUrlString ('https://malangkota.bps.go.id/');
                    }
                  },
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: dark4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.2 * 255).round()),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Image.asset(
                        'assets/icons/${item.icons}',
                      ),
                      title: Text(
                        item.title,
                        style: bold16.copyWith(color: dark1),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            item.description,
                            style: regular14.copyWith(color: dark2),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.center,
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
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
