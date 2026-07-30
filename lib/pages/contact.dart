import 'package:flutter/material.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Contact extends StatelessWidget {
  const Contact({Key? key}) : super(key: key);

  void _logAndLaunch(String action, String item, String? url) {
    LoggerService.logActivity(
      actionType: 'click_contact',
      sectorCategory: 'kontak',
      itemName: item,
    );
    if (url != null && url.isNotEmpty) {
      launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  void _logAndNavigate(BuildContext context, String action, String item, String route) {
    LoggerService.logActivity(
      actionType: 'click_contact_menu',
      sectorCategory: 'kontak',
      itemName: item,
    );
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Cream Container wrapping both Title/Subtitle AND the 6 Contact Cards
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A261F) : const Color(0xFFFCF8EC),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kontak Kami',
                      style: pjsBold20.copyWith(
                        color: isDark ? const Color(0xFFFFD59E) : const Color(0xFF4A2E1B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kami siap membantu Anda. Hubungi kami untuk informasi lebih lanjut.',
                      textAlign: TextAlign.center,
                      style: pjsRegular14.copyWith(
                        color: isDark ? const Color(0xFFD6C5B0) : const Color(0xFF7A5C43),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2x3 Grid of White Contact Cards inside the Cream Container
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                      children: [
                        _buildContactCard(
                          context: context,
                          icon: 'assets_v2/icons/alamat.png',
                          title: 'Alamat',
                          subtitle: 'Jl. Janti Barat No.47, Sukun',
                          onTap: () => _logAndLaunch('click_alamat', 'Alamat BPS Malang', 'https://maps.google.com/?q=BPS+Kota+Malang'),
                        ),
                        _buildContactCard(
                          context: context,
                          icon: 'assets_v2/icons/telepon.png',
                          title: 'Telepon',
                          subtitle: '(0341) 801164',
                          onTap: () => _logAndLaunch('click_telepon', 'Telepon BPS Malang', 'tel:0341801164'),
                        ),
                        _buildContactCard(
                          context: context,
                          icon: 'assets_v2/icons/email.png',
                          title: 'Email',
                          subtitle: 'bps3573@bps.go.id',
                          onTap: () => _logAndLaunch('click_email', 'Email BPS Malang', 'mailto:bps3573@bps.go.id'),
                        ),
                        _buildContactCard(
                          context: context,
                          icon: 'assets_v2/icons/Whatsapp.png',
                          title: 'WhatsApp',
                          subtitle: '+62 81250503573',
                          onTap: () => _logAndLaunch('click_whatsapp', 'WhatsApp BPS Malang', 'https://wa.me/6281250503573'),
                        ),
                        _buildContactCard(
                          context: context,
                          icon: 'assets_v2/icons/Instagram.png',
                          title: 'Instagram',
                          subtitle: '@bpskotamalang',
                          onTap: () => _logAndLaunch('click_instagram', 'Instagram BPS Malang', 'https://instagram.com/bpskotamalang'),
                        ),
                        _buildContactCard(
                          context: context,
                          icon: 'assets_v2/icons/website.png',
                          title: 'Website',
                          subtitle: 'malangkota.bps.go.id',
                          onTap: () => _logAndLaunch('click_website', 'Website BPS Malang', 'https://malangkota.bps.go.id'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu List Tiles (Informasi Pelayanan, Tentang Kami, Galeri InovaZI, Pengaduan, Feedback)
              _buildMenuItem(
                context: context,
                icon: 'assets_v2/icons/informasi_pelayanan.png',
                title: 'Informasi Pelayanan',
                onTap: () => _logAndNavigate(context, 'click_informasi_pelayanan', 'Informasi Pelayanan', '/informasipelayanan'),
              ),
              _buildMenuItem(
                context: context,
                icon: 'assets_v2/icons/tentang_kami.png',
                title: 'Tentang Kami',
                onTap: () => _logAndNavigate(context, 'click_tentang_kami', 'Tentang Kami', '/tentang'),
              ),
              _buildMenuItem(
                context: context,
                icon: 'assets_v2/icons/galeri_inovazi.png',
                title: 'Galeri InovaZI',
                onTap: () => _logAndLaunch('click_galeri_inovazi', 'Galeri InovaZI', 'https://s.bps.go.id/mboistats_galeri_inovazi'),
              ),
              _buildMenuItem(
                context: context,
                icon: 'assets_v2/icons/pengaduan.png',
                title: 'Pengaduan',
                onTap: () => _logAndLaunch('click_pengaduan', 'Pengaduan', 'https://s.bps.go.id/mboistats_lapor3573'),
              ),
              _buildMenuItem(
                context: context,
                icon: 'assets_v2/icons/feedback.png',
                title: 'Feedback',
                onTap: () => _logAndLaunch('click_feedback', 'Feedback', 'https://s.bps.go.id/mboistats_feedback'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.contact_phone, color: blueNormal, size: 44),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: pjsBold14.copyWith(color: isDark ? Colors.white : dark1),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: pjsRegular12.copyWith(color: isDark ? Colors.white70 : dark2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFEDEDED)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Image.asset(
          icon,
          width: 32,
          height: 32,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.info, color: blueNormal),
        ),
        title: Text(
          title,
          style: pjsSemiBold14.copyWith(color: isDark ? Colors.white : dark1),
        ),
        trailing: const Icon(
          Icons.play_arrow,
          size: 14,
          color: blueNormal,
        ),
      ),
    );
  }
}
