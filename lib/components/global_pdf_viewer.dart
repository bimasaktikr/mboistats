import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/theme.dart';

/// Native Flutter PDF Viewer (Varian B)
/// Menggunakan Syncfusion C++ PDFium Canvas Engine & Local Disk Caching
/// untuk performa rendering native tanpa Chromium engine.
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
  File? _cachedFile;
  bool _isCheckingCache = true;

  @override
  void initState() {
    super.initState();
    _checkLocalCache();
  }

  /// Memeriksa apakah file PDF sudah tersimpan di cache lokal
  Future<void> _checkLocalCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hashName = 'pdf_cache_${widget.pdfUrl.hashCode}.pdf';
      final file = File('${dir.path}/$hashName');

      if (await file.exists() && (await file.length()) > 0) {
        if (mounted) {
          setState(() {
            _cachedFile = file;
            _isCheckingCache = false;
          });
        }
        return;
      }

      // Unduh & cache file secara latar belakang untuk akses berikutnya
      _cachePdfInBackground(file);
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingCache = false);
      }
    }
  }

  Future<void> _cachePdfInBackground(File file) async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (mounted && _cachedFile == null) {
          setState(() {
            _cachedFile = file;
            _isCheckingCache = false;
          });
        }
      }
    } catch (_) {}
    if (mounted && _isCheckingCache) {
      setState(() => _isCheckingCache = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
    });

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
          backgroundColor: blueNormal,
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
            backgroundColor: blueNormal,
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
          backgroundColor: blueNormal,
          textColor: Colors.white,
        );

        await FileDownloader.downloadFile(
          url: widget.pdfUrl,
          name: fileName,
          downloadDestination: DownloadDestinations.publicDownloads,
          onProgress: (name, double progress) {},
          onDownloadCompleted: (String path) {
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
              backgroundColor: blueNormal,
              textColor: Colors.white,
            );
          },
          onDownloadError: (String error) {
            Fluttertoast.showToast(
              msg: "Gagal mengunduh berkas.",
              toastLength: Toast.LENGTH_SHORT,
              backgroundColor: blueNormal,
              textColor: Colors.white,
            );
          },
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Terjadi kesalahan: $e",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: blueNormal,
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
      body: _cachedFile != null
          ? SfPdfViewer.file(_cachedFile!)
          : SfPdfViewer.network(widget.pdfUrl),
    );
  }
}
