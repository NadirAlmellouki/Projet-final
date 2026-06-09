import '../../application/services/auth_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;

  @override
  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) =>
      _authService.login(email: email, password: password);

  @override
  Future<({User user, String token})> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? university,
    String? major,
    int? year,
  }) =>
      _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        university: university,
        major: major,
        year: year,
      );

  @override
  Future<User?> getCurrentUser() => _authService.getMe();

  @override
  Future<void> logout() => _authService.logout();

  @override
  Future<({User user, String token})> signInWithGoogle(String idToken) =>
      _authService.signInWithGoogle(idToken);

  @override
  Future<({String? devLink, String? warning})> requestPasswordReset(
    String email,
  ) =>
      _authService.requestPasswordReset(email);

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) =>
      _authService.resetPassword(token: token, password: password);
}
