import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/user_profile.dart';
import 'local_database.dart';

class LocalAuthDatasource {
  static const _keyCurrentUser = 'current_user_json';
  final _uuid = const Uuid();

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<UserProfile> register(
      String name, String email, String password) async {
    final db = await LocalDatabase.instance.database;

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (existing.isNotEmpty) {
      throw const AppAuthException('E-mail já cadastrado.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await db.insert('users', {
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'password_hash': _hash(password),
      'created_at': now.toIso8601String(),
    });

    final user =
        UserProfile(id: id, name: name, email: email, createdAt: now);
    await _persist(user);
    return user;
  }

  Future<UserProfile> login(String email, String password) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.toLowerCase(), _hash(password)],
    );
    if (rows.isEmpty) {
      throw const AppAuthException('E-mail ou senha inválidos.');
    }
    final user = _rowToProfile(rows.first);
    await _persist(user);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  Future<UserProfile?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyCurrentUser);
    if (json == null) return null;
    return _jsonToProfile(json);
  }

  Future<void> _persist(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyCurrentUser,
      jsonEncode({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'created_at': user.createdAt.toIso8601String(),
      }),
    );
  }

  UserProfile _rowToProfile(Map<String, Object?> row) => UserProfile(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  UserProfile _jsonToProfile(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return UserProfile(
      id: m['id'] as String,
      name: m['name'] as String,
      email: m['email'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
