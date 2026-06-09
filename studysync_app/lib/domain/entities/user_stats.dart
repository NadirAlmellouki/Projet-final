class UserStats {
  const UserStats({
    this.sessionCount = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.trustScore,
    this.partnersCount = 0,
  });

  final int sessionCount;
  final double? averageRating;
  final int ratingCount;
  final double? trustScore;
  final int partnersCount;
}
