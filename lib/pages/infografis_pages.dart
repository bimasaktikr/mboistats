import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mboistats/theme.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saf/saf.dart';

class InfografisPages extends StatefulWidget {
  const InfografisPages({Key? key}) : super(key: key);

  @override
  _InfografisPagesState createState() => _InfografisPagesState();
}

class _InfografisPagesState extends State<InfografisPages> {
  late Saf saf;
  List<Map<String, dynamic>> dataInfografis = [];
  String imageUrl = ''; // Variable to store the PDF URL

  @override
  void initState() {
    super.initState();
    fetchDataInfografis();
  }

  Future<void> fetchDataInfografis() async {
    const String apiUrl = "https://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/key/9db89e91c3c142df678e65a78c4e547f";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final parsedResponse = json.decode(response.body);
      final infografis = parsedResponse["data"][1];

      setState(() {
        dataInfografis = List<Map<String, dynamic>>.from(infografis);
      });

    } else {
      throw Exception('Failed to load data');
    }
  }

  String truncateText(String text, int maxLength) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }

  void openDownloadConfirmation(BuildContext context, String imageUrl, int index, String imageTitle) async {
    try {
      bool confirmDownload = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Konfirmasi Unduh"),
            content: const Text("Apakah Anda ingin mengunduh berkas infografis ini?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text("Tidak"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, false);
                  String imageTitle = dataInfografis[index]["title"];
                  await downloadAndShowConfirmation(context, imageUrl, imageTitle);
                },
                child: const Text("Ya"),
              ),
            ],
          );
        },
      );

      if (confirmDownload == true) {
        downloadAndShowConfirmation(context, imageUrl, imageTitle);
      }
    } catch (error) {}
  }

  Future<void> downloadAndShowConfirmation(BuildContext context, String pdfUrl, String fileName) async {
    // Check if the necessary permissions are granted
    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas infografis sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        //Download a single file
        FileDownloader.downloadFile(
            url: pdfUrl,
            name: fileName,
            downloadDestination: DownloadDestinations.publicDownloads,
            onProgress: (fileName, double progress) {

            },
            onDownloadCompleted: (String path) {
              //Renaming File Extension
              String fileExt = path.substring(path.lastIndexOf('.'),path.length);
              File downloadedFile = File('/storage/emulated/0/Download/$fileName$fileExt');
              downloadedFile.rename(downloadedFile.path.replaceAll('.php', '.jpg'));

              Fluttertoast.showToast(
                msg: 'Infografis $fileName.jpg telah disimpan dalam Folder Download.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infografis'),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/left-arrow.png',
            height: 25,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView.builder(
        itemCount: dataInfografis.length,
        itemBuilder: (context, index) {

          return Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: InkWell(
              onTap: () {
                String imageUrl = dataInfografis[index]["img"];
                String title = dataInfografis[index]["title"];
                openDownloadConfirmation(context, imageUrl, index, title);
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  leading: Image.asset(
                    'assets/icons/infographics.png',
                    width: 40,
                    height: 40,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          dataInfografis[index]["title"],
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
          );
        },
      ),
    );
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var permissionStatus = await Permission.storage.status;

      if (permissionStatus.isDenied) {
        await Permission.storage.request();
        await saf.getDirectoryPermission(isDynamic: true);
        return permissionStatus.isGranted;
      }
      else {
        return permissionStatus.isGranted;
      }
    }
    return true;
  }
}