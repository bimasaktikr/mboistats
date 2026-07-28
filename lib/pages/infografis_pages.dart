import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mboistats/theme.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saf/saf.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class InfografisPages extends StatefulWidget {
  const InfografisPages({Key? key}) : super(key: key);

  @override
  _InfografisPagesState createState() => _InfografisPagesState();
}

class _InfografisPagesState extends State<InfografisPages> {
  late Saf saf;
  List<Map<String, dynamic>> dataInfografis = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchDataInfografis();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && hasMore) {
        fetchDataInfografis();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchDataInfografis() async {
    setState(() => isLoading = true);
    final String apiUrl = "https://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/page/$currentPage/key/9db89e91c3c142df678e65a78c4e547f";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        final List<dynamic> infografis = parsedResponse["data"][1];

        if (infografis.isEmpty) {
          setState(() => hasMore = false);
        } else {
          setState(() {
            currentPage++;
            dataInfografis.addAll(List<Map<String, dynamic>>.from(infografis));
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (_) {
      // Handle error
    } finally {
      setState(() => isLoading = false);
    }
  }

  void openDownloadConfirmation(BuildContext context, String imageUrl, int index, String imageTitle) async {
    try {
      bool confirmDownload = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              dataInfografis[index]["title"],
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
                            dataInfografis[index]['img'],
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tanggal Rilis: ${dataInfografis[index]["date"]}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Tutup"),
                  ),
                  const SizedBox(width: 16), // spacing between buttons
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context, false);
                      String imageTitle = dataInfografis[index]["title"];
                      await downloadAndShowConfirmation(context, imageUrl, imageTitle);
                    },
                    child: const Text("Unduh"),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (confirmDownload == true) {
        downloadAndShowConfirmation(context, imageUrl, imageTitle);
      }
    } catch (error) {

    }
  }

  Future<void> downloadAndShowConfirmation(BuildContext context, String pdfUrl, String fileName) async {
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

        final response = await http.get(Uri.parse(pdfUrl));
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
            coverUrl: pdfUrl,
            contentUrl: pdfUrl,
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

        String cleanFileName = fileName;
        if (!cleanFileName.toLowerCase().endsWith('.jpg')) {
          cleanFileName = '$cleanFileName.jpg';
        }

        FileDownloader.downloadFile(
            url: pdfUrl,
            name: cleanFileName,
            downloadDestination: DownloadDestinations.publicDownloads,
            onProgress: (fileName, double progress) {},
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
                coverUrl: pdfUrl,
                contentUrl: pdfUrl,
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
              Navigator.pop(context);
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
        Navigator.pop(context);
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
    } else {
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
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GridView.builder(
        controller: _scrollController,
        itemCount: dataInfografis.length + (hasMore ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (index == dataInfografis.length) {
            return const Center(child: CircularProgressIndicator());
          }

          return InkWell(
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
                boxShadow: const [
                  BoxShadow(
                    color: Colors.transparent,
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Image.network(
                      dataInfografis[index]['img'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          dataInfografis[index]["title"],
                          style: TextStyle(
                            fontSize: 10,
                            color: dark1,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
}
