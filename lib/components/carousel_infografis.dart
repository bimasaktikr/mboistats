
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:saf/saf.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../theme.dart';

class CarouselInfografis extends StatefulWidget {
  const CarouselInfografis({Key? key}) : super(key: key);

  @override
  _CarouselInfografisState createState() => _CarouselInfografisState();
}

class _CarouselInfografisState extends State<CarouselInfografis> {
  late Saf saf;
  List<Map<String, dynamic>> dataInfografis = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/key/9db89e91c3c142df678e65a78c4e547f'),);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final infographic =
        (data['data'][1] as List).cast<Map<String, dynamic>>();
        setState(() {
          dataInfografis = infographic;
        });
      } else {
        throw Exception('Gagal mendapatkan data.');
      }
    } catch (error) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return dataInfografis.isEmpty
        ? const Center(
      child: CircularProgressIndicator(),
    )
        : Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(
            top: 24.0,
            bottom: 16.0,
          ),
          child: Text(
            'INFOGRAFIS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            height: 450,
            enlargeCenterPage: true,
            autoPlay: true,
            aspectRatio: 3 / 4,
          ),
          items: dataInfografis.map((item) {
            return GestureDetector(
              onTap: () {
                openDownloadConfirmation(
                  context,
                  item['img'] ?? '',
                  item['title'] ?? '',
                  item['date'] ?? '',
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    item['img'],
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return true;
      }
      var permissionStatus = await Permission.storage.status;
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.storage.request();
      }
      return permissionStatus.isGranted;
    }
    return true;
  }

  void openDownloadConfirmation(BuildContext context, String tautan,
      String judul, String tglrilis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            judul,
            textAlign: TextAlign.center,
            style: bold16.copyWith(color: dark1),
          ),
          content: SingleChildScrollView(
            child: Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.network(
                        tautan,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                      ),
                      Text(
                        "Tanggal Rilis: $tglrilis",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("Tutup"),
                ),
                const SizedBox(width: 16), // space between buttons
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await downloadAndShowConfirmation(context, tautan, judul);
                  },
                  child: const Text("Unduh"),
                ),
              ],
            ),
          ],

        );
      },
    );
  }

  Future<void> downloadAndShowConfirmation(BuildContext context, String imgUrl,
      String fileName) async {
    if (Platform.isIOS) {
      try {
        Fluttertoast.showToast(
          msg: "Menyiapkan berkas infografis...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        final response = await http.get(Uri.parse(imgUrl));
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
          final filePath = '${dir.path}/$cleanName.jpg';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          LoggerService.logActivity(
            actionType: 'download_file',
            sectorCategory: 'infografis',
            itemName: fileName,
            coverUrl: imgUrl,
            contentUrl: imgUrl,
          );

          await OpenFile.open(filePath);
        } else {
          throw Exception("Gagal mengunduh berkas dari server.");
        }
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Gagal mengunduh: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      return;
    }

    // Check if the necessary permissions are granted
    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas publikasi sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        String cleanFileName = fileName;
        if (!cleanFileName.toLowerCase().endsWith('.jpg')) {
          cleanFileName = '$cleanFileName.jpg';
        }

        //Download a single file
        FileDownloader.downloadFile(
            url: imgUrl,
            name: cleanFileName,
            downloadDestination: DownloadDestinations.publicDownloads,
            onProgress: (fileName, double progress) {

            },
            onDownloadCompleted: (String path) {
              final decodedPath = Uri.decodeFull(path);
              if (decodedPath.endsWith('.php')) {
                try {
                  final file = File(decodedPath);
                  final newPath = decodedPath.replaceAll('.php', '.jpg');
                  if (file.existsSync()) {
                    file.renameSync(newPath);
                  } else {
                    // Coba gunakan path mentah jika file disimpan dengan %20 literal
                    final rawFile = File(path);
                    final rawNewPath = path.replaceAll('.php', '.jpg');
                    if (rawFile.existsSync()) {
                      rawFile.renameSync(rawNewPath);
                    }
                  }
                } catch (e) {
                  print("Gagal me-rename file: $e");
                }
              }

              // Catat log aktivitas ke Supabase
              LoggerService.logActivity(
                actionType: 'download_file',
                sectorCategory: 'infografis',
                itemName: fileName,
                coverUrl: imgUrl,
                contentUrl: imgUrl,
              );

              Fluttertoast.showToast(
                msg: 'Infografis $fileName telah disimpan.',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            },
            onDownloadError: (String error) {
              Navigator.pop(context); // Close the download dialog
              Fluttertoast.showToast(
                msg: "Gagal mengunduh berkas.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            });
      } catch (error) {
        Navigator.pop(context); // Close the download dialog
        Fluttertoast.showToast(
          msg: "Terjadi kesalahan saat mengunduh. $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
    else {
      // Display a message indicating that the application is not authorized
      Fluttertoast.showToast(
        msg: "Aplikasi belum diizinkan untuk mengakses penyimpanan.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
