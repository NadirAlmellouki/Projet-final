import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';

class RatingDialog extends ConsumerStatefulWidget {
  const RatingDialog({
    super.key,
    required this.sessionId,
    required this.rateeId,
    required this.rateeName,
  });

  final String sessionId;
  final String rateeId;
  final String rateeName;

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  int _score = 0;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_score == 0) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await ref.read(sessionRepositoryProvider).submitRating(
            sessionId: widget.sessionId,
            rateeId: widget.rateeId,
            score: _score,
            comment: _commentCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Noter ${widget.rateeName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFF991B1B), fontSize: 12)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _score;
              return IconButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _score = i + 1),
                icon: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: filled ? AppColors.warning : AppColors.text3,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              hintText: 'Commentaire optionnel...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _score == 0 || _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}
