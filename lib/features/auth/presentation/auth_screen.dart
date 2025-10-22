import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../common/presentation/moneybase_shell.dart';
import '../../../app/theme/theme.dart';
import '../../../core/services/google_sign_in_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      maxContentWidth: 1080,
      widePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
      narrowPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      builder: (context, layout) {
        final size = MediaQuery.sizeOf(context);
        final verticalPadding = layout.contentPadding.vertical;
        final minHeight = (size.height - verticalPadding).clamp(0.0, double.infinity);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              minHeight: minHeight,
            ),
            child: _AuthCard(
              onLoginSuccess: onLoginSuccess,
              isWide: layout.isWide,
            ),
          ),
        );
      },
    );
  }
}


class _AuthCard extends StatefulWidget {
  const _AuthCard({required this.onLoginSuccess, required this.isWide});

  final VoidCallback? onLoginSuccess;
  final bool isWide;

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _applyPersistence(true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final baseTextColor = isLightMode ? Colors.black : Colors.white;
    final colors = context.moneyBaseColors;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSpacing = (screenHeight * 0.3) - 140;
    final resolvedTopSpacing = topSpacing.isFinite
        ? topSpacing.clamp(24.0, screenHeight * 0.22)
        : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isWide ? 16 : 8,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: resolvedTopSpacing),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MoneyBase',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: baseTextColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.04),
            Text(
              'Start tracking your finance!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: baseTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Log in to access your budgets, reports, and shared spaces.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (_isLoading) ...[
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(12),
                minHeight: 6,
                backgroundColor: baseTextColor.withOpacity(0.15),
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _emailController,
              enabled: !_isLoading,
              decoration: const InputDecoration(labelText: 'Email address'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: _togglePasswordVisibility,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              validator: _validatePassword,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    )
                  : const Text('Log In'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _registerWithEmail,
                  child: const Text('Sign Up'),
                ),
                const SizedBox(width: 12),
                Text(
                  '·',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isLoading ? null : _sendPasswordReset,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _DividerWithText(text: 'or'),
            const SizedBox(height: 24),
            _ThirdPartyButton(
              label: 'Continue with Google',
              assetPath: 'assets/images/google.png',
              onPressed: _isLoading ? null : _signInWithGoogle,
            ),
            SizedBox(height: screenHeight * 0.08),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'MoneyBase 2025 copyright',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.mutedText,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await _runAuthFlow(() async {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _syncUserProfile(credential.user);
    });
  }

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await _runAuthFlow(() async {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      await _syncUserProfile(credential.user, creating: true);
    });
  }

  Future<void> _signInWithGoogle() async {
    await _runAuthFlow(() async {
      UserCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        try {
          credential = await FirebaseAuth.instance.signInWithPopup(provider);
        } on FirebaseAuthException catch (error) {
          if (_isCoopWindowClosedError(error)) {
            await FirebaseAuth.instance.signInWithRedirect(provider);
            throw const _AuthRedirectException();
          }
          rethrow;
        }
      } else {
        final account = await googleSignInService.authenticate(
          scopeHint: GoogleSignInService.defaultScopes,
        );
        final authentication = account.authentication;
        final idToken = authentication.idToken;
        if (idToken == null) {
          throw FirebaseAuthException(
            code: 'missing-google-id-token',
            message: 'Google sign-in did not return a valid ID token.',
          );
        }
        final authorization = await account.authorizationClient.authorizeScopes(
          GoogleSignInService.defaultScopes,
        );
        final authCredential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: idToken,
        );
        credential = await FirebaseAuth.instance.signInWithCredential(
          authCredential,
        );
      }
      await _syncUserProfile(credential.user);
    });
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      _setErrorMessage(
        'Enter the email associated with your account to reset your password.',
      );
      return;
    }
    await _runAuthFlow(() async {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent. Check your inbox.'),
          ),
        );
      }
    }, suppressDefaultCompletion: true);
  }

  Future<void> _runAuthFlow(
    Future<void> Function() operation, {
    bool suppressDefaultCompletion = false,
  }) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await operation();
      if (!suppressDefaultCompletion) {
        widget.onLoginSuccess?.call();
      }
    } on _AuthRedirectException {
      return;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      _setErrorMessage(error.description ?? 'Google sign-in failed.');
    } on FirebaseAuthException catch (error) {
      _handleFirebaseAuthError(error);
    } catch (error) {
      _setErrorMessage('Unexpected error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        _setErrorMessage('Incorrect email or password. Please try again.');
        break;
      case 'email-already-in-use':
        _setErrorMessage(
          'An account already exists for ${_emailController.text.trim()}.',
        );
        break;
      case 'weak-password':
        _setErrorMessage(
          'Choose a stronger password with at least 6 characters.',
        );
        break;
      case 'user-disabled':
        _setErrorMessage('This account has been disabled. Contact support.');
        break;
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        // User dismissed the popup; ignore.
        break;
      default:
        _setErrorMessage(error.message ?? 'Authentication failed.');
    }
  }

  void _setErrorMessage(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _syncUserProfile(User? user, {bool creating = false}) async {
    if (user == null) return;

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userData = {
      'displayName': user.displayName ?? '',
      'email': user.email,
      'photoUrl': user.photoURL,
      'profilePictureUrl': user.photoURL,
    };

    final timestamp = FieldValue.serverTimestamp();
    final snapshot = await doc.get();
    if (snapshot.exists) {
      await doc.update({...userData, 'lastLoginAt': timestamp});
    } else {
      await doc.set({
        ...userData,
        'createdAt': timestamp,
        'lastLoginAt': timestamp,
        'premium': false,
      });
    }

    if (creating && user.displayName == null) {
      await user.updateDisplayName(user.email?.split('@').first);
    }
  }

  Future<void> _applyPersistence(bool value) async {
    if (!kIsWeb) return;
    try {
      await FirebaseAuth.instance.setPersistence(
        value ? Persistence.LOCAL : Persistence.SESSION,
      );
    } catch (_) {
      // Ignored. Persistence is only configurable on the web target.
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address.';
    }
    if (!_isValidEmail(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  bool _isValidEmail(String value) {
    final atParts = value.split('@');
    if (atParts.length != 2) {
      return false;
    }
    final localPart = atParts.first.trim();
    final domainPart = atParts.last.trim();
    if (localPart.isEmpty || domainPart.isEmpty) {
      return false;
    }
    return domainPart.contains('.') && !domainPart.endsWith('.');
  }
}

class _ThirdPartyButton extends StatelessWidget {
  const _ThirdPartyButton({
    required this.label,
    required this.assetPath,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final backgroundColor = Colors.black.withOpacity(isLightMode ? 0.85 : 0.9);

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        textStyle: theme.textTheme.titleMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetPath,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Text(label),
        ],
      ),
    );
  }
}

class _AuthRedirectException implements Exception {
  const _AuthRedirectException();
}

bool _isCoopWindowClosedError(FirebaseAuthException error) {
  if (error.code != 'internal-error') {
    return false;
  }
  final message = error.message?.toLowerCase() ?? '';
  if (!message.contains('window.closed')) {
    return false;
  }
  return message.contains('cross-origin-opener-policy');
}

class _DividerWithText extends StatelessWidget {
  const _DividerWithText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}
