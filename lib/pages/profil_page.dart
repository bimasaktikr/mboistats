import 'package:flutter/material.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/main.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mboistats/config/auth_config.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'package:mboistats/services/customer_api_service.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool _notificationsEnabled = true;
  String _userName = 'Pengguna';
  String _userEmail = '';
  String? _userAvatar;
  String? _userMajor;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    LoggerService.logActivity(
      actionType: 'view_page',
      sectorCategory: 'profil',
      itemName: 'Halaman Profil',
    );
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
        _userName = user.userMetadata?['full_name'] ?? 'Pengguna';
        _userAvatar = user.userMetadata?['avatar_url'];
      });
    }
    final major = await RecommendationService.getMajor();
    
    // Tarik data kustomer dari Supabase (tabel users_buku_tamu) dengan fallback ke API Endpoint
    CustomerProfileData? customerApiData;
    if (_userEmail.isNotEmpty) {
      customerApiData = await CustomerApiService.getCustomerFromSupabase(_userEmail);
      customerApiData ??= await CustomerApiService.getCustomerByEmail(_userEmail);
    }

    if (mounted) {
      setState(() {
        _userMajor = major;
        if (customerApiData != null && customerApiData.name != null) {
          _userName = customerApiData.name!;
        }
        _isLoadingProfile = false;
      });
    }
  }

  void _showLogoutDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout', style: pjsBold18),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Anda?',
          style: pjsRegular14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: pjsMedium14),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: blueNormal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              LoggerService.logActivity(
                actionType: 'logout',
                sectorCategory: 'profil',
                itemName: 'Logout Akun',
              );
              try {
                RecommendationService.clearLocalCache();
                await GoogleSignIn.instance.initialize(
                  serverClientId: AuthConfig.webClientId,
                  clientId: AuthConfig.iosClientId,
                );
                await GoogleSignIn.instance.signOut();
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                print("Logout error: $e");
              }
              if (mounted) {
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun (Debug/Testing)', style: pjsBold18),
        content: const Text(
          'Apakah Anda yakin ingin menghapus akun? Data profil Anda akan dihapus dari Supabase.',
          style: pjsRegular14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: pjsMedium14),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              LoggerService.logActivity(
                actionType: 'delete_account',
                sectorCategory: 'profil',
                itemName: 'Hapus Akun',
              );
              try {
                await GoogleSignIn.instance.initialize(
                  serverClientId: AuthConfig.webClientId,
                  clientId: AuthConfig.iosClientId,
                );
                await RecommendationService.deleteProfile();
                await GoogleSignIn.instance.signOut();
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                print("Delete account error: $e");
              }
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Profil akun telah dibersihkan.'),
                    backgroundColor: Colors.red,
                  ),
                );
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Teal Gradient Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 24,
                20,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerTealStart, headerTealEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFE2F3FC),
                      backgroundImage: _userAvatar != null ? NetworkImage(_userAvatar!) : null,
                      child: _userAvatar == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: blueNormal,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: pjsBold20.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: pjsRegular14.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (_userMajor != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _userMajor!,
                              style: pjsSemiBold12.copyWith(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Card Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildMenuCard(
                    context: context,
                    iconPath: 'assets_v2/icons/edit_profil.png',
                    title: 'Edit Profil',
                    onTap: () {
                      LoggerService.logActivity(
                        actionType: 'click_menu',
                        sectorCategory: 'profil',
                        itemName: 'Edit Profil',
                      );
                      Navigator.pushNamed(context, '/edit_profil').then((_) {
                        _loadProfileData();
                      });
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    iconPath: 'assets_v2/icons/mode_gelap.png',
                    title: 'Mode Gelap',
                    trailing: Switch(
                      value: appThemeNotifier.isDarkMode,
                      activeThumbColor: blueNormal,
                      onChanged: (val) {
                        LoggerService.logActivity(
                          actionType: 'toggle_dark_mode',
                          sectorCategory: 'profil',
                          itemName: val ? 'Enable Dark Mode' : 'Disable Dark Mode',
                        );
                        appThemeNotifier.toggleDarkMode();
                      },
                    ),
                  ),
                  _buildMenuCard(
                    context: context,
                    iconPath: 'assets_v2/icons/notifikasi.png',
                    title: 'Notifikasi',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: blueNormal,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                        LoggerService.logActivity(
                          actionType: 'toggle_notification',
                          sectorCategory: 'profil',
                          itemName: val ? 'Enable Notification' : 'Disable Notification',
                        );
                      },
                    ),
                  ),
                  _buildMenuCard(
                    context: context,
                    iconPath: 'assets_v2/icons/logout.png',
                    title: 'Logout',
                    onTap: _showLogoutDialog,
                  ),
                  _buildMenuCard(
                    context: context,
                    iconPath: 'assets_v2/icons/hapus_akun.png',
                    title: 'Hapus Akun',
                    onTap: _showDeleteAccountDialog,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String iconPath,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFEDEDED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F9FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            iconPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.settings, color: blueNormal, size: 20),
          ),
        ),
        title: Text(
          title,
          style: pjsSemiBold14.copyWith(
            color: isDark ? Colors.white : dark1,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white54 : dark3,
            ),
      ),
      ),
    );
  }
}
