const cheerio = require('cheerio');

const PHIVOLCS_URL = 'https://earthquake.phivolcs.dost.gov.ph/';
const PAGASA_URL =
  'https://www.pagasa.dost.gov.ph/tropical-cyclone/severe-weather-bulletin';

function normalizeText(value) {
  return value.replace(/\s+/g, ' ').trim();
}

function parseEarthquakes(html) {
  const $ = cheerio.load(html);
  const events = [];

  $('table tr').each((_, row) => {
    const cells = $(row).find('td');
    if (cells.length < 6) return;

    const href = $(cells[0]).find('a[href]').attr('href');
    if (!href || !href.includes('Earthquake_Information')) return;

    const magnitude = normalizeText($(cells[4]).text());
    if (!Number.isFinite(Number(magnitude))) {
      throw new Error('PHIVOLCS earthquake magnitude was invalid.');
    }

    const normalizedHref = href.replace(/\\/g, '/');
    events.push({
      id: new URL(normalizedHref, PHIVOLCS_URL).toString(),
      time: normalizeText($(cells[0]).text()),
      latitude: normalizeText($(cells[1]).text()),
      longitude: normalizeText($(cells[2]).text()),
      depth: normalizeText($(cells[3]).text()),
      magnitude,
      location: normalizeText($(cells[5]).text()),
    });
  });

  if (events.length === 0) {
    throw new Error('No PHIVOLCS earthquake records were found.');
  }
  return events.slice(0, 100);
}

function parseTyphoon(html) {
  const $ = cheerio.load(html);
  const section = $(
    '.tropical-cyclone-weather-bulletin-page .article-content',
  ).first();
  if (section.length === 0) {
    throw new Error('PAGASA bulletin section was not found.');
  }

  const text = normalizeText(section.text());
  if (!text) throw new Error('PAGASA bulletin section was empty.');
  if (
    text.toLowerCase().includes(
      'no active tropical cyclone within the philippine area of responsibility',
    )
  ) {
    return null;
  }

  const links = [];
  section.find('a[href]').each((_, link) => {
    links.push($(link).attr('href'));
  });
  return {
    id: links.join('|') || text,
    title: links.length
      ? normalizeText(section.find('a[href]').first().text())
      : 'Tropical Cyclone Bulletin',
    details: text,
    sourceUrl: PAGASA_URL,
  };
}

module.exports = { PAGASA_URL, PHIVOLCS_URL, parseEarthquakes, parseTyphoon };
