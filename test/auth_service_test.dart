import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ligtaslink/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local account deletion checks the password and clears the session',
      () async {
    final auth = await LocalAuthService.create();
    final result = await auth.register(
      name: 'Test Member',
      email: 'member@example.com',
      password: 'correct-password',
      recoveryPin: '1234',
    );

    expect(result.success, isTrue);
    await expectLater(
      auth.deleteAccount(password: 'wrong-password'),
      throwsA(isA<StateError>()),
    );
    expect(auth.currentUser, isNotNull);

    await auth.deleteAccount(password: 'correct-password');

    expect(auth.currentUser, isNull);
    final restoredAuth = await LocalAuthService.create();
    expect(restoredAuth.currentUser, isNull);
    final signIn = await restoredAuth.signIn(
      'member@example.com',
      'correct-password',
    );
    expect(signIn.success, isFalse);
  });
}
