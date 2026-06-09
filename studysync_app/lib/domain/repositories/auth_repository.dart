import '../entities/user.dart';

abstract class AuthRepository {
  Future<({User user, String token})> login({
    required String email,
    required String password,
  });

  Future<({User user, String token})> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? university,
    String? major,
    int? year,
  });

  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<({User user, String token})> signInWithGoogle(String idToken);
  Future<({String? devLink, String? warning})> requestPasswordReset(
    String email,
  );
  Future<void> resetPassword({required String token, required String password});
}

abstract class UserRepository {
  Future<User> getProfile();
  Future<User> updateProfile(Map<String, dynamic> data);
}
