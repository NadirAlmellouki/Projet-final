import '../entities/create_rating_request.dart';
import '../entities/rating_summary.dart';
import '../entities/session_detail.dart';

abstract class RatingRepository {
  Future<SessionDetail> getSessionDetail(String sessionId);
  Future<double?> submitRating(CreateRatingRequest request);
  Future<RatingSummary> getUserRatings(String userId);
}
