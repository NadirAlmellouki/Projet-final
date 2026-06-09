class CreateSessionRequest {
  const CreateSessionRequest({
    required this.subject,
    this.topic,
    this.locationName,
    required this.startTime,
    this.durationMinutes = 60,
    this.maxParticipants = 4,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  final String subject;
  final String? topic;
  final String? locationName;
  final DateTime startTime;
  final int durationMinutes;
  final int maxParticipants;
  final double latitude;
  final double longitude;
  final String? description;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        if (topic != null && topic!.isNotEmpty) 'topic': topic,
        if (locationName != null && locationName!.isNotEmpty)
          'location_name': locationName,
        'start_time': startTime.toUtc().toIso8601String(),
        'duration_minutes': durationMinutes,
        'max_participants': maxParticipants,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}
