import 'session_participant.dart';
import 'study_session.dart';

class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.participants,
  });

  final StudySession session;
  final List<SessionParticipant> participants;
}
