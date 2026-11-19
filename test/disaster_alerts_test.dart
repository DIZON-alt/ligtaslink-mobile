import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ligtaslink/disaster_alerts.dart';

void main() {
  test('parses recent earthquakes and active PAGASA bulletins', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'earthquake.phivolcs.dost.gov.ph') {
        return http.Response(
          '''
          <table>
            <tr><th>Date</th></tr>
            <tr>
              <td><a href="2026_Earthquake_Information\\November\\event.html">10 November 2026 - 02:55 PM</a></td>
              <td>05.63</td><td>125.34</td><td>034</td><td>4.5</td>
              <td>Near Sarangani Island</td>
            </tr>
          </table>
          ''',
          200,
        );
      }
      return http.Response(
        '''
        <div class="tropical-cyclone-weather-bulletin-page">
          <div class="article-content">
            <ul><li><a href="https://pubfiles.pagasa.dost.gov.ph/tcb.pdf">TCB #1</a></li></ul>
          </div>
        </div>
        ''',
        200,
      );
    });
    addTearDown(client.close);

    final snapshot = await DisasterAlertsApi(client: client).fetch();

    expect(snapshot.earthquakes, hasLength(1));
    expect(snapshot.earthquakes.single.magnitude, '4.5');
    expect(snapshot.earthquakes.single.location, 'Near Sarangani Island');
    expect(snapshot.earthquakeError, isNull);
    expect(snapshot.typhoon?.title, 'TCB #1');
    expect(snapshot.typhoon?.sourceUrl.host, 'www.pagasa.dost.gov.ph');
    expect(snapshot.typhoonError, isNull);
  });

  test('reports an inactive typhoon and keeps source failures visible',
      () async {
    final client = MockClient((request) async {
      if (request.url.host == 'earthquake.phivolcs.dost.gov.ph') {
        return http.Response('Unavailable', 503);
      }
      return http.Response(
        '''
        <div class="tropical-cyclone-weather-bulletin-page">
          <div class="article-content">
            <h3>No Active Tropical Cyclone within the Philippine Area of Responsibility</h3>
          </div>
        </div>
        ''',
        200,
      );
    });
    addTearDown(client.close);

    final snapshot = await DisasterAlertsApi(client: client).fetch();

    expect(snapshot.earthquakeError, contains('HTTP 503'));
    expect(snapshot.typhoon, isNull);
    expect(snapshot.typhoonError, isNull);
  });
}
