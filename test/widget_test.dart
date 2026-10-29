import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ligtaslink/auth_service.dart';
import 'package:ligtaslink/login_page.dart';

void main() {
  testWidgets('login page loads and validates empty fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = await LocalAuthService.create();
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));

    expect(find.text('LIGTASLINK'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
