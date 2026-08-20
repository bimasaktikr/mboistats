import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mboistats/theme.dart';
import 'package:mboistats/components/global_pdf_viewer.dart';
import 'package:saf/saf.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart' show parse;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class PublikasiPage extends StatefulWidget {
  const PublikasiPage({Key? key}) : super(key: key);

  @override
  _PublikasiPageState createState() => _PublikasiPageState();
}

class _PublikasiPageState extends State<PublikasiPage> {
  late Saf saf;
  List<Map<String, dynamic>> dataPublikasi = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchDataPublikasi();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && hasMore) {
        fetchDataPublikasi();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchDataPublikasi() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = "https://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/$currentPage/key/9db89e91c3c142df678e65a78c4e547f";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final parsedResponse = json.decode(response.body);
      final publikasi = List<Map<String, dynamic>>.from(parsedResponse["data"][1]);

      setState(() {
        if (publikasi.isNotEmpty) {
          dataPublikasi.addAll(publikasi);
          currentPage++;
        } else {
          hasMore = false;
        }
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publikasi'),
        leading: IconButton(
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3 / 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        itemCount: dataPublikasi.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == dataPublikasi.length) {
            return hasMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox();
          }

          return InkWell(
            onTap: () => showDownloadDialog(context, dataPublikasi[index]["pdf"], index),
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
                      dataPublikasi[index]['cover'],
                      width: double.infinity,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          dataPublikasi[index]["title"],
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

  void showDownloadDialog(BuildContext context, String pdfUrl, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            dataPublikasi[index]["title"],
            textAlign: TextAlign.center,
            style: bold16.copyWith(color: dark1),
          ),
            content: SingleChildScrollView(
              child: Row(
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dataPublikasi[index]["abstract"] != null && (dataPublikasi[index]["abstract"] as String).isNotEmpty
                              ? (parse(HtmlUnescape().convert(dataPublikasi[index]["abstract"])).body?.text ?? '')
                              : (dataPublikasi[index]["title"] ?? ''),
                          style: TextStyle(fontSize: 13, color: dark1),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 8),
                        if (dataPublikasi[index]["size"] != null)
                          Text(
                            "Ukuran Berkas: ${(dataPublikasi[index]["size"] as String).replaceAll('.', ',')}",
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey
                            ),
                          ),
                        if (dataPublikasi[index]["rl_date"] != null || dataPublikasi[index]["created_at"] != null)
                          Text(
                            "Tanggal Rilis: ${dataPublikasi[index]["rl_date"] ?? dataPublikasi[index]["created_at"]?.toString().split('T')[0] ?? ''}",
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
                const SizedBox(width: 16), // space between buttons
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    String fileName = dataPublikasi[index]["title"];
                    await downloadAndShowConfirmation(context, pdfUrl, fileName);
                  },
                  child: const Text("Unduh"),
                ),
                const SizedBox(width: 16), // space between buttons
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    String fileName = dataPublikasi[index]["title"];
                    LoggerService.logActivity(
                      actionType: 'view_pdf',
                      contentType: 'publikasi',
                      sectorCategory: LoggerService.classifySector(fileName),
                      itemName: fileName,
                      coverUrl: dataPublikasi[index]["cover"],
                      contentUrl: pdfUrl,
                    );
                    openPdfDirectly(context, pdfUrl, fileName);
                  },
                  child: const Text("Buka PDF"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadAndShowConfirmation(BuildContext context, String pdfUrl, String fileName) async {
    final item = dataPublikasi.firstWhere((x) => x['pdf'] == pdfUrl, orElse: () => {});
    final coverUrl = item['cover'] as String?;

    if (Platform.isIOS) {
      try {
        Fluttertoast.showToast(
          msg: "Menyiapkan berkas publikasi...",
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
          final filePath = '${dir.path}/$cleanName.pdf';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          LoggerService.logActivity(
            actionType: 'download_file',
            sectorCategory: 'publikasi',
            itemName: fileName,
            coverUrl: coverUrl,
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
          msg: "Berkas publikasi sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        String cleanFileName = fileName;
        if (!cleanFileName.toLowerCase().endsWith('.pdf')) {
          cleanFileName = '$cleanFileName.pdf';
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
                  final newPath = decodedPath.replaceAll('.php', '.pdf');
                  if (file.existsSync()) {
                    file.renameSync(newPath);
                  } else {
                    // Coba gunakan path mentah jika file disimpan dengan %20 literal
                    final rawFile = File(path);
                    final rawNewPath = path.replaceAll('.php', '.pdf');
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
                sectorCategory: 'publikasi',
                itemName: fileName,
                coverUrl: coverUrl,
                contentUrl: pdfUrl,
              );

              Fluttertoast.showToast(
                msg: 'Publikasi "$fileName" telah disimpan.',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            },
            onDownloadError: (String error) {
              Fluttertoast.showToast(
                msg: "Gagal mengunduh berkas.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            });
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Terjadi kesalahan saat mengunduh. \$error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
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
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
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

  void openPdfDirectly(BuildContext context, String pdfUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalPDFViewer(pdfUrl: pdfUrl, title: title),
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
