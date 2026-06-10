/// Raisons de signalement acceptées par POST /api/reports.
class ReportReasons {
  ReportReasons._();

  static const values = [
    ReportReason(value: 'harassment', label: 'Harcèlement'),
    ReportReason(value: 'spam', label: 'Spam'),
    ReportReason(value: 'fake_profile', label: 'Faux profil'),
    ReportReason(value: 'safety', label: 'Problème de sécurité'),
    ReportReason(value: 'other', label: 'Autre'),
  ];
}

class ReportReason {
  const ReportReason({required this.value, required this.label});

  final String value;
  final String label;
}
