import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class GlobalPDFViewer extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const GlobalPDFViewer({
    Key? key,
    required this.pdfUrl,
    this.title = 'Dokumen Statistik',
  }) : super(key: key);

  @override
  _GlobalPDFViewerState createState() => _GlobalPDFViewerState();
}

class _GlobalPDFViewerState extends State<GlobalPDFViewer> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
    });

    // Ambil nama file dari URL atau gunakan default
    String fileName = widget.title.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = '$fileName.pdf';
    }

    try {
      if (Platform.isIOS) {
        Fluttertoast.showToast(
          msg: "Menyiapkan berkas unduhan...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        );

        final response = await http.get(Uri.parse(widget.pdfUrl));
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          Fluttertoast.showToast(
            msg: "Unduhan selesai.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          );

          await OpenFile.open(filePath);
        } else {
          throw Exception("Gagal mengunduh berkas dari server.");
        }
      } else {
        Fluttertoast.showToast(
          msg: "Berkas sedang diunduh...",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        );

        await FileDownloader.downloadFile(
          url: widget.pdfUrl,
          name: fileName,
          downloadDestination: DownloadDestinations.publicDownloads,
          onProgress: (name, double progress) {},
          onDownloadCompleted: (String path) {
            // Fallback rename jika file terunduh dengan ekstensi .php karena redirect server BPS
            final decodedPath = Uri.decodeFull(path);
            if (decodedPath.endsWith('.php')) {
              try {
                final file = File(decodedPath);
                final newPath = decodedPath.replaceAll('.php', '.pdf');
                if (file.existsSync()) {
                  file.renameSync(newPath);
                } else {
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

            Fluttertoast.showToast(
              msg: 'Berkas berhasil disimpan di folder Download.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            );
          },
          onDownloadError: (String error) {
            Fluttertoast.showToast(
              msg: "Gagal mengunduh berkas.",
              toastLength: Toast.LENGTH_SHORT,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            );
          },
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Terjadi kesalahan: $e",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Unduh PDF',
                  onPressed: _downloadPdf,
                ),
        ],
      ),
      body: SfPdfViewer.network(widget.pdfUrl),
    );
  }
}
