import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk menangani otentikasi sosial (Google & Facebook).
class SocialAuthService {
  static final _supabase = Supabase.instance.client;

  /// Melakukan proses login menggunakan akun Google.
  static Future<void> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final String? idToken = auth.idToken;
        final String? accessToken = auth.accessToken;

        if (idToken == null) throw 'No ID Token found.';

        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        print("Google Login Success & Supabase Authenticated");
      }
    } catch (e) {
      print("Google Login Error: $e");
      rethrow;
    }
  }

  /// Melakukan proses login menggunakan akun Facebook.
  static Future<void> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        
        // Catatan: Supabase signInWithIdToken memerlukan token OIDC. 
        // Jika Facebook tidak memberikan idToken, gunakan provider OAuth normal.
        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.facebook,
          idToken: accessToken.tokenString, 
        );

        print("Facebook Login Success & Supabase Authenticated");
      } else {
        print("Facebook Login Error: Status is ${result.status}");
        throw 'Facebook Login Failed: ${result.status}';
      }
    } catch (e) {
      print("Facebook Login Error: $e");
      rethrow;
    }
  }
}