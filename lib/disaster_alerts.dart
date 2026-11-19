import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

const phivolcsEarthquakeUrl = 'https://earthquake.phivolcs.dost.gov.ph/';
const pagasaCycloneBulletinUrl =
    'https://www.pagasa.dost.gov.ph/tropical-cyclone/severe-weather-bulletin';

class EarthquakeAlert {
  final String id;
  final String timeLabel;
  final String magnitude;
  final String location;
  final String details;
  final Uri sourceUrl;

  const EarthquakeAlert({
    required this.id,
    required this.timeLabel,
    required this.magnitude,
    required this.location,
    required this.details,
    required this.sourceUrl,
  });
}

class TyphoonAlert {
  final String id;
  final String title;
  final String details;
  final Uri sourceUrl;

  const TyphoonAlert({
    required this.id,
    required this.title,
    required this.details,
    required this.sourceUrl,
  });
}

class DisasterAlertsSnapshot {
  final List<EarthquakeAlert> earthquakes;
  final TyphoonAlert? typhoon;
  final String? earthquakeError;
  final String? typhoonError;

  const DisasterAlertsSnapshot({
    required this.earthquakes,
    required this.typhoon,
    this.earthquakeError,
    this.typhoonError,
  });
}

class DisasterAlertsApi {
  final http.Client _client;

  DisasterAlertsApi({http.Client? client}) : _client = client ?? http.Client();

  Future<DisasterAlertsSnapshot> fetch() async {
    final results = await Future.wait([
      _loadSource(
        () async => _parseEarthquakes(await _get(phivolcsEarthquakeUrl)),
      ),
      _loadSource(
        () async => _parseTyphoon(await _get(pagasaCycloneBulletinUrl)),
      ),
    ]);

    final earthquakes = results[0] as _SourceResult<List<EarthquakeAlert>>;
    final typhoon = results[1] as _SourceResult<TyphoonAlert?>;
    return DisasterAlertsSnapshot(
      earthquakes: earthquakes.value ?? const [],
      typhoon: typhoon.value,
      earthquakeError: earthquakes.error,
      typhoonError: typhoon.error,
    );
  }

  Future<_SourceResult<T>> _loadSource<T>(Future<T> Function() load) async {
    try {
      return _SourceResult(value: await load());
    } catch (error) {
      return _SourceResult(error: error.toString());
    }
  }

  Future<String> _get(String url) async {
    final response = await _client.get(Uri.parse(url), headers: const {
      'Accept': 'text/html'
    }).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Official source returned HTTP ${response.statusCode}.',
        Uri.parse(url),
      );
    }
    return response.body;
  }

  List<EarthquakeAlert> _parseEarthquakes(String body) {
    final document = html_parser.parse(body);
    final alerts = <EarthquakeAlert>[];
    for (final row in document.querySelectorAll('table tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 6) continue;

      final link = cells.first.querySelector('a[href]');
      final href = link?.attributes['href'];
      if (href == null || !href.contains('Earthquake_Information')) continue;

      final magnitude = _text(cells[4]);
      if (double.tryParse(magnitude) == null) {
        throw const FormatException(
            'PHIVOLCS earthquake magnitude was invalid.');
      }

      final sourceUrl = Uri.parse(phivolcsEarthquakeUrl).resolve(
        href.replaceAll(r'\', '/'),
      );
      final timeLabel = _text(cells[0]);
      final coordinates = '${_text(cells[1])}°N, ${_text(cells[2])}°E';
      final depth = _text(cells[3]);
      final location = _text(cells[5]);
      alerts.add(
        EarthquakeAlert(
          id: sourceUrl.toString(),
          timeLabel: timeLabel,
          magnitude: magnitude,
          location: location,
          details: '$coordinates • $depth km depth',
          sourceUrl: sourceUrl,
        ),
      );
    }

    if (alerts.isEmpty) {
      throw const FormatException('No PHIVOLCS earthquake records were found.');
    }
    return alerts.take(20).toList(growable: false);
  }

  TyphoonAlert? _parseTyphoon(String body) {
    final document = html_parser.parse(body);
    final section = document.querySelector(
      '.tropical-cyclone-weather-bulletin-page .article-content',
    );
    if (section == null) {
      throw const FormatException('PAGASA bulletin section was not found.');
    }

    final text = _text(section);
    if (text.isEmpty) {
      throw const FormatException('PAGASA bulletin section was empty.');
    }
    if (text.toLowerCase().contains(
          'no active tropical cyclone within the philippine area of responsibility',
        )) {
      return null;
    }

    final bulletinLinks = section.querySelectorAll('a[href]');
    final linkIds = bulletinLinks
        .map((link) => link.attributes['href'] ?? '')
        .where((href) => href.isNotEmpty)
        .join('|');
    final title = bulletinLinks.isEmpty
        ? 'Tropical Cyclone Bulletin'
        : _text(bulletinLinks.first);

    return TyphoonAlert(
      id: linkIds.isEmpty ? text : linkIds,
      title: title,
      details: text,
      sourceUrl: Uri.parse(pagasaCycloneBulletinUrl),
    );
  }

  String _text(html_dom.Node element) {
    return element.text!.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _SourceResult<T> {
  final T? value;
  final String? error;

  const _SourceResult({this.value, this.error});
}
