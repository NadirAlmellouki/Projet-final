import '../../application/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required ApiService api}) : _api = api;

  final ApiService _api;

  @override
  Future<User> getProfile() async {
    final response = await _api.get(ApiEndpoints.usersMe);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return UserModel.fromJson(data);
    }
    if (data is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Profil invalide');
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put(ApiEndpoints.usersMe, data: data);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return UserModel.fromJson(body);
    }
    if (body is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(body));
    }
    throw Exception('Mise à jour profil invalide');
  }
}
