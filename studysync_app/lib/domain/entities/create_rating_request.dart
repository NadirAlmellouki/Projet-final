class CreateRatingRequest {
  const CreateRatingRequest({
    required this.sessionId,
    required this.ratedId,
    required this.score,
    this.punctualityScore,
    this.engagementScore,
    this.wouldStudyAgain,
    this.comment,
  });

  final String sessionId;
  final String ratedId;
  final int score;
  final int? punctualityScore;
  final int? engagementScore;
  final bool? wouldStudyAgain;
  final String? comment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'session_id': sessionId,
      'rated_id': ratedId,
      'score': score,
    };
    if (punctualityScore != null) {
      map['punctuality_score'] = punctualityScore;
    }
    if (engagementScore != null) {
      map['engagement_score'] = engagementScore;
    }
    if (wouldStudyAgain != null) {
      map['would_study_again'] = wouldStudyAgain;
    }
    if (comment != null && comment!.trim().isNotEmpty) {
      map['comment'] = comment!.trim();
    }
    return map;
  }
}
