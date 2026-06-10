class CreateReportRequest {
  const CreateReportRequest({
    required this.reason,
    this.description,
    this.reportedUserId,
    this.reportedSessionId,
    this.reportedMessageId,
  });

  final String reason;
  final String? description;
  final String? reportedUserId;
  final String? reportedSessionId;
  final String? reportedMessageId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'reason': reason};
    if (description != null && description!.trim().isNotEmpty) {
      map['description'] = description!.trim();
    }
    if (reportedUserId != null) map['reported_user_id'] = reportedUserId;
    if (reportedSessionId != null) {
      map['reported_session_id'] = reportedSessionId;
    }
    if (reportedMessageId != null) {
      map['reported_message_id'] = reportedMessageId;
    }
    return map;
  }

  bool get hasTarget =>
      reportedUserId != null ||
      reportedSessionId != null ||
      reportedMessageId != null;
}
