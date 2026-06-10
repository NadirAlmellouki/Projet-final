import 'session_member_role.dart';

class StudySession {
  const StudySession({
    required this.id,
    required this.subject,
    this.topic,
    this.description,
    this.locationName,
    this.startTime,
    this.durationMinutes = 60,
    this.maxParticipants = 4,
    this.status = 'created',
    this.creatorId,
    this.creatorFirstName,
    this.creatorLastName,
    this.participantCount,
    this.matchScore,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.memberRole = SessionMemberRole.none,
  });

  final String id;
  final String subject;
  final String? topic;
  final String? description;
  final String? locationName;
  final DateTime? startTime;
  final int durationMinutes;
  final int maxParticipants;
  final String status;
  final String? creatorId;
  final String? creatorFirstName;
  final String? creatorLastName;
  final int? participantCount;
  final double? matchScore;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final SessionMemberRole memberRole;

  bool get isParticipant => memberRole.isParticipant;
  bool get isCreator => memberRole == SessionMemberRole.creator;

  StudySession copyWith({
    String? id,
    String? subject,
    String? topic,
    String? locationName,
    DateTime? startTime,
    int? durationMinutes,
    int? maxParticipants,
    String? status,
    String? creatorId,
    String? creatorFirstName,
    String? creatorLastName,
    int? participantCount,
    double? matchScore,
    double? distanceKm,
    double? latitude,
    double? longitude,
    SessionMemberRole? memberRole,
  }) {
    return StudySession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      locationName: locationName ?? this.locationName,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      creatorFirstName: creatorFirstName ?? this.creatorFirstName,
      creatorLastName: creatorLastName ?? this.creatorLastName,
      participantCount: participantCount ?? this.participantCount,
      matchScore: matchScore ?? this.matchScore,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      memberRole: memberRole ?? this.memberRole,
    );
  }

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

  bool get isEnded {
    if (status == 'completed') return true;
    if (startTime == null) return false;
    final end = startTime!.add(Duration(minutes: durationMinutes));
    return DateTime.now().isAfter(end);
  }

  bool get hasLocation => latitude != null && longitude != null;
}
