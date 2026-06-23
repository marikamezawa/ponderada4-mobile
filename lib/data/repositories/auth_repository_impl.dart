import 'dart:async';
import '../../core/auth_state.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalAuthDatasource _datasource;
  final _controller = StreamController<UserProfile?>.broadcast();

  AuthRepositoryImpl(this._datasource);

  @override
  Future<UserProfile> login(String email, String password) async {
    final user = await _datasource.login(email, password);
    authState.value = true;
    _controller.add(user);
    return user;
  }

  @override
  Future<UserProfile> register(
      String name, String email, String password) async {
    final user = await _datasource.register(name, email, password);
    authState.value = true;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await _datasource.logout();
    authState.value = false;
    _controller.add(null);
  }

  @override
  Future<UserProfile?> getCurrentUser() => _datasource.getCurrentUser();

  @override
  Stream<UserProfile?> get authStateChanges => _controller.stream;
}
