import 'package:flutter/material.dart';

import 'common_widgets.dart';

/// Bouton Google classique (mobile / desktop).
Widget buildPlatformGoogleSignInButton({VoidCallback? onPressed}) {
  return GhostButton(
    label: 'Continuer avec Google',
    onPressed: onPressed,
  );
}
