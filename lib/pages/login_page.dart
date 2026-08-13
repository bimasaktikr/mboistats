import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mboistats/services/recommendation_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    LoggerService.logActivity(
      actionType: 'view_page',
      sectorCategory: 'auth',
      itemName: 'Halaman Login',
    );

    // Dengarkan perubahan state autentikasi (berguna untuk deep link callback)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        RecommendationService.clearLocalCache();
        final currentUser = Supabase.instance.client.auth.currentUser;
        LoggerService.logActivity(
          actionType: 'login_success',
          sectorCategory: 'auth',
          itemName: 'Login Google Sukses',
          userId: currentUser?.email ?? currentUser?.id,
        );
        final hasProfile = await RecommendationService.checkProfileExists();
        if (mounted) {
          if (hasProfile) {
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        }
      }
    });
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F3F4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [headerTealStart, blueNormal],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 20),

                // Welcome Header Text
                Column(
                  children: [
                    Text(
                      'Selamat Datang di',
                      style: pjsMedium16.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'MBOIStats+',
                      style: pjsBold24.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Layanan Data & Informasi Statistik Kota Malang',
                      textAlign: TextAlign.center,
                      style: pjsRegular14.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),

                // Center White Card with Logo
                Container(
                  width: 180,
                  height: 180,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets_v2/icons/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/Mbois-stat Logo_Fix Putih.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.bar_chart_rounded,
                            size: 90,
                            color: blueNormal,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Google SSO Login Button
                Column(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      elevation: 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () async {
                          LoggerService.logActivity(
                            actionType: 'click_login_google',
                            sectorCategory: 'auth',
                            itemName: 'Masuk dengan Google',
                          );

                          try {
                            // Web Client ID dari Google Cloud Console
                            const webClientId =
                                '514445291536-chdl933f0j39uuas2dsnb132boen68s7.apps.googleusercontent.com';
                            const iosClientId =
                                '514445291536-o9oot6ilqj8fm0380f160obe4o0vhh15.apps.googleusercontent.com';

                            await GoogleSignIn.instance.initialize(
                              serverClientId: webClientId,
                              clientId: defaultTargetPlatform == TargetPlatform.iOS
                                  ? iosClientId
                                  : null,
                            );

                            final googleUser =
                                await GoogleSignIn.instance.authenticate();
                            if (googleUser == null) {
                              return; // User membatalkan login (tutup popup)
                            }

                            final googleAuth = await googleUser.authentication;
                            final idToken = googleAuth.idToken;

                            if (idToken == null) {
                              throw 'Gagal mendapatkan ID token dari Google.';
                            }

                            await Supabase.instance.client.auth
                                .signInWithIdToken(
                              provider: OAuthProvider.google,
                              idToken: idToken,
                            );
                            // Redirection ditangani oleh onAuthStateChange di atas
                          } catch (e) {
                            print('ERROR NATIVE LOGIN GOOGLE: $e. Mencoba fallback Supabase OAuth...');
                            try {
                              await Supabase.instance.client.auth.signInWithOAuth(
                                OAuthProvider.google,
                                redirectTo: kIsWeb
                                    ? null
                                    : 'io.supabase.mboistats://login-callback',
                                authScreenLaunchMode: LaunchMode.externalApplication,
                              );
                            } catch (oauthErr) {
                              print('ERROR OAUTH FALLBACK: $oauthErr');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal masuk: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGoogleIcon(),
                              const SizedBox(width: 12),
                              Text(
                                'Masuk dengan Google',
                                style: pjsBold16.copyWith(
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Badan Pusat Statistik Kota Malang',
                      style: pjsMedium12.copyWith(
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
