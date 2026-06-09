import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'app_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authRepo, this._tokenStorage) : super(const AuthState());

  final AuthRepository _authRepo;
  final TokenStorage _tokenStorage;

  Future<void> checkAuthOnStartup() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _tokenStorage
          .readToken()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      if (JwtDecoder.isExpired(token)) {
        await _authRepo.logout();
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _authRepo
          .getCurrentUser()
          .timeout(const Duration(seconds: 3));
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void markUnauthenticated() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepo.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void setUser(User user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> signInWithGoogle(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepo.signInWithGoogle(idToken);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<({String? devLink, String? warning})> requestPasswordReset(
    String email,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepo.requestPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<bool> resetPassword(String token, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepo.resetPassword(token: token, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});
