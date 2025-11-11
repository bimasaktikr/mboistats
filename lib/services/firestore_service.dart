import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  FirestoreService() {
    _userId = _auth.currentUser?.uid;
  }

  // --- TAMBAHAN BARU: STREAM UNTUK ID FAVORIT ---
  /// Stream yang mengeluarkan satu Set berisi ID dokumen favorit.
  /// Sempurna untuk menyinkronkan ikon hati di seluruh aplikasi.
  Stream<Set<String>> get favoriteIdsStream {
    final user = _auth.currentUser;
    if (user == null) {
      // Jika pengguna logout, kirim stream berisi Set kosong.
      return Stream.value({});
    }
    final collectionPath = 'users/${user.uid}/favorites';
    
    // Dengarkan perubahan pada koleksi
    return _firestore.collection(collectionPath).snapshots().map((snapshot) {
      // Ubah daftar dokumen menjadi satu Set berisi ID-nya
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }
  // --- AKHIR TAMBAHAN BARU ---

  /// Mengambil daftar lengkap data favorit (untuk Halaman Favorit)
  Stream<List<Map<String, dynamic>>> getFavoritesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error("Pengguna belum login untuk mengambil favorit.");
    }
    final collectionPath = 'users/${user.uid}/favorites';
    
    return _firestore
        .collection(collectionPath)
        .orderBy('favorited_at', descending: true) // Urutkan berdasarkan waktu
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Mengecek apakah satu item sudah difavoritkan (untuk dialog)
  Future<bool> isFavorite(String itemType, String itemTitle) async {
    if (_userId == null) return false;
    final docId = 'favorite_${itemType}_$itemTitle';
    final docRef =
        _firestore.collection('users').doc(_userId).collection('favorites').doc(docId);
    final doc = await docRef.get();
    return doc.exists;
  }
  
  /// Mengambil satu Set ID favorit (untuk Pengecekan Satu Kali)
  /// CATATAN: Ini tidak lagi digunakan oleh halaman grid/carousel
  Future<Set<String>> getFavoriteIds() async {
    if (_userId == null) return {};
    final collectionPath = 'users/$_userId/favorites';
    final snapshot = await _firestore.collection(collectionPath).get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// Menambah/Memperbarui item ke favorit
  Future<void> addFavorite(Map<String, dynamic> item) async {
    if (_userId == null) return;
    final itemType = item['type'];
    final itemTitle = item['title'];
    final docId = 'favorite_${itemType}_$itemTitle';
    
    item['favorited_at'] = FieldValue.serverTimestamp(); // Gunakan timestamp server

    final docRef =
        _firestore.collection('users').doc(_userId).collection('favorites').doc(docId);
    await docRef.set(item, SetOptions(merge: true));
  }

  /// Menghapus item dari favorit
  Future<void> removeFavorite(String itemType, String itemTitle) async {
    if (_userId == null) return;
    final docId = 'favorite_${itemType}_$itemTitle';
    final docRef =
        _firestore.collection('users').doc(_userId).collection('favorites').doc(docId);
    await docRef.delete();
  }
}