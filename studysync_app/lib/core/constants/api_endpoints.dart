/// Endpoints REST du backend StudySync.
class ApiEndpoints {
  ApiEndpoints._();

  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authGoogle = '/api/auth/google';
  static const authForgotPassword = '/api/auth/forgot-password';
  static const authResetPassword = '/api/auth/reset-password';
  static const authMe = '/api/auth/me';
  static const usersMe = '/api/users/me';

  static const sessions = '/api/sessions';
  static const sessionsMine = '/api/sessions/mine';
  static String sessionMessages(String id) => '/api/sessions/$id/messages';
  static String sessionJoin(String id) => '/api/sessions/$id/join';
  static String sessionById(String id) => '/api/sessions/$id';

  static const matchesRecommend = '/api/matches/recommend';
  static const matchesNearby = '/api/matches/nearby-sessions';
  static const matchesHeatmap = '/api/matches/heatmap';

  static String userRatings(String userId) => '/api/ratings/user/$userId';
  static const health = '/api/health';
}
