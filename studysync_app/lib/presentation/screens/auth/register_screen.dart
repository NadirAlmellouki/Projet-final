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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _acceptedTerms = false;
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
            SnackBar(content: Text(msg)),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _googleWebSub?.cancel();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acceptez les conditions d\'utilisation')),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).register(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (ok && mounted) context.go(AppRoutes.profileSetup);
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
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
                  onPressed: () => context.go(AppRoutes.intro),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text('Inscription', style: AppTheme.screenTitle()),
                      const SizedBox(height: 4),
                      Text(
                        'Créer un compte',
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const InputLabel('Prénom'),
                                TextFormField(
                                  controller: _firstNameCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    hintText: 'Votre prénom',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Requis' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const InputLabel('Nom'),
                                TextFormField(
                                  controller: _lastNameCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    hintText: 'Votre nom',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Requis' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: InputLabel('Email universitaire'),
                      ),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'votre.email@univ.ma',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email requis';
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
                          hintText: 'Minimum 8 caractères',
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Minimum 8 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: InputLabel('Confirmer le mot de passe'),
                      ),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Répétez le mot de passe',
                        ),
                        validator: (v) {
                          if (v != _passwordCtrl.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) =>
                                setState(() => _acceptedTerms = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      PrimaryButton(
                        label: 'Créer mon compte',
                        isLoading: auth.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      buildPlatformGoogleSignInButton(
                        onPressed:
                            auth.isLoading ? null : _onGoogleSignIn,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Déjà membre ? ',
                            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                          LinkTextButton(
                            label: 'Se connecter',
                            onPressed: () => context.go(AppRoutes.login),
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
