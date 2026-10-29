import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ServiceItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final String availability;
  final String responseTime;
  final Color color;
  final IconData icon;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.availability,
    required this.responseTime,
    required this.color,
    required this.icon,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final icon = <String, IconData>{
      'medical_services': Icons.medical_services_outlined,
      'local_fire_department': Icons.local_fire_department_outlined,
      'local_police': Icons.local_police_outlined,
      'car_crash': Icons.car_crash_outlined,
    };
    final colorValue = (json['color'] as String).replaceFirst('#', '');
    return ServiceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      availability: json['availability'] as String,
      responseTime: json['responseTime'] as String,
      color: Color(int.parse('FF$colorValue', radix: 16)),
      icon: icon[json['icon']] ?? Icons.support_agent_outlined,
    );
  }
}

class Course {
  final String id;
  final String title;
  final String category;
  final String description;
  final String availability;
  final String responseTime;

  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.availability,
    required this.responseTime,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      availability: json['availability'] as String,
      responseTime: json['responseTime'] as String,
    );
  }
}

class ServicesCatalog {
  final String title;
  final String updatedAt;
  final List<ServiceItem> services;
  final String? offlineMessage;

  const ServicesCatalog({
    required this.title,
    required this.updatedAt,
    required this.services,
    this.offlineMessage,
  });

  factory ServicesCatalog.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'] as Map<String, dynamic>;
    final services = (json['services'] as List<dynamic>)
        .map((item) => ServiceItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return ServicesCatalog(
      title: catalog['title'] as String,
      updatedAt: catalog['updatedAt'] as String,
      services: services,
    );
  }
}

class ServicesApi {
  static const _servicesGistUrl =
      'https://gist.githubusercontent.com/DIZON-alt/b66f48dbfb2c6e4d19690820641f9d0d/raw/7b5a5e0961fcacbaa93f9de0d266ae9d41c6af7e/service.json';
  static const apiUrl = _servicesGistUrl;

  final String baseUrl;
  final http.Client? client;

  const ServicesApi({required this.baseUrl, this.client});

  Future<List<Course>> fetchCourses() async {
    final uri = Uri.parse(apiUrl);
    final response = await (client?.get(uri) ?? http.get(uri))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Failed to load courses from API');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> jsonList;
    if (decoded is List<dynamic>) {
      jsonList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final records = decoded['courses'] ?? decoded['services'];
      if (records is! List<dynamic>) {
        throw const FormatException(
          'API response must contain a courses or services list.',
        );
      }
      jsonList = records;
    } else {
      throw const FormatException(
        'API response must be a JSON list or object.',
      );
    }

    return jsonList
        .map((json) => Course.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ServicesCatalog> fetchServices() async {
    final apiBaseUrl = baseUrl.trim();
    final usesGist = apiBaseUrl.isEmpty;
    final uri = usesGist
        ? Uri.parse(_servicesGistUrl)
        : Uri.parse(
            '${apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/api/services',
          );
    final source = usesGist ? 'Gist' : 'REST API';

    late final http.Response response;
    try {
      response = await _get(uri).timeout(const Duration(seconds: 5));
    } on http.ClientException {
      return _fetchBundledServices(
        '$source is unreachable; showing the bundled service catalog.',
      );
    } on TimeoutException {
      return _fetchBundledServices(
        '$source timed out; showing the bundled service catalog.',
      );
    }

    if (response.statusCode != 200) {
      return _fetchBundledServices(
        '$source returned HTTP ${response.statusCode}; showing the bundled service catalog.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ServicesCatalog.fromJson(json);
  }

  Future<http.Response> _get(Uri uri) {
    final httpClient = client;
    return httpClient == null ? http.get(uri) : httpClient.get(uri);
  }

  Future<ServicesCatalog> _fetchBundledServices(String offlineMessage) async {
    final json = jsonDecode(await rootBundle.loadString('assets/services.json'))
        as Map<String, dynamic>;
    final catalog = ServicesCatalog.fromJson(json);
    return ServicesCatalog(
      title: catalog.title,
      updatedAt: catalog.updatedAt,
      services: catalog.services,
      offlineMessage: offlineMessage,
    );
  }
}
