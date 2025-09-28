import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../common/presentation/moneybase_shell.dart';
import '../../../core/services/google_sign_in_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      maxContentWidth: 1200,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
      builder: (context, layout) {
        final authCard = _AuthCard(
          onLoginSuccess: onLoginSuccess,
          isWide: layout.isWide,
        );

        if (layout.isWide) {
          return Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 32),
                  child: _AuthMarketingPanel(),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: authCard,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.topCenter, child: authCard),
            const SizedBox(height: 24),
            const _AuthMarketingPanel(compact: true),
          ],
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
  bool _keepSignedIn = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _applyPersistence(_keepSignedIn);
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
    final secondaryTextColor = baseTextColor.withOpacity(0.8);
    final mutedTextColor = baseTextColor.withOpacity(0.7);

    return MoneyBaseFrostedPanel(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isWide ? 48 : 32,
        vertical: widget.isWide ? 48 : 36,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 36,
          offset: Offset(0, 28),
        ),
      ],
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer
                      .withOpacity(0.6),
                  child: ClipOval(
                    child: Image.asset(
                      'app_icon.ico',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: baseTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to sync your budgets and keep your spending on track across Android and the web.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            _ThirdPartyButton(
              label: 'Continue with Google',
              icon: Icons.account_circle,
              onPressed: _isLoading ? null : _signInWithGoogle,
            ),
            const SizedBox(height: 20),
            const _DividerWithText(text: 'or continue with email'),
            const SizedBox(height: 20),
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
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _keepSignedIn,
                  onChanged: _isLoading ? null : _togglePersistence,
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keep me signed in',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _sendPasswordReset,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoading ? null : _registerWithEmail,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: baseTextColor.withOpacity(0.3)),
                foregroundColor: baseTextColor,
              ),
              child: const Text('Create a MoneyBase account'),
            ),
            const SizedBox(height: 24),
            Text(
              'By continuing you agree to the MoneyBase Terms of Service and acknowledge our Privacy Policy.',
              style: theme.textTheme.bodySmall?.copyWith(color: mutedTextColor),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _togglePersistence(bool? value) async {
    if (value == null) return;
    setState(() => _keepSignedIn = value);
    await _applyPersistence(value);
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

class _AuthMarketingPanel extends StatelessWidget {
  const _AuthMarketingPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final primaryTextColor = isLightMode ? Colors.black : Colors.white;
    final secondaryTextColor = primaryTextColor.withOpacity(0.85);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 28)
        : const EdgeInsets.symmetric(horizontal: 48, vertical: 64);
    final borderRadius = compact ? 28.0 : 32.0;
    final bulletSpacing = compact ? 16.0 : 20.0;
    const bullets = [
      _MarketingBullet(
        icon: Icons.auto_graph_outlined,
        text: 'Visualize spending trends with live-updating charts.',
      ),
      _MarketingBullet(
        icon: Icons.verified_user_outlined,
        text: 'Enterprise-grade security powered by Firebase Auth.',
      ),
      _MarketingBullet(
        icon: Icons.devices_other_outlined,
        text: 'Optimized layouts tailored to desktop, tablet, and mobile.',
      ),
      _MarketingBullet(
        icon: Icons.smart_toy_outlined,
        text: 'AI budgeting assistance to answer finance questions fast.',
      ),
    ];

    return MoneyBaseFrostedPanel(
      padding: padding,
      borderRadius: borderRadius,
      backgroundOpacity: 0.12,
      borderOpacity: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MoneyBase',
            style: theme.textTheme.displaySmall?.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All-new everywhere access.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Plan budgets, review reports, and reconcile your accounts seamlessly between web and Android with a refreshed design.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < bullets.length; i++) ...[
            bullets[i],
            if (i != bullets.length - 1) SizedBox(height: bulletSpacing),
          ],
        ],
      ),
    );
  }
}

class _MarketingBullet extends StatelessWidget {
  const _MarketingBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final iconColor = isLightMode ? Colors.black87 : Colors.white;
    final textColor = (isLightMode ? Colors.black : Colors.white).withOpacity(
      0.85,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThirdPartyButton extends StatelessWidget {
  const _ThirdPartyButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final foregroundColor = isLightMode ? Colors.black : Colors.white;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: foregroundColor.withOpacity(0.3)),
        foregroundColor: foregroundColor,
        textStyle: theme.textTheme.titleMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
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
