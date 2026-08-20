import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/theme.dart';
import 'package:mboistats/services/logger_service.dart';

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
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  /// Memeriksa cache lokal atau mengunduh langsung bytes PDF dengan User-Agent BPS
  Future<void> _loadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hashName = 'pdf_cache_${widget.pdfUrl.hashCode}.pdf';
      final file = File('${dir.path}/$hashName');

      if (await file.exists() && (await file.length()) > 0) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
        return;
      }

      // Unduh dari server dengan User-Agent resmi agar tidak di-block oleh WebAPI BPS
      final response = await http.get(
        Uri.parse(widget.pdfUrl),
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/pdf,*/*',
        },
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            _pdfBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat dokumen (HTTP ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengunduh berkas: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
    });

    LoggerService.logActivity(
      actionType: 'download_file',
      sectorCategory: LoggerService.classifySector(widget.title),
      itemName: widget.title,
      contentUrl: widget.pdfUrl,
    );

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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: blueNormal),
                  SizedBox(height: 16),
                  Text(
                    'Memuat dokumen PDF...',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : _pdfBytes != null
              ? SfPdfViewer.memory(
                  _pdfBytes!,
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    if (mounted) {
                      setState(() {
                        _errorMessage = details.description;
                      });
                    }
                  },
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? 'Dokumen tidak dapat dimuat.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blueNormal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadPdf();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
