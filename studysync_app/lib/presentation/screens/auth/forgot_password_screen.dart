import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    final isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (isAuthenticated) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = await ref
          .read(authProvider.notifier)
          .requestPasswordReset(_emailCtrl.text.trim());

      if (!mounted) return;

      final devLink = result.devLink;
      final warning = result.warning;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            warning != null ? 'Lien de secours' : 'Demande envoyée',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warning != null) ...[
                Text(
                  warning,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
              ] else
                Text(
                  'Si un compte existe pour ${_emailCtrl.text.trim()}, '
                  'vous recevrez un lien de réinitialisation par email '
                  '(vérifiez aussi les spams).',
                ),
              if (devLink != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Lien de réinitialisation :',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  devLink,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _goBack();
              },
              child: const Text('Retour à la connexion'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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
                  onPressed: _goBack,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Mot de passe oublié',
                        style: AppTheme.brandTitle(26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On t\'envoie un lien par email',
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
                        child: InputLabel('Ton email'),
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
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Envoyer le lien',
                        isLoading: auth.isLoading,
                        onPressed: _sendLink,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: LinkTextButton(
                          label: 'Retour à la connexion',
                          onPressed: _goBack,
                        ),
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
