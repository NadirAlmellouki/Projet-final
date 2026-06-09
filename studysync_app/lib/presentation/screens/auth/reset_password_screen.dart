import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien invalide : token manquant')),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).resetPassword(
          widget.token,
          _passwordCtrl.text,
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour')),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (widget.token.isEmpty) {
      return AuthScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AuthFormCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lien invalide ou expiré',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Demandez un nouveau lien depuis la page '
                    '« Mot de passe oublié ».',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Mot de passe oublié',
                    onPressed: () => context.go(AppRoutes.forgotPassword),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.token.isEmpty) {
      return AuthScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AuthFormCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lien invalide ou expiré',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Demandez un nouveau lien depuis la page '
                    '« Mot de passe oublié ».',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Mot de passe oublié',
                    onPressed: () => context.go(AppRoutes.forgotPassword),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AuthScaffold(
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Nouveau mot de passe',
                    style: AppTheme.brandTitle(26),
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
                        child: InputLabel('Nouveau mot de passe'),
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
                        child: InputLabel('Confirmer'),
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
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Enregistrer',
                        isLoading: auth.isLoading,
                        onPressed: _submit,
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
