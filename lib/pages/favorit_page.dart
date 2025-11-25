import 'package:flutter/material.dart';
// --- PERUBAHAN IMPORT ---
import 'package:mboistats/services/supabase_db_service.dart';
import 'package:provider/provider.dart';
// --- AKHIR PERUBAHAN ---
import 'package:mboistats/theme.dart';
import 'dart:convert'; 
// HAPUS: 'package:flutter_file_downloader/flutter_file_downloader.dart';
// HAPUS: 'package:html/parser.dart' show parse;
// HAPUS: 'package:html_unescape/html_unescape.dart';
// HAPUS: 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// HAPUS: 'dart:io';
// HAPUS: 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

// --- TAMBAHAN BARU ---
import 'package:mboistats/utils/download_helper.dart'; // Import helper baru kita

class FavoritPage extends StatefulWidget {
  const FavoritPage({Key? key}) : super(key: key);

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {

  Widget _buildFavoriteItem(BuildContext context, Map<String, dynamic> item) {
    // ... (Logika _buildFavoriteItem tidak berubah) ...
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
        Navigator.of(context).pop(); // Cukup pop() saja
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorit Saya'),
          leading: IconButton(
            icon: Image.asset('assets/icons/left-arrow.png', height: 25),
            onPressed: () => Navigator.of(context).pop(), // Cukup pop() saja
          ),
        ),
        body: Consumer<SupabaseDbService>(
          builder: (context, dbService, child) {
            final favoriteItems = dbService.favoriteItems;
            if (favoriteItems.isEmpty) {
              return Center(
                child: Text(
                  'Anda belum memiliki item favorit.',
                  style: regular14.copyWith(color: dark2),
                ),
              );
            }
            return ListView.builder(
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                return _buildFavoriteItem(context, favoriteItems[index]);
              },
            );
          },
        ),
      ),
    );
  }

  // --- PERUBAHAN DI SINI ---
  // Logika dialog ini sekarang memanggil DownloadHelper
  void _showItemDialog(
      BuildContext context,
      Map<String, dynamic> item) {
        
    final String itemType = item['item_type'] ?? 'unknown';
    final String itemTitle = item["title"] ?? "Tanpa Judul";

    final bool isPublikasi = itemType == 'publikasi';
    final bool isInfografis = itemType == 'infografis';
    final bool isBrs = itemType == 'brs';
    final dbService = context.read<SupabaseDbService>();
    final String favoriteKey = dbService.generateItemId(itemType, itemTitle);
    bool isCurrentlyFavorited = dbService.favoriteIds.contains(favoriteKey);

    // Fungsi callback untuk toggle favorit
    void toggleFavorite() async {
      try {
        bool newStatus = !isCurrentlyFavorited;
        
        if (newStatus) {
          Map<String, dynamic> itemToAdd = Map.from(item);
          itemToAdd['type'] = itemType; 
          
          await dbService.addFavorite(itemToAdd);
        } else {
          await dbService.removeFavorite(itemType, itemTitle);
        }
        
        // Update status lokal di dalam dialog
        isCurrentlyFavorited = newStatus;
                          
      } catch (e) {
        print("Error toggling favorite: $e");
      }
    }

    if (isPublikasi || isBrs) {
      DownloadHelper.showPublikasiDialog(
        context: context, 
        title: itemTitle, 
        postType: itemType, 
        pdfUrl: item["pdf"] ?? "", 
        abstract: item["abstract"] ?? "", 
        size: item["size"] ?? "N/A", 
        releaseDate: item["rl_date"] ?? item["date"] ?? "N/A", 
        onToggleFavorite: toggleFavorite, 
        isCurrentlyFavorited: isCurrentlyFavorited,
      );
    } else if (isInfografis) {
      DownloadHelper.showInfografisDialog(
        context: context, 
        title: itemTitle, 
        imageUrl: item['img'] ?? '', 
        releaseDate: item['date'] ?? 'N/A', 
        onToggleFavorite: toggleFavorite, 
        isCurrentlyFavorited: isCurrentlyFavorited,
      );
    } else {
      // Fallback untuk tipe yang tidak dikenal
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(itemTitle),
          content: const Text("Tipe data favorit ini tidak dikenali."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            )
          ],
        )
      );
    }
  }

  // HAPUS: Semua metode di bawah ini telah dipindahkan ke DownloadHelper
  // Future<void> _downloadFile(...) { ... }
  // Future<bool> _checkPermission() { ... }
  // void _openPdfDirectly(...) { ... }
  // HAPUS: class PDFViewer { ... }
}