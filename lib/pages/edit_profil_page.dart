import 'package:flutter/material.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mboistats/services/customer_api_service.dart';

class EditProfilPage extends StatefulWidget {
  const EditProfilPage({Key? key}) : super(key: key);

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = true;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    LoggerService.logActivity(
      actionType: 'view_page',
      sectorCategory: 'profil',
      itemName: 'Halaman Edit Profil',
    );
  }

  void _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      
      String fullName = user.userMetadata?['full_name'] as String? ?? '';
      
      // Ambil nama dari tabel users_buku_tamu jika tersedia
      final customerData = await CustomerApiService.getCurrentUserProfile();
      if (customerData?.name != null && customerData!.name!.isNotEmpty) {
        fullName = customerData.name!;
      }
      
      final nameParts = fullName.split(' ');
      if (nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.sublist(1).join(' ');
        }
      }
      
      _avatarUrl = user.userMetadata?['avatar_url'] as String?;
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();
    final fullName = '$newFirstName $newLastName'.trim();
    final email = _emailController.text.trim();
    
    try {
      // 1. Update metadata di Supabase Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'full_name': fullName},
        ),
      );

      // 2. Sinkronkan perubahan ke tabel user_all
      if (email.isNotEmpty) {
        await CustomerApiService.updateCustomerInSupabase(
          email: email,
          updateData: {'name': fullName},
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: blueNormal,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profil',
          style: pjsBold18.copyWith(
            color: isDark ? Colors.white : dark1,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets_v2/icons/back_arrow.png',
            width: 24,
            height: 24,
            color: isDark ? Colors.white : dark1,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: blueNormal))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Icon Top Center
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE2F3FC),
                        border: Border.all(color: blueNormal, width: 2),
                      ),
                      child: _avatarUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(_avatarUrl!),
                              backgroundColor: Colors.transparent,
                            )
                          : const CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.person_rounded,
                                size: 64,
                                color: blueNormal,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: blueNormal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Theme.of(context).scaffoldBackgroundColor
                                : bgColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form TextFields
              _buildTextField(
                label: 'Nama Depan',
                controller: _firstNameController,
              ),

              const SizedBox(height: 20),

              _buildTextField(
                label: 'Nama Belakang',
                controller: _lastNameController,
              ),

              const SizedBox(height: 20),

              _buildTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true, // Email sebaiknya tidak diubah secara langsung jika menggunakan SSO
              ),

              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    LoggerService.logActivity(
                      actionType: 'click_save_profile',
                      sectorCategory: 'profil',
                      itemName: 'Simpan Profil',
                    );
                    _saveProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueNormal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Simpan',
                    style: pjsBold16.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: pjsSemiBold14.copyWith(
            color: isDark ? Colors.white70 : dark1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: pjsRegular14.copyWith(
            color: readOnly ? (isDark ? Colors.white54 : Colors.grey) : (isDark ? Colors.white : dark1),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : const Color(0xFFEDEDED),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : const Color(0xFFEDEDED),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: blueNormal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
