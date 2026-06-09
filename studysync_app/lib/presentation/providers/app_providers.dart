import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/api_service.dart';
import '../../application/services/auth_service.dart';
import '../../application/services/google_auth_service.dart';
import '../../core/storage/token_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(tokenStorage: ref.watch(tokenStorageProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    api: ref.watch(apiServiceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(authService: ref.watch(authServiceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(api: ref.watch(apiServiceProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(api: ref.watch(apiServiceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(api: ref.watch(apiServiceProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepositoryImpl(api: ref.watch(apiServiceProvider));
});
