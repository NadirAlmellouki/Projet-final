import '../../domain/entities/session_participant.dart';

class SessionParticipantModel extends SessionParticipant {
  const SessionParticipantModel({
    required super.userId,
    required super.firstName,
    required super.lastName,
    super.trustScore,
    super.status,
  });

  factory SessionParticipantModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : json;

    return SessionParticipantModel(
      userId: (userMap['id'] ?? json['user_id'])?.toString() ?? '',
      firstName: userMap['first_name']?.toString() ?? '',
      lastName: userMap['last_name']?.toString() ?? '',
      trustScore: double.tryParse('${userMap['trust_score']}'),
      status: json['status']?.toString(),
    );
  }
}
