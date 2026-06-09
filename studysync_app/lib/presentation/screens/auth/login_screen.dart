import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  StreamSubscription? _googleWebSub;
  bool _googleHandling = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleWebSub = ref.read(googleAuthServiceProvider).listenWebSignIn(
        onIdToken: _completeGoogleSignIn,
        onError: (msg) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _googleWebSub?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;

    if (ok) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _completeGoogleSignIn(String idToken) async {
    if (_googleHandling || !mounted) return;
    _googleHandling = true;
    try {
      final ok = await ref.read(authProvider.notifier).signInWithGoogle(idToken);
      if (!mounted) return;

      if (ok) {
        final user = ref.read(authProvider).user;
        if (user?.needsProfileSetup == true) {
          context.go(AppRoutes.profileSetup);
        } else {
          context.go(AppRoutes.home);
        }
      } else {
        final msg = ref.read(authProvider).errorMessage;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } finally {
      _googleHandling = false;
    }
  }

  Future<void> _onGoogleSignIn() async {
    try {
      final idToken =
          await ref.read(googleAuthServiceProvider).signInAndGetIdToken();
      if (idToken == null || !mounted) return;
      await _completeGoogleSignIn(idToken);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return AuthScaffold(
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GhostButton(
                  label: '← Retour',
                  light: true,
                  onPressed: () => context.go(AppRoutes.onboarding),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text('Connexion', style: AppTheme.screenTitle()),
                      const SizedBox(height: 4),
                      Text(
                        'Content de te revoir',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AuthFormCard(
                  child: Column(
                    children: [
                      if (auth.errorMessage != null)
                        ErrorBanner(message: auth.errorMessage!),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: InputLabel('Email universitaire'),
                      ),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          hintText: 'votre.email@univ.ma',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email requis';
                          }
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: InputLabel('Mot de passe'),
                      ),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Votre mot de passe',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Mot de passe requis' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: LinkTextButton(
                          label: 'Mot de passe oublié ?',
                          onPressed: () => context.push(AppRoutes.forgotPassword),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: 'Se connecter',
                        isLoading: auth.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'ou',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      buildPlatformGoogleSignInButton(
                        onPressed:
                            auth.isLoading ? null : _onGoogleSignIn,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Pas encore de compte ? ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                          LinkTextButton(
                            label: 'S\'inscrire',
                            onPressed: () => context.go(AppRoutes.intro),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
