import 'package:flutter/foundation.dart';
import 'package:mboistats/main.dart'; 
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Gunakan variabel 'supabase' global dari main.dart
final _supabase = supabase;

class SupabaseDbService with ChangeNotifier {
  final SupabaseAuthService _authService;

  List<Map<String, dynamic>> _favoriteItems = [];
  Set<String> _favoriteIds = {};

  // Getter publik agar UI bisa mengakses data
  List<Map<String, dynamic>> get favoriteItems => _favoriteItems;
  Set<String> get favoriteIds => _favoriteIds;

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _favoriteStreamSubscription;

  SupabaseDbService(this._authService) {
    checkCurrentUser();
    _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void checkCurrentUser() {
    final user = _authService.currentUser;
    if (user != null) {
      print("DEBUG: DbService checkCurrentUser, user SUDAH login: ${user.id}");
      _listenToFavorites(user.id);
    } else {
      print("DEBUG: DbService checkCurrentUser, user BELUM login.");
    }
  }

  void _onAuthStateChanged(AuthState authState) {
    final user = authState.session?.user;
    if (user != null) {
      print("DEBUG: State management sadar (aware) user login: ${user.id}");
      _listenToFavorites(user.id);
    } else {
      print("DEBUG: State management sadar (aware) user logout.");
      _clearFavorites();
    }
  }

  void _listenToFavorites(String userId) {
    _favoriteStreamSubscription?.cancel();
    print("DEBUG: Memulai listener favorit BARU untuk user: $userId");
    
    _favoriteStreamSubscription = _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
      (list) {
        _favoriteItems = list.map(_flattenItemData).toList();
        _favoriteIds =
            _favoriteItems.map((item) => generateItemId(item['item_type'], item['title'])).toSet();
        
        print("DEBUG: Data favorit baru diterima dari stream. Count: ${_favoriteIds.length}");
        notifyListeners();
      },
      onError: (e) {
        print("ERROR: Gagal mendengarkan stream favorit: $e");
      },
    );
  }

  Map<String, dynamic> _flattenItemData(Map<String, dynamic> map) {
    final itemData = map['item_data'] as Map<String, dynamic>? ?? {};
    return {
      'id': map['id'],
      'user_id': map['user_id'],
      'item_id': map['item_id'], 
      'item_type': map['item_type'],
      'title': map['title'],
      'created_at': map['created_at'],
      ...itemData,
    };
  }

  void _clearFavorites() {
    _favoriteStreamSubscription?.cancel();
    _favoriteItems = [];
    _favoriteIds = {};
    print("DEBUG: Data favorit dibersihkan (karena logout).");
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _favoriteStreamSubscription?.cancel();
    super.dispose();
  }

  String generateItemId(String? itemType, String? itemTitle) {
    final type = itemType ?? 'unknown';
    final title = itemTitle ?? 'Tanpa Judul';
    final cleanTitle = title.replaceAll(RegExp(r'\s+'), '_');
    final sanitizedTitle = cleanTitle.trim();
    return 'favorite_${type}_$sanitizedTitle';
  }

  Future<void> addFavorite(Map<String, dynamic> item) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
        print("--- ERROR: ADD FAVORITE GAGAL (User ID NULL) ---");
        return;
    }

    final itemType = item['type'] as String? ?? 'unknown';
    final title = item['title'] as String? ?? 'Tanpa Judul';
    final itemId = generateItemId(itemType, title);

    // --- PERBAIKAN DI SINI: GUARD CLAUSE ---
    // Cek state lokal. Jika item SUDAH ada di _favoriteIds,
    // berarti user melakukan double-click. Abaikan perintah ini.
    if (_favoriteIds.contains(itemId)) {
      print("DEBUG: ADD FAVORITE diabaikan, item sudah ada di state lokal.");
      return; 
    }
    // --- AKHIR PERBAIKAN ---

    print("--- DEBUG: ADD FAVORITE ---");
    print("User ID: $userId");
    print("Item ID (Sangat Bersih): $itemId");
    print("---------------------------");

    final Map<String, dynamic> itemData = Map.from(item);
    itemData.remove('type');
    itemData.remove('title');

    try {
      final newRecord = await _supabase.from('favorites').insert({
        'user_id': userId,
        'item_id': itemId, 
        'item_type': itemType,
        'title': title, 
        'item_data': itemData,
      }).select(); 

      // Workaround untuk Free Tier
      if (newRecord.isNotEmpty) {
        final newItem = _flattenItemData(newRecord[0]);
        _favoriteItems.insert(0, newItem); 
        _favoriteIds.add(itemId);
      }
      
      print("DEBUG: addFavorite manual notifyListeners()");
      notifyListeners();

    } catch (e) {
      print("--- ERROR: ADD FAVORITE GAGAL ---");
      print("Error: $e");
      print("---------------------------------");
    }
  }

  Future<void> removeFavorite(String? itemType, String? itemTitle) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      print("--- ERROR: REMOVE FAVORITE GAGAL (User ID NULL) ---");
      return;
    }

    final itemId = generateItemId(itemType, itemTitle);

    // --- PERBAIKAN DI SINI: GUARD CLAUSE ---
    // Cek state lokal. Jika item TIDAK ada di _favoriteIds,
    // berarti user melakukan double-click. Abaikan perintah ini.
    if (!_favoriteIds.contains(itemId)) {
      print("DEBUG: REMOVE FAVORITE diabaikan, item tidak ada di state lokal.");
      return;
    }
    // --- AKHIR PERBAIKAN ---

    print("--- DEBUG: REMOVE FAVORITE ---");
    print("User ID: $userId");
    print("Item ID (Sangat Bersih): $itemId");
    print("------------------------------");

    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('item_id', itemId); 
          
      // Workaround untuk Free Tier
      _favoriteItems.removeWhere((item) => 
          generateItemId(item['item_type'], item['title']) == itemId);
      _favoriteIds.remove(itemId);

      print("DEBUG: removeFavorite manual notifyListeners()");
      notifyListeners();
          
    } catch (e) {
      print("--- ERROR: REMOVE FAVORITE GAGAL ---");
      print("Error: $e");
      print("----------------------------------");
    }
  }
}