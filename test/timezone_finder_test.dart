import 'package:test/test.dart';
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  var expectedResults = <String, Map<String, dynamic>>{
    'Barcelona': {
      'latitude': 41.387048,
      'longitude': 2.17413425,
      'timezone': 'Europe/Madrid',
    },
    'Brussels': {
      'latitude': 50.843471,
      'longitude': 4.36431884,
      'timezone': 'Europe/Brussels',
    },
    'Helsinki': {
      'latitude': 60.166114,
      'longitude': 24.9361887,
      'timezone': 'Europe/Helsinki',
    },
    'Dubai': {
      'latitude': 25.263792,
      'longitude': 55.3434562,
      'timezone': 'Asia/Dubai',
    },
    'Singapore': {
      'latitude': 1.3102843,
      'longitude': 103.846485,
      'timezone': 'Asia/Singapore',
    },
    'Sydney': {
      'latitude': -33.92614,
      'longitude': 151.222826,
      'timezone': 'Australia/Sydney',
    },
    'Ushuaïa': {
      'latitude': -54.81631,
      'longitude': -68.327772,
      'timezone': 'America/Argentina/Ushuaia',
    },
    'Vancouver': {
      'latitude': 49.247112,
      'longitude': -123.10707,
      'timezone': 'America/Vancouver',
    },
    'Skopje': {
      'latitude': 42.0,
      'longitude': 21.433333,
      'timezone': 'Europe/Skopje',
    },
    'Sofia': {
      'latitude': 42.7,
      'longitude': 23.316667,
      'timezone': 'Europe/Sofia',
    },
  };

  final finder = TimeZoneFinder();

  for (var entry in expectedResults.entries) {
    group(entry.key, () {
      var expected = expectedResults[entry.key];

      test('Timezone Name', () async {
        var tzName = await finder.findTimeZoneName(
            expected?['latitude'], expected?['longitude']);
        expect(tzName, expected?['timezone']);
      });
    });
  }
}
