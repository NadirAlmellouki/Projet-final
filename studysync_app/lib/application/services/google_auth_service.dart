import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';

/// Connexion Google — sur le Web utilise GIS (idToken), pas signIn() + People API.
class GoogleAuthService {
  GoogleSignIn? _client;

  GoogleSignIn get client {
    final clientId = AppConfig.googleClientId;
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'Google non configuré. Lancez avec --dart-define=GOOGLE_CLIENT_ID=...',
      );
    }
    return _client ??= GoogleSignIn(
      clientId: clientId,
      scopes: const ['email', 'openid'],
    );
  }

  /// One Tap au chargement (Web uniquement).
  void warmUpWebSignIn() {
    if (!kIsWeb) return;
    client.signInSilently();
  }

  /// Écoute les connexions via le bouton Google Web (renderButton / One Tap).
  StreamSubscription<GoogleSignInAccount?> listenWebSignIn({
    required Future<void> Function(String idToken) onIdToken,
    void Function(String message)? onError,
  }) {
    warmUpWebSignIn();
    return client.onCurrentUserChanged.listen((account) async {
      if (account == null) return;
      try {
        final idToken = await idTokenFromAccount(account);
        await onIdToken(idToken);
      } catch (e) {
        onError?.call(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    });
  }

  Future<String> idTokenFromAccount(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Token Google manquant. Sur le Web, cliquez sur le bouton Google affiché.',
      );
    }
    return idToken;
  }

  /// Android / iOS / desktop — popup classique.
  Future<String?> signInAndGetIdToken() async {
    if (kIsWeb) {
      throw Exception(
        'Sur Chrome, utilisez le bouton « Continuer avec Google » affiché.',
      );
    }

    final account = await client.signIn();
    if (account == null) return null;
    return idTokenFromAccount(account);
  }
}
