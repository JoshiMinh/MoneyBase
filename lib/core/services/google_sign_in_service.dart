import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:moneybase/firebase_options.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();
  static const List<String> defaultScopes = <String>['email', 'profile'];

  Future<void>? _initialization;

  Future<void> ensureInitialized() {
    return _initialization ??=
        GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
  }

  GoogleSignIn get client => GoogleSignIn.instance;

  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = defaultScopes,
  }) async {
    await ensureInitialized();
    return GoogleSignIn.instance.authenticate(scopeHint: scopeHint);
  }

  Future<void> signOut() async {
    await ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }

  String? get _serverClientId {
    if (kIsWeb) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return DefaultFirebaseOptions.androidServerClientId;
    }
    return null;
  }
}

final GoogleSignInService googleSignInService = GoogleSignInService.instance;
