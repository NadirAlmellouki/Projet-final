class RatingSummary {
  const RatingSummary({
    required this.userId,
    required this.averageScore,
    required this.ratingsCount,
  });

  final String userId;
  final double averageScore;
  final int ratingsCount;
}
