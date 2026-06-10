import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/studysync_widgets.dart';

class RatingScreen extends StatelessWidget {
  const RatingScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  final String sessionId;
  final String sessionTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(sessionTitle),
      ),
      body: EmptyState(
        icon: Icons.star_rounded,
        title: 'Noter la session',
        message:
            'La notation des participants sera disponible une fois la session terminée.',
        action: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour'),
        ),
      ),
    );
  }
}
