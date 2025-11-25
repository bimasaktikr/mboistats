import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:mboistats/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

/// Service terpusat untuk semua logika unduh,
/// izin (permission), dan dialog.
class DownloadHelper {

  /// Memeriksa (dan meminta) izin penyimpanan.
  static Future<bool> _checkPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var permissionStatus = await Permission.storage.status;
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.storage.request();
      }
      return permissionStatus.isGranted;
    }
    return true; // Izin tidak diperlukan di platform lain
  }

  /// Membuka PDF di viewer internal
  static void openPdfDirectly(BuildContext context, String pdfUrl) {
    if (pdfUrl.isEmpty) {
      Fluttertoast.showToast(msg: "URL PDF tidak valid.");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PDFViewer(pdfUrl: pdfUrl),
      ),
    );
  }

  /// Menangani logika unduh file (PDF atau Gambar)
  static Future<void> downloadFile({
    required BuildContext context,
    required String fileUrl,
    required String fileName,
    required String fileTypeForToast, // e.g., "Publikasi", "Infografis"
    required bool isPublikasi, // Untuk penanganan ekstensi .php
  }) async {
    if (fileUrl.isEmpty) {
      Fluttertoast.showToast(msg: "URL tidak valid.");
      return;
    }

    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas $fileTypeForToast sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
        );

        String extension = ".pdf"; // Default untuk publikasi
        if (!isPublikasi) {
          // Logika untuk menentukan ekstensi gambar (infografis)
          try {
            Uri uri = Uri.parse(fileUrl);
            String path = uri.path;
            int lastDot = path.lastIndexOf('.');
            if (lastDot != -1) {
              extension = path.substring(lastDot);
              int queryStart = extension.indexOf('?');
              if (queryStart != -1) {
                extension = extension.substring(0, queryStart);
              }
            }
            if (extension.isEmpty || extension.length > 5 || extension.contains('/') || extension == '.php') {
              extension = ".jpg"; // Fallback aman
            }
          } catch (_) {
            extension = ".jpg"; // Fallback jika parse URL gagal
          }
        }

        String safeFileName =
            fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

        FileDownloader.downloadFile(
            url: fileUrl.trim(),
            name: "$safeFileName$extension",
            downloadDestination: DownloadDestinations.publicDownloads,
            onDownloadCompleted: (String path) {
              // Ganti nama file jika server mengirim .php untuk .pdf
              if (isPublikasi && path.toLowerCase().endsWith('.php')) {
                File downloadedFile = File(path);
                String newPath = path.replaceAll('.php', '.pdf');
                downloadedFile.renameSync(newPath);
              }
              Fluttertoast.showToast(
                msg: '$fileTypeForToast "$safeFileName$extension" disimpan di Download.',
              );
            },
            onDownloadError: (String error) {
              Fluttertoast.showToast(msg: "Gagal mengunduh: $error");
            });
      } catch (error) {
        Fluttertoast.showToast(msg: "Terjadi kesalahan: $error");
      }
    } else {
      Fluttertoast.showToast(msg: "Izin penyimpanan ditolak.");
    }
  }

  /// Menampilkan dialog terpusat untuk item BRS & Publikasi
  static void showPublikasiDialog({
    required BuildContext context,
    required String title,
    required String postType, // 'brs' atau 'publikasi'
    required String pdfUrl,
    required String abstract,
    required String size,
    required String releaseDate,
    required Function onToggleFavorite,
    required bool isCurrentlyFavorited,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContextInner) {
        // Kita butuh StatefulBuilder agar ikon favorit bisa update
        // tanpa menutup dialog
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: bold16.copyWith(color: dark1),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parse(HtmlUnescape().convert(abstract)).body?.text ?? '',
                      style: TextStyle(fontSize: 13, color: dark1),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Ukuran Berkas: ${size.replaceAll('.', ',')}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Tanggal Rilis: $releaseDate",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContextInner),
                          child: const Text("Tutup"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContextInner);
                            await downloadFile(
                              context: context,
                              fileUrl: pdfUrl,
                              fileName: title,
                              fileTypeForToast: postType,
                              isPublikasi: true,
                            );
                          },
                          child: const Text("Unduh"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContextInner);
                            openPdfDirectly(context, pdfUrl);
                          },
                          child: const Text("Buka PDF"),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // Panggil fungsi callback, lalu update UI dialog
                            onToggleFavorite();
                            setDialogState(() {
                              isCurrentlyFavorited = !isCurrentlyFavorited;
                            });
                          },
                          icon: Icon(
                            isCurrentlyFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isCurrentlyFavorited ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                          label: Text(
                            isCurrentlyFavorited ? 'Favorit' : 'Favoritkan',
                            style: TextStyle(
                                color: isCurrentlyFavorited
                                    ? Colors.red
                                    : Colors.grey[700]),
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  /// Menampilkan dialog terpusat untuk item Infografis
  static void showInfografisDialog({
    required BuildContext context,
    required String title,
    required String imageUrl,
    required String releaseDate,
    required Function onToggleFavorite,
    required bool isCurrentlyFavorited,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContextInner) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: bold16.copyWith(color: dark1),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                            height: 150,
                            child: Center(child: CircularProgressIndicator()));
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tanggal Rilis: $releaseDate",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContextInner),
                          child: const Text("Tutup"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContextInner);
                            await downloadFile(
                              context: context,
                              fileUrl: imageUrl,
                              fileName: title,
                              fileTypeForToast: "Infografis",
                              isPublikasi: false, // Ini gambar
                            );
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 4),
                              Text("Unduh"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            onToggleFavorite();
                            setDialogState(() {
                              isCurrentlyFavorited = !isCurrentlyFavorited;
                            });
                          },
                          icon: Icon(
                            isCurrentlyFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isCurrentlyFavorited ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                          label: Text(
                            isCurrentlyFavorited ? 'Favorit' : 'Favoritkan',
                            style: TextStyle(
                                color: isCurrentlyFavorited
                                    ? Colors.red
                                    : Colors.grey[700]),
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }
}

/// Widget private untuk menampung PDF Viewer
class _PDFViewer extends StatelessWidget {
  final String pdfUrl;
  const _PDFViewer({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        leading: IconButton(
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        onDocumentLoadFailed: (details) {
          print("PDF Load Failed: ${details.description}");
          Fluttertoast.showToast(
              msg: "Gagal memuat PDF: ${details.description}");
        },
      ),
    );
  }
}