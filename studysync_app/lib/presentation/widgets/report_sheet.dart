import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/report_reasons.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/create_report_request.dart';
import '../providers/app_providers.dart';

enum ReportTargetType { user, session, message }

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({
    super.key,
    required this.targetType,
    required this.targetLabel,
    this.reportedUserId,
    this.reportedSessionId,
    this.reportedMessageId,
  });

  final ReportTargetType targetType;
  final String targetLabel;
  final String? reportedUserId;
  final String? reportedSessionId;
  final String? reportedMessageId;

  static Future<bool?> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetLabel,
    String? reportedUserId,
    String? reportedSessionId,
    String? reportedMessageId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ReportSheet(
          targetType: targetType,
          targetLabel: targetLabel,
          reportedUserId: reportedUserId,
          reportedSessionId: reportedSessionId,
          reportedMessageId: reportedMessageId,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  String _reason = ReportReasons.values.first.value;
  final _descriptionCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String get _title => switch (widget.targetType) {
        ReportTargetType.user => 'Signaler un utilisateur',
        ReportTargetType.session => 'Signaler une session',
        ReportTargetType.message => 'Signaler un message',
      };

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(reportRepositoryProvider).createReport(
            CreateReportRequest(
              reason: _reason,
              description: _descriptionCtrl.text,
              reportedUserId: widget.reportedUserId,
              reportedSessionId: widget.reportedSessionId,
              reportedMessageId: widget.reportedMessageId,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.targetLabel,
              style: const TextStyle(fontSize: 13, color: AppColors.text2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Motif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items: ReportReasons.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r.value,
                      child: Text(r.label),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (v) {
                      if (v != null) setState(() => _reason = v);
                    },
            ),
            const SizedBox(height: 12),
            const Text(
              'Description (optionnel)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: 'Décrivez le problème…',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Envoyer le signalement'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
