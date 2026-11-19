import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUser {
  final String name;
  final String email;

  const LocalUser({required this.name, required this.email});
}

class AuthResult {
  final bool success;
  final String message;
  final LocalUser? user;

  const AuthResult._(this.success, this.message, this.user);
  const AuthResult.success(LocalUser user) : this._(true, '', user);
  const AuthResult.failure(String message) : this._(false, message, null);
}

abstract interface class AuthService {
  LocalUser? get currentUser;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String recoveryPin,
  });

  Future<AuthResult> signIn(String email, String password);

  Future<AuthResult> resetPassword({
    required String email,
    required String recoveryPin,
    required String newPassword,
  });

  Future<void> deleteAccount({required String password});

  Future<void> signOut();
}

class LocalAuthService implements AuthService {
  static const _accountsKey = 'ligtaslink_accounts_v1';
  static const _sessionKey = 'ligtaslink_session_v1';

  final SharedPreferences _preferences;
  LocalUser? _currentUser;

  LocalAuthService._(this._preferences) {
    _restoreSession();
  }

  static Future<LocalAuthService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalAuthService._(preferences);
  }

  @override
  LocalUser? get currentUser => _currentUser;

  List<Map<String, dynamic>> _loadAccounts() {
    final stored = _preferences.getString(_accountsKey);
    if (stored == null || stored.isEmpty) return [];
    try {
      return (jsonDecode(stored) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAccounts(List<Map<String, dynamic>> accounts) async {
    await _preferences.setString(_accountsKey, jsonEncode(accounts));
  }

  String _newSalt() {
    final random = Random.secure();
    return base64UrlEncode(
      List<int>.generate(24, (_) => random.nextInt(256)),
    );
  }

  String _hash(String value, String salt) {
    return sha256.convert(utf8.encode('$salt:$value')).toString();
  }

  void _restoreSession() {
    final email = _preferences.getString(_sessionKey)?.toLowerCase();
    if (email == null) return;
    for (final account in _loadAccounts()) {
      if (account['email'] == email) {
        _currentUser = LocalUser(
          name: account['name'] as String,
          email: account['email'] as String,
        );
        return;
      }
    }
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String recoveryPin,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = _loadAccounts();
    if (accounts.any((account) => account['email'] == normalizedEmail)) {
      return const AuthResult.failure(
          'An account with that email already exists.');
    }

    final passwordSalt = _newSalt();
    final pinSalt = _newSalt();
    final account = <String, dynamic>{
      'name': name.trim(),
      'email': normalizedEmail,
      'passwordSalt': passwordSalt,
      'passwordHash': _hash(password, passwordSalt),
      'pinSalt': pinSalt,
      'pinHash': _hash(recoveryPin, pinSalt),
    };
    accounts.add(account);
    await _saveAccounts(accounts);

    _currentUser = LocalUser(name: name.trim(), email: normalizedEmail);
    await _preferences.setString(_sessionKey, normalizedEmail);
    return AuthResult.success(_currentUser!);
  }

  @override
  Future<AuthResult> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in _loadAccounts()) {
      if (account['email'] != normalizedEmail) continue;
      final salt = account['passwordSalt'] as String;
      if (_hash(password, salt) != account['passwordHash']) break;
      _currentUser = LocalUser(
        name: account['name'] as String,
        email: account['email'] as String,
      );
      await _preferences.setString(_sessionKey, normalizedEmail);
      return AuthResult.success(_currentUser!);
    }
    return const AuthResult.failure('Incorrect email or password.');
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String recoveryPin,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = _loadAccounts();
    for (var index = 0; index < accounts.length; index++) {
      final account = accounts[index];
      if (account['email'] != normalizedEmail) continue;
      final pinSalt = account['pinSalt'] as String;
      if (_hash(recoveryPin, pinSalt) != account['pinHash']) {
        return const AuthResult.failure('The recovery PIN is incorrect.');
      }
      final passwordSalt = _newSalt();
      account['passwordSalt'] = passwordSalt;
      account['passwordHash'] = _hash(newPassword, passwordSalt);
      accounts[index] = account;
      await _saveAccounts(accounts);
      return AuthResult.success(
        LocalUser(
          name: account['name'] as String,
          email: account['email'] as String,
        ),
      );
    }
    return const AuthResult.failure('No account was found for that email.');
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('No signed-in account was found.');
    }

    final accounts = _loadAccounts();
    final accountIndex =
        accounts.indexWhere((account) => account['email'] == user.email);
    if (accountIndex < 0) {
      throw StateError('The signed-in account could not be found.');
    }

    final account = accounts[accountIndex];
    if (_hash(password, account['passwordSalt'] as String) !=
        account['passwordHash']) {
      throw StateError('The password is incorrect.');
    }

    accounts.removeAt(accountIndex);
    await _saveAccounts(accounts);
    await _preferences.remove(_sessionKey);
    _currentUser = null;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _preferences.remove(_sessionKey);
  }
}
