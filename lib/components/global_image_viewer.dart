import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';

class GlobalImageViewer extends StatefulWidget {
  final String imageUrl;
  final String title;
  
  const GlobalImageViewer({
    Key? key,
    required this.imageUrl,
    this.title = 'Infografis',
  }) : super(key: key);

  @override
  State<GlobalImageViewer> createState() => _GlobalImageViewerState();
}

class _GlobalImageViewerState extends State<GlobalImageViewer> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _downloadImage() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      LoggerService.logActivity(
        actionType: 'download_file',
        sectorCategory: 'INFOGRAFIS',
        itemName: widget.title,
      );

      String extension = widget.imageUrl.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
      String fileName = widget.title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_') + extension;

      if (Platform.isIOS) {
        final response = await http.get(Uri.parse(widget.imageUrl));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          
          if (mounted) {
            setState(() => _isDownloading = false);
            Fluttertoast.showToast(msg: "Download berhasil. Membuka file...");
            await OpenFile.open(file.path);
          }
        } else {
          throw Exception('Gagal mengunduh gambar');
        }
      } else {
        FileDownloader.downloadFile(
          url: widget.imageUrl,
          name: fileName,
          onProgress: (fileName, progress) {
            if (mounted) {
              setState(() {
                _downloadProgress = progress / 100;
              });
            }
          },
          onDownloadCompleted: (path) async {
            if (mounted) {
              setState(() => _isDownloading = false);
              Fluttertoast.showToast(msg: "Download berhasil. Membuka file...");
              await OpenFile.open(path);
            }
          },
          onDownloadError: (errorMessage) {
            if (mounted) {
              setState(() => _isDownloading = false);
              Fluttertoast.showToast(msg: "Download gagal: $errorMessage");
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        Fluttertoast.showToast(msg: "Terjadi kesalahan saat mengunduh: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: pjsBold16.copyWith(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isDownloading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadImage,
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text('Gagal memuat gambar', style: pjsMedium12.copyWith(color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}
