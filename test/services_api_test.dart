import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ligtaslink/services_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches and parses services from the configured Gist', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://gist.githubusercontent.com/DIZON-alt/b66f48dbfb2c6e4d19690820641f9d0d/raw/7b5a5e0961fcacbaa93f9de0d266ae9d41c6af7e/service.json',
      );
      return httpResponse(
        jsonEncode({
          'catalog': {'title': 'Emergency Response Services'},
          'services': [
            {
              'id': 'medical-response',
              'name': 'Medical Response',
              'category': 'Health',
              'description': 'Urgent medical assistance.',
              'availability': '24/7',
              'responseTime': '5-15 min',
            },
          ],
        }),
      );
    });
    addTearDown(client.close);

    final courses =
        await ServicesApi(baseUrl: '', client: client).fetchCourses();

    expect(courses, hasLength(1));
    expect(courses.single.title, 'Medical Response');
    expect(courses.single.category, 'Health');
  });

  test('falls back to bundled services when the Gist request fails', () async {
    final catalog = await const ServicesApi(baseUrl: '').fetchServices();

    expect(catalog.services, hasLength(4));
    expect(catalog.services.first.name, 'Medical Response');
    expect(catalog.offlineMessage, contains('Gist'));
  });

  test('falls back to bundled services when the REST API returns an error',
      () async {
    final catalog = await const ServicesApi(
      baseUrl: 'http://127.0.0.1:1',
    ).fetchServices();

    expect(catalog.services, hasLength(4));
    expect(catalog.offlineMessage, contains('HTTP 400'));
  });
}

http.Response httpResponse(String body) => http.Response(body, 200);
