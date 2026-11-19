import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class RestAuthService implements AuthService {
  static const _sessionKey = 'ligtaslink_api_session_v1';

  final String _baseUrl;
  final SharedPreferences _preferences;
  LocalUser? _currentUser;

  RestAuthService._(this._baseUrl, this._preferences) {
    _restoreSession();
  }

  static Future<RestAuthService> create(String baseUrl) async {
    final preferences = await SharedPreferences.getInstance();
    return RestAuthService._(
        baseUrl.replaceFirst(RegExp(r'/$'), ''), preferences);
  }

  @override
  LocalUser? get currentUser => _currentUser;

  void _restoreSession() {
    final stored = _preferences.getString(_sessionKey);
    if (stored == null) return;
    try {
      _currentUser = _userFromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (_) {
      _preferences.remove(_sessionKey);
    }
  }

  LocalUser _userFromJson(Map<String, dynamic> json) {
    return LocalUser(
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final json = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult.failure(
            json['error'] as String? ?? 'The API request failed.');
      }
      final user = _userFromJson(json);
      _currentUser = user;
      await _preferences.setString(_sessionKey, jsonEncode(json));
      return AuthResult.success(user);
    } on FormatException {
      return const AuthResult.failure('The API returned an invalid response.');
    } catch (_) {
      return const AuthResult.failure(
        'The REST API is unavailable. Check that the server is running.',
      );
    }
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String recoveryPin,
  }) {
    return _post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'recoveryPin': recoveryPin,
    });
  }

  @override
  Future<AuthResult> signIn(String email, String password) {
    return _post('/api/auth/login', {'email': email, 'password': password});
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String recoveryPin,
    required String newPassword,
  }) {
    return _post('/api/auth/reset-password', {
      'email': email,
      'recoveryPin': recoveryPin,
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> deleteAccount({required String password}) {
    throw UnsupportedError(
      'Account deletion is not available through the configured REST API.',
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _preferences.remove(_sessionKey);
  }
}
