import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mboistats/theme.dart';
import 'package:saf/saf.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class PublikasiPage extends StatefulWidget {
  const PublikasiPage({Key? key}) : super(key: key);

  @override
  _PublikasiPageState createState() => _PublikasiPageState();
}

class _PublikasiPageState extends State<PublikasiPage> {
  late Saf saf;
  List<Map<String, dynamic>> dataPublikasi = [];
  List<String> abstraksiBrs = [];
  String pdfUrl = '';

  @override
  void initState() {
    super.initState();
    fetchDataPublikasi();
  }

  Future<void> fetchDataPublikasi() async {
    const String apiUrl = "https://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/1/key/9db89e91c3c142df678e65a78c4e547f";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final parsedResponse = json.decode(response.body);
      final publikasi = parsedResponse["data"][1];

      setState(() {
        dataPublikasi = List<Map<String, dynamic>>.from(publikasi);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publikasi'),
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
        itemCount: dataPublikasi.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: InkWell(
              onTap: () {
                String pdfUrl = dataPublikasi[index]["pdf"];
                showDownloadDialog(context, pdfUrl, index);
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
                    'assets/icons/publication.png',
                    width: 40,
                    height: 40,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dataPublikasi[index]["title"],
                              style: bold16.copyWith(color: dark1),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              "Size: ${dataPublikasi[index]["size"]}",
                              style:
                                  const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
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

  void showDownloadDialog(BuildContext context, String pdfUrl, int index) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Unduh"),
          content: const Text("Apakah Anda ingin membuka/mengunduh berkas publikasi ini?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Tidak"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // showToastMessage(pdfUrl);
                String fileName = dataPublikasi[index]["title"];
                await downloadAndShowConfirmation(context, pdfUrl, fileName);
              },
              child: const Text("Unduh"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openPdfDirectly(context, pdfUrl);
              },
              child: const Text("Buka PDF"),
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadAndShowConfirmation(BuildContext context, String pdfUrl, String fileName) async {
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
              downloadedFile.rename(downloadedFile.path.replaceAll(".php", ".pdf"));

              Fluttertoast.showToast(
                msg: 'Publikasi "$fileName.pdf" telah disimpan dalam Folder Download.',
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

  void openPdfDirectly(BuildContext context, String pdfUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewer(pdfUrl: pdfUrl),
      ),
    );
  }
}

class PDFViewer extends StatelessWidget {
  final String pdfUrl;

  const PDFViewer({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: SfPdfViewer.network(
        pdfUrl,
      ),
    );
  }
}


