import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ligtaslink/services_api.dart';
import 'package:ligtaslink/services_page.dart';

void main() {
  testWidgets('refreshes services without returning a Future from setState',
      (tester) async {
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return http.Response(
        jsonEncode({
          'catalog': {'title': 'Services', 'updatedAt': 'today'},
          'services': [
            {
              'id': 'medical',
              'name': 'Medical Response',
              'category': 'Health',
              'description': 'Medical assistance.',
              'availability': '24/7',
              'responseTime': '5-15 min',
              'color': '#FF0000',
              'icon': 'medical_services',
            },
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServicesPage(
            api: ServicesApi(baseUrl: '', client: client),
            onRequest: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh services'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(requestCount, 2);
  });
}
