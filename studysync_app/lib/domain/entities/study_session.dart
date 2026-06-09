class StudySession {
  const StudySession({
    required this.id,
    required this.subject,
    this.topic,
    this.locationName,
    this.startTime,
    this.durationMinutes = 60,
    this.maxParticipants = 4,
    this.status = 'created',
    this.creatorFirstName,
    this.creatorLastName,
    this.participantCount,
    this.matchScore,
    this.distanceKm,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String subject;
  final String? topic;
  final String? locationName;
  final DateTime? startTime;
  final int durationMinutes;
  final int maxParticipants;
  final String status;
  final String? creatorFirstName;
  final String? creatorLastName;
  final int? participantCount;
  final double? matchScore;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;

  String get creatorName {
    if (creatorFirstName != null && creatorLastName != null) {
      return '$creatorFirstName $creatorLastName';
    }
    return 'Étudiant';
  }

  String get creatorInitials {
    final f = creatorFirstName?.isNotEmpty == true ? creatorFirstName![0] : 'E';
    final l = creatorLastName?.isNotEmpty == true ? creatorLastName![0] : 'T';
    return '$f$l'.toUpperCase();
  }

  bool get isActiveNow {
    if (startTime == null) return false;
    final now = DateTime.now();
    final end = startTime!.add(Duration(minutes: durationMinutes));
    return now.isAfter(startTime!) && now.isBefore(end);
  }

  bool get hasLocation => latitude != null && longitude != null;
}
