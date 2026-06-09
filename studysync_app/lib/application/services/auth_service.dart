import '../../core/constants/api_endpoints.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import 'api_service.dart';

/// Service d'authentification — login, register, logout, me.
class AuthService {
  AuthService({
    required ApiService api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final ApiService _api;
  final TokenStorage _tokenStorage;

  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post(
      ApiEndpoints.authLogin,
      data: {'email': email.trim(), 'password': password},
    );
    return _saveAuth(res.data);
  }

  Future<({User user, String token})> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? university,
    String? major,
    int? year,
  }) async {
    final res = await _api.post(
      ApiEndpoints.authRegister,
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
        'password': password,
        if (university != null && university.isNotEmpty) 'university': university,
        if (major != null && major.isNotEmpty) 'major': major,
        if (year != null) 'year': year,
      },
    );
    return _saveAuth(res.data);
  }

  Future<User?> getMe() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final res = await _api.get(ApiEndpoints.authMe);
      return _parseUser(res.data);
    } catch (_) {
      await _tokenStorage.deleteToken();
      return null;
    }
  }

  Future<void> logout() => _tokenStorage.deleteToken();

  Future<({User user, String token})> signInWithGoogle(String idToken) async {
    final res = await _api.post(
      ApiEndpoints.authGoogle,
      data: {'id_token': idToken},
    );
    return _saveAuth(res.data);
  }

  Future<({String? devLink, String? warning})> requestPasswordReset(
    String email,
  ) async {
    final res = await _api.post(
      ApiEndpoints.authForgotPassword,
      data: {'email': email.trim()},
    );
    final data = res.data;
    if (data is! Map) return (devLink: null, warning: null);

    final devLink = data['dev_reset_link']?.toString();
    final warning = data['email_error']?.toString();
    final sent = data['email_sent'] == true;

    if (!sent && devLink == null && warning == null) {
      return (devLink: null, warning: null);
    }
    return (devLink: devLink, warning: warning);
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _api.post(
      ApiEndpoints.authResetPassword,
      data: {'token': token, 'password': password},
    );
  }

  Future<({User user, String token})> _saveAuth(dynamic data) async {
    if (data is! Map) throw Exception('Réponse auth invalide');
    final payload = data['data'] as Map? ?? data;
    final token = payload['token']?.toString() ?? '';
    final userJson = payload['user'] ?? payload;
    final user = UserModel.fromJson(Map<String, dynamic>.from(userJson as Map));
    await _tokenStorage.saveToken(token);
    return (user: user, token: token);
  }

  User? _parseUser(dynamic data) {
    if (data is! Map) return null;
    if (data['data'] is Map) {
      final userMap = (data['data'] as Map)['user'];
      if (userMap is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(userMap));
      }
    }
    if (data['user'] is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    }
    return null;
  }
}
