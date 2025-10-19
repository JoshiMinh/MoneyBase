import 'dart:ui';

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
      maxContentWidth: 1100,
      widePadding: const EdgeInsets.symmetric(horizontal: 72, vertical: 72),
      narrowPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      builder: (context, layout) {
        final colors = context.moneyBaseColors;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _AuthBackdropOrb(
              top: layout.isWide ? -160 : -120,
              right: layout.isWide ? -80 : -32,
              size: layout.isWide ? 360 : 260,
              color: colors.secondaryAccent.withOpacity(0.28),
            ),
            _AuthBackdropOrb(
              top: layout.isWide ? 260 : 320,
              left: -72,
              size: layout.isWide ? 300 : 240,
              color: colors.primaryAccent.withOpacity(0.24),
            ),
            _AuthBackdropOrb(
              bottom: layout.isWide ? -160 : -140,
              right: -46,
              size: layout.isWide ? 420 : 280,
              color: colors.tertiaryAccent.withOpacity(0.22),
            ),
            _AuthBody(
              isWide: layout.isWide,
              onLoginSuccess: onLoginSuccess,
            ),
          ],
        );
      },
    );
  }
}

class _AuthBody extends StatelessWidget {
  const _AuthBody({
    required this.isWide,
    required this.onLoginSuccess,
  });

  final bool isWide;
  final VoidCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    final hero = _AuthHeroPanel(isWide: isWide);
    final authCard = _AuthCard(
      onLoginSuccess: onLoginSuccess,
      isWide: isWide,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: hero),
          const SizedBox(width: 48),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: authCard,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hero,
        const SizedBox(height: 32),
        authCard,
      ],
    );
  }
}

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final textTheme = theme.textTheme;
    final isLightMode = theme.brightness == Brightness.light;

    return MoneyBaseFrostedPanel(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 28,
        vertical: isWide ? 52 : 34,
      ),
      borderRadius: isWide ? 44 : 32,
      backgroundOpacity: isLightMode ? 0.18 : 0.28,
      borderOpacity: isLightMode ? 0.18 : 0.3,
      boxShadow: [
        BoxShadow(
          color: colors.surfaceShadow.withOpacity(isLightMode ? 0.28 : 0.45),
          blurRadius: 64,
          offset: const Offset(0, 40),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primaryAccent.withOpacity(0.9),
                      colors.secondaryAccent.withOpacity(0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoneyBase account',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in without losing the calm.',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isWide)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colors.primaryAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: colors.primaryAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SSO & MFA ready',
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'MoneyBase keeps budgets, automations, and shared workspaces consistent from phone to desktop. Sign in once and everything stays in sync.',
            style: textTheme.titleMedium?.copyWith(
              color: colors.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _AuthHeroHighlight(
                icon: Icons.auto_graph_rounded,
                title: 'Clarity at a glance',
                subtitle: 'Net worth, cash flow, and savings goals stay updated in real time.',
                maxWidth: isWide ? 280 : double.infinity,
              ),
              _AuthHeroHighlight(
                icon: Icons.bolt_rounded,
                title: 'Automate the routine',
                subtitle: 'Custom rules clean transactions and track what matters to you.',
                maxWidth: isWide ? 280 : double.infinity,
              ),
              _AuthHeroHighlight(
                icon: Icons.group_rounded,
                title: 'Share responsibly',
                subtitle: 'Invite partners with granular permissions and activity trails.',
                maxWidth: isWide ? 280 : double.infinity,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthHeroHighlight extends StatelessWidget {
  const _AuthHeroHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.maxWidth,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final isLightMode = theme.brightness == Brightness.light;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryAccent.withOpacity(isLightMode ? 0.2 : 0.28),
              colors.secondaryAccent.withOpacity(isLightMode ? 0.14 : 0.22),
            ],
          ),
          border: Border.all(
            color: colors.primaryAccent.withOpacity(isLightMode ? 0.28 : 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primaryAccent.withOpacity(0.12),
              blurRadius: 34,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isLightMode ? 0.28 : 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: colors.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final colors = context.moneyBaseColors;
    final isLightMode = theme.brightness == Brightness.light;
    final baseTextColor = colors.primaryText;
    final secondaryTextColor = colors.mutedText;
    final mutedTextColor = colors.mutedText.withOpacity(isLightMode ? 0.8 : 0.7);
    final accentColor = colors.primaryAccent;

    return MoneyBaseFrostedPanel(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isWide ? 40 : 28,
        vertical: widget.isWide ? 44 : 34,
      ),
      borderRadius: widget.isWide ? 36 : 28,
      backgroundOpacity: isLightMode ? 0.16 : 0.26,
      borderOpacity: isLightMode ? 0.18 : 0.3,
      boxShadow: [
        BoxShadow(
          color: colors.surfaceShadow.withOpacity(isLightMode ? 0.28 : 0.45),
          blurRadius: 48,
          offset: const Offset(0, 28),
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primaryAccent.withOpacity(0.85),
                        colors.secondaryAccent.withOpacity(0.78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in to MoneyBase',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: baseTextColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bring your budgets, automations, and shared spaces with you.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _AuthFeaturePill(
                  icon: Icons.fingerprint_rounded,
                  label: 'Biometric ready',
                ),
                _AuthFeaturePill(
                  icon: Icons.notifications_active_outlined,
                  label: 'Smart alerts',
                ),
                _AuthFeaturePill(
                  icon: Icons.shield_outlined,
                  label: 'Bank-grade security',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.negative.withOpacity(isLightMode ? 0.12 : 0.22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.negative.withOpacity(isLightMode ? 0.32 : 0.4),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.negative,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (_isLoading) ...[
              LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: colors.surfaceBorder.withOpacity(0.4),
              ),
              const SizedBox(height: 20),
            ],
            _ThirdPartyButton(
              label: 'Continue with Google',
              icon: Icons.g_translate,
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
            const SizedBox(height: 14),
            Row(
              children: [
                Checkbox(
                  value: _keepSignedIn,
                  onChanged: _isLoading ? null : _togglePersistence,
                  activeColor: accentColor,
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
                minimumSize: const Size.fromHeight(54),
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
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
                minimumSize: const Size.fromHeight(54),
                side: BorderSide(color: colors.surfaceBorder.withOpacity(0.6)),
                foregroundColor: baseTextColor,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Create a MoneyBase account'),
            ),
            const SizedBox(height: 20),
            const _AuthAssuranceBanner(),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(color: mutedTextColor),
                children: [
                  const TextSpan(
                    text:
                        'By continuing you agree to the MoneyBase ',
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and acknowledge our '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
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

class _AuthFeaturePill extends StatelessWidget {
  const _AuthFeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final isLightMode = theme.brightness == Brightness.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryAccent.withOpacity(isLightMode ? 0.18 : 0.28),
            colors.secondaryAccent.withOpacity(isLightMode ? 0.12 : 0.22),
          ],
        ),
        border: Border.all(
          color: colors.primaryAccent.withOpacity(isLightMode ? 0.26 : 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.primaryAccent),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthAssuranceBanner extends StatelessWidget {
  const _AuthAssuranceBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final isLightMode = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colors.surfaceBackground.withOpacity(isLightMode ? 0.7 : 0.32),
        border: Border.all(
          color: colors.primaryAccent.withOpacity(isLightMode ? 0.28 : 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, color: colors.primaryAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data stays encrypted',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MoneyBase uses secure Firebase authentication, optional multi-factor protection, and read-only financial connections.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdropOrb extends StatelessWidget {
  const _AuthBackdropOrb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: true,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
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
    final colors = context.moneyBaseColors;
    final isLightMode = theme.brightness == Brightness.light;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor:
            colors.surfaceBackground.withOpacity(isLightMode ? 0.86 : 0.28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: colors.surfaceBorder.withOpacity(isLightMode ? 0.5 : 0.6),
        ),
        foregroundColor: colors.primaryText,
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.primaryAccent),
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
