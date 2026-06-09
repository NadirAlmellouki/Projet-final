import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Bouton Google Identity Services (obligatoire sur le Web pour obtenir un idToken).
Widget buildPlatformGoogleSignInButton({VoidCallback? onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: web.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        minimumWidth: 400,
      ),
    ),
  );
}
