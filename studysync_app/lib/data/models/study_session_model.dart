import '../../domain/entities/study_session.dart';

class StudySessionModel extends StudySession {
  const StudySessionModel({
    required super.id,
    required super.subject,
    super.topic,
    super.description,
    super.locationName,
    super.startTime,
    super.durationMinutes,
    super.maxParticipants,
    super.status,
    super.creatorId,
    super.creatorFirstName,
    super.creatorLastName,
    super.participantCount,
    super.matchScore,
    super.distanceKm,
    super.latitude,
    super.longitude,
    super.memberRole,
  });

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedStart;
    final rawStart = json['start_time'];
    if (rawStart != null) {
      parsedStart = DateTime.tryParse(rawStart.toString());
    }

    double? parseDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    int? parseInt(dynamic v) =>
        v == null ? null : int.tryParse(v.toString());

    var lat = parseDouble(json['latitude']);
    var lng = parseDouble(json['longitude']);
    if (lat == null || lng == null) {
      final loc = json['location'];
      if (loc is Map) {
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = parseDouble(coords[0]);
          lat = parseDouble(coords[1]);
        }
      }
    }

    final creator = json['creator'];
    final creatorMap = creator is Map ? Map<String, dynamic>.from(creator) : null;

    return StudySessionModel(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'Session',
      topic: json['topic']?.toString(),
      description: json['description']?.toString(),
      locationName: json['location_name']?.toString(),
      startTime: parsedStart,
      durationMinutes: parseInt(json['duration_minutes']) ?? 60,
      maxParticipants: parseInt(json['max_participants']) ?? 4,
      status: json['status']?.toString() ?? 'created',
      creatorId: json['creator_id']?.toString() ?? creatorMap?['id']?.toString(),
      creatorFirstName: json['creator_first_name']?.toString() ??
          creatorMap?['first_name']?.toString(),
      creatorLastName: json['creator_last_name']?.toString() ??
          creatorMap?['last_name']?.toString(),
      participantCount: parseInt(json['participant_count']),
      matchScore: parseDouble(json['match_score']),
      distanceKm: parseDouble(json['distance_km']),
      latitude: lat,
      longitude: lng,
    );
  }
}
