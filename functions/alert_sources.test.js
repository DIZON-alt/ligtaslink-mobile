const test = require('node:test');
const assert = require('node:assert/strict');

const { parseEarthquakes, parseTyphoon } = require('./alert_sources');

test('parses PHIVOLCS earthquake rows and Windows-style bulletin links', () => {
  const events = parseEarthquakes(`
    <table><tr>
      <td><a href="2026_Earthquake_Information\\November\\event.html">10 November 2026 - 02:55 PM</a></td>
      <td>05.63</td><td>125.34</td><td>034</td><td>4.5</td>
      <td>Near Sarangani Island</td>
    </tr></table>
  `);

  assert.equal(events.length, 1);
  assert.equal(events[0].magnitude, '4.5');
  assert.equal(events[0].location, 'Near Sarangani Island');
  assert.match(events[0].id, /November\/event\.html$/);
});

test('distinguishes an active PAGASA bulletin from no active cyclone', () => {
  const active = parseTyphoon(`
    <div class="tropical-cyclone-weather-bulletin-page">
      <div class="article-content">
        <a href="https://pubfiles.pagasa.dost.gov.ph/tcb.pdf">TCB #1</a>
      </div>
    </div>
  `);
  assert.equal(active.title, 'TCB #1');
  assert.match(active.id, /tcb\.pdf$/);

  const inactive = parseTyphoon(`
    <div class="tropical-cyclone-weather-bulletin-page">
      <div class="article-content">
        <h3>No Active Tropical Cyclone within the Philippine Area of Responsibility</h3>
      </div>
    </div>
  `);
  assert.equal(inactive, null);
});
