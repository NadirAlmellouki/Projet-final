import 'package:flutter/material.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart' as impl;

/// Bouton Google adapté à la plateforme (GIS sur Web, GhostButton ailleurs).
Widget buildPlatformGoogleSignInButton({VoidCallback? onPressed}) {
  return impl.buildPlatformGoogleSignInButton(onPressed: onPressed);
}
