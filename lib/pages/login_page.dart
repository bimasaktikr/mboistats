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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background illustration at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets_v2/icons/login_bg.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Welcome Header Text
                  const Text(
                    'Selamat',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: blueNormal,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    'Datang',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Color(0xFF75C7EC), // blueLightActive
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'di MBOIStats+',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: orangeNormal,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Google SSO Login Button
                  Material(
                    color: blueNormal,
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
                            Image.asset(
                              'assets_v2/icons/google_login.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Masuk dengan Google',
                              style: pjsBold16.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
