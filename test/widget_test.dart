import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ligtaslink/auth_service.dart';
import 'package:ligtaslink/home_page.dart';
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

  testWidgets('official alerts show Hazards and Earthquake tabs',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = await LocalAuthService.create();
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          auth: auth,
          user: const LocalUser(name: 'Test Member', email: 'test@example.com'),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open National Hub'));
    await tester.pumpAndSettle();

    expect(find.text('Hazards'), findsOneWidget);
    expect(find.text('Hazard warnings'), findsOneWidget);

    await tester.tap(find.text('Earthquake'));
    await tester.pumpAndSettle();

    expect(find.text('Earthquake warnings'), findsOneWidget);
  });
}
