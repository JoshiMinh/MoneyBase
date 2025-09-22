import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();
  static const List<String> defaultScopes = <String>[
    'email',
    'profile',
  ];

  Future<void>? _initialization;

  Future<void> ensureInitialized() {
    return _initialization ??=
        GoogleSignIn.instance.initialize(scopes: defaultScopes);
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
}

final GoogleSignInService googleSignInService = GoogleSignInService.instance;
