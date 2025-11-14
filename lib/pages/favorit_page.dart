import 'package:flutter/material.dart';
// --- PERUBAHAN IMPORT ---
import 'package:mboistats/services/supabase_db_service.dart';
import 'package:provider/provider.dart';
// --- AKHIR PERUBAHAN ---
import 'package:mboistats/theme.dart';
import 'dart:convert'; 
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:html/parser.dart' show parse;
import 'package:html_unescape/html_unescape.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({Key? key}) : super(key: key);

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  // Hapus: bool _didChange = false; 
  // Hapus: final SupabaseDbService _dbService = SupabaseDbService();

  Widget _buildFavoriteItem(BuildContext context, Map<String, dynamic> item) {
    final String itemType = item['item_type'] ?? 'unknown'; 
    final bool isPublikasi = itemType == 'publikasi';
    final bool isInfografis = itemType == 'infografis';
    final bool isBrs = itemType == 'brs';

    final String title = item['title'] ?? 'Tanpa Judul';
    String imageUrl = '';
    String date = '';
    String typeLabel = 'Lainnya';
    Color typeColor = Colors.grey;

    if (isPublikasi) {
      imageUrl = item['cover'] ?? '';
      date = item['rl_date'] ?? 'N/A';
      typeLabel = 'Publikasi';
      typeColor = Colors.blue[700]!;
    } else if (isInfografis) {
      imageUrl = item['img'] ?? '';
      date = item['date'] ?? 'N/A';
      typeLabel = 'Infografis';
      typeColor = Colors.green[700]!;
    } else if (isBrs) {
      imageUrl = item['thumbnail'] ?? '';
      date = item['rl_date'] ?? 'N/A';
      typeLabel = 'BRS';
      typeColor = Colors.orange[700]!;
    } else {
      // Fallback jika item_type tidak dikenal
      imageUrl = 'https://placehold.co/70x90/e0e0e0/9e9e9e?text=?';
      date = 'N/A';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: () {
            // Panggil _showItemDialog versi baru
            _showItemDialog(context, item);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    width: 70,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 90,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[400])),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: semibold14.copyWith(color: dark1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Rilis: $date",
                        style: regular12_5.copyWith(color: dark3),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Hapus: Navigator.of(context).pop(_didChange);
        Navigator.of(context).pop(); // Cukup pop() saja
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorit Saya'),
          leading: IconButton(
            icon: Image.asset('assets/icons/left-arrow.png', height: 25),
            // Hapus: onPressed: () => Navigator.of(context).pop(_didChange),
            onPressed: () => Navigator.of(context).pop(), // Cukup pop() saja
          ),
        ),
        // --- PERUBAHAN BESAR DI SINI ---
        body: Consumer<SupabaseDbService>(
          builder: (context, dbService, child) {
            
            // 1. Ambil data favorit langsung dari provider
            final favoriteItems = dbService.favoriteItems;
            
            // 2. Tampilkan pesan jika kosong
            if (favoriteItems.isEmpty) {
              return Center(
                child: Text(
                  'Anda belum memiliki item favorit.',
                  style: regular14.copyWith(color: dark2),
                ),
              );
            }

            // 3. Bangun ListView
            return ListView.builder(
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                return _buildFavoriteItem(context, favoriteItems[index]);
              },
            );
          },
        ),
        // --- AKHIR PERUBAHAN ---
      ),
    );
  }

  // --- PERBAIKAN BESAR DI FUNGSI DIALOG ---
  void _showItemDialog(
      BuildContext context,
      Map<String, dynamic> item) {
        
    final String itemType = item['item_type'] ?? 'unknown';
    final String itemTitle = item["title"] ?? "Tanpa Judul";

    final bool isPublikasi = itemType == 'publikasi';
    final bool isInfografis = itemType == 'infografis';
    final bool isBrs = itemType == 'brs';
    
    // Ambil dbService SATU KALI.
    // PENTING: Gunakan read() karena kita di dalam fungsi/aksi.
    final dbService = context.read<SupabaseDbService>();
    
    // Ambil status favorit saat ini LANGSUNG dari provider
    final String favoriteKey = dbService.generateItemId(itemType, itemTitle); // <-- Gunakan fungsi helper baru
    bool isCurrentlyFavorited = dbService.favoriteIds.contains(favoriteKey);

    showDialog(
      context: context,
      builder: (BuildContext dialogContextInner) {
        // Gunakan StatefulBuilder HANYA untuk update UI di dalam dialog
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            
            void toggleFavorite() async {
              try {
                // Tentukan status baru
                bool newStatus = !isCurrentlyFavorited;
                
                if (newStatus) {
                  // --- PERBAIKAN BUG 'unknown' ---
                  // 'item' dari database tidak punya 'type', jadi kita buat map baru
                  // yang "dikenali" oleh fungsi addFavorite
                  Map<String, dynamic> itemToAdd = Map.from(item);
                  itemToAdd['type'] = itemType; // <-- Kunci perbaikannya di sini
                  
                  await dbService.addFavorite(itemToAdd);
                  // --- AKHIR PERBAIKAN ---
                } else {
                  // Panggil aksi dari provider
                  await dbService.removeFavorite(itemType, itemTitle);
                }
                
                // Update UI lokal di dalam dialog
                if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                  setDialogState(() {
                    isCurrentlyFavorited = newStatus;
                  });
                }
                                
              } catch (e) {
                print("Error toggling favorite: $e");
              }
            }
            
            // ... (Sisa dialog UI tidak berubah) ...
            Widget dialogContent;
            List<Widget> dialogActions = []; 
            List<Widget> mainButtons = []; 

            mainButtons.add(
              TextButton(
                onPressed: () => Navigator.pop(dialogContextInner),
                child: const Text("Tutup"),
              ),
            );

            if (isPublikasi || isBrs) {
              dialogContent = SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parse(HtmlUnescape().convert(item["abstract"] ?? ""))
                              .body
                              ?.text ??
                          '',
                      style: TextStyle(fontSize: 13, color: dark1),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Ukuran Berkas: ${item["size"]?.replaceAll('.', ',') ?? 'N/A'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Tanggal Rilis: ${item["rl_date"] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );

              mainButtons.addAll([
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContextInner);
                    await _downloadFile(context, item["pdf"] ?? "", itemTitle,
                        isPublikasi: true);
                  },
                  child: const Text("Unduh"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContextInner);
                    _openPdfDirectly(context, item["pdf"] ?? "");
                  },
                  child: const Text("Buka PDF"),
                ),
              ]);
            } else if (isInfografis) {
              dialogContent = SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(item['img'] ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                size: 100, color: Colors.grey),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()));
                        }),
                    const SizedBox(height: 8),
                    Text(
                      "Tanggal Rilis: ${item['date'] ?? 'N/A'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );

              mainButtons.add(
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContextInner);
                    await _downloadFile(context, item["img"] ?? "", itemTitle,
                        isPublikasi: false);
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 4),
                      Text("Unduh"),
                    ],
                  ),
                ),
              );
            } else {
              dialogContent = const Text("Data favorit ini tidak dikenali.");
            }
            
            // Tombol favorit sekarang menggunakan 'isCurrentlyFavorited'
            Widget favoriteButton = TextButton(
              onPressed: toggleFavorite,
              child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCurrentlyFavorited // <-- Gunakan variabel dialog
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isCurrentlyFavorited ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCurrentlyFavorited ? 'Favorit' : 'Favoritkan',
                          style: TextStyle(
                              color: isCurrentlyFavorited
                                  ? Colors.red
                                  : Colors.grey[700]),
                        ),
                      ],
                    ),
            );

            dialogActions = [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: mainButtons,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [favoriteButton],
              )
            ];

            return AlertDialog(
              title: Text(
                itemTitle,
                textAlign: TextAlign.center,
                style: bold16.copyWith(color: dark1),
              ),
              content: dialogContent,
              actionsPadding:
                  EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dialogActions,
                )
              ],
            );
          },
        );
      },
    );
  }
  // --- AKHIR PERBAIKAN ---

  // --- FUNGSI HELPER (TIDAK BERUBAH) ---
  Future<void> _downloadFile(BuildContext context, String fileUrl, String fileName,
      {required bool isPublikasi}) async {
    if (fileUrl.isEmpty) {
      Fluttertoast.showToast(msg: "URL tidak valid.");
      return;
    }

    if (await _checkPermission()) {
      try {
        final String fileType = isPublikasi ? "Publikasi" : "Infografis";
        Fluttertoast.showToast(
          msg: "Berkas $fileType sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
        );

        String extension = ".pdf";
        if (!isPublikasi) {
          try {
            Uri uri = Uri.parse(fileUrl);
            String path = uri.path;
            int lastDot = path.lastIndexOf('.');
            if (lastDot != -1) {
              extension = path.substring(lastDot);
              int queryStart = extension.indexOf('?');
              if (queryStart != -1)
                extension = extension.substring(0, queryStart);
            }
            if (extension.isEmpty || extension.length > 5 || extension == '.php')
              extension = ".jpg";
          } catch (_) {
            extension = ".jpg";
          }
        }

        String safeFileName =
            fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

        FileDownloader.downloadFile(
            url: fileUrl.trim(),
            name: "$safeFileName$extension",
            downloadDestination: DownloadDestinations.publicDownloads,
            onDownloadCompleted: (String path) {
              if (isPublikasi && path.toLowerCase().endsWith('.php')) {
                File downloadedFile = File(path);
                String newPath = path.replaceAll('.php', '.pdf');
                downloadedFile.renameSync(newPath);
              }
              Fluttertoast.showToast(
                msg:
                    '$fileType "$safeFileName$extension" disimpan di Download.',
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

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var permissionStatus = await Permission.storage.status;
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.storage.request();
      }
      return permissionStatus.isGranted;
    }
    return true;
  }

  void _openPdfDirectly(BuildContext context, String pdfUrl) {
    if (pdfUrl.isEmpty) {
      Fluttertoast.showToast(msg: "URL PDF tidak valid.");
      return;
    }
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