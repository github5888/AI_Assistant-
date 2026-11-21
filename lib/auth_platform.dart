import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_models.dart';

abstract interface class SessionVault {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class AndroidSessionVault implements SessionVault {
  AndroidSessionVault(Uri origin) : _key = 'itsclear.session.v1:${origin.origin}';
  final String _key;
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

abstract interface class GoogleIdentity {
  Future<String?> idToken();
  Future<void> signOut();
}

class NativeGoogleIdentity implements GoogleIdentity {
  NativeGoogleIdentity(this.serverClientId);
  final String serverClientId;
  Future<void>? _initialization;

  @override
  Future<String?> idToken() async {
    final google = GoogleSignIn.instance;
    try {
      await (_initialization ??= google.initialize(serverClientId: serverClientId));
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const AuthException('Google did not return an identity token. Try Email OTP or check the Google setup.');
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw const AuthException('Google sign-in could not start. Check the app’s Google registration or use Email OTP.');
    }
  }

  @override
  Future<void> signOut() async {
    final initialization = _initialization;
    if (initialization == null) return;
    await initialization;
    await GoogleSignIn.instance.signOut();
  }
}
