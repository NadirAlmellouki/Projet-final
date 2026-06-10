class SessionParticipant {
  const SessionParticipant({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.trustScore,
    this.status,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final double? trustScore;
  final String? status;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : 'E';
    final l = lastName.isNotEmpty ? lastName[0] : 'T';
    return '$f$l'.toUpperCase();
  }
}
