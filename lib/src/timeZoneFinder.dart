import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:geojson/geojson.dart';
import 'package:geopoint/geopoint.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:timezone_finder/src/extensions.dart';

const int _kOffset = 200;

class TimeZoneFinder {
  final _isolates = <Isolate?>[];

  // void _readZipArchive() {
  //   final bytes = File('lib/assets/timezones.zip').readAsBytesSync();

  //   // Decode and extract the contents of the Zip archive to disk.
  //   final archive = ZipDecoder().decodeBytes(bytes);
  //   File('lib/assets/' + archive.fileName(0))
  //     ..createSync()
  //     ..writeAsBytesSync(archive.fileData(0));
  // }

  /// Finds the time zone name according to the IANA time zone database, for the given [latitude] and [longitude] in degrees.
  Future<String?> findTimeZoneName(double latitude, double longitude) async {
    if (latitude > 90 ||
        latitude < -90 ||
        longitude > 180 ||
        longitude < -180) {
      return null;
    }

    final completer = Completer<String>();

    var geoPoint = GeoJsonPoint(
        geoPoint: GeoPoint(latitude: latitude, longitude: longitude));

    // if (!await File('lib/assets/timezones').exists()) _readZipArchive();

    final db = sqlite3.open('lib/assets/timezones');
    var resultSet = db.select('SELECT * FROM timezones LIMIT $_kOffset');
    var offset = 0;

    var nbIsolate = 0;
    var nbIsolateCompleted = 0;

    final receiverPort = ReceivePort()
      ..listen(
        (data) {
          if (data == null) {
            nbIsolateCompleted += 1;
            if (nbIsolateCompleted == nbIsolate) completer.complete(null);
          } else {
            completer.complete(data);
          }
        },
        onDone: () => _killIsolates(),
      );

    while (resultSet.isNotEmpty) {
      final message =
          _IsolateMessage(resultSet, geoPoint, receiverPort.sendPort);
      _isolates.add(await Isolate.spawn(_isolateProcessResultSet, message,
          onExit: receiverPort.sendPort));
      nbIsolate += 1;

      offset += _kOffset;
      resultSet =
          db.select('SELECT * FROM timezones LIMIT $_kOffset OFFSET $offset');
    }

    db.dispose();

    return completer.future.then((value) {
      receiverPort.close();
      if (value == null) {
        // Get time zone from longitude. 15 degrees of longitude = 1 hr difference
        final offset = longitude / 15.0;
        if (offset > -1.0 && offset < 1.0) return 'Etc/GMT';

        final sign = offset.isNegative ? '+' : '-'; // Sign are reversed
        return 'Etc/GMT$sign${offset.truncate().abs()}';
      }
      return value;
    });
  }

  void _killIsolates() {
    for (var isolate in _isolates) {
      isolate?.kill(priority: Isolate.immediate);
      isolate = null;
    }
  }

  static void _isolateProcessResultSet(_IsolateMessage message) async {
    final polygons = <GeoJsonFeature<GeoJsonPolygon>>[];
    for (var row in message.resultSet.rows) {
      row = row as List<String>;
      final feature = GeoJsonFeature<GeoJsonPolygon>();
      feature.type = GeoJsonFeatureType.polygon;
      feature.properties = {'tzid': row[2]};

      final geoPoints = <GeoPoint>[];

      for (final coord in json.decode(row[1])[0]) {
        geoPoints.add(GeoPoint(
          latitude: double.parse(coord[1].toString()),
          longitude: double.parse(coord[0].toString()),
        ));
      }

      feature.geometry = GeoJsonPolygon(
        geoSeries: List.generate(
          feature.geometry!.geoSeries.length,
          (index) {
            var geoSerie = feature.geometry!.geoSeries[index];
            return GeoSerie(name: geoSerie.name, type: geoSerie.type);
          },
        ),
      );

      polygons.add(feature);
    }

    final geo = GeoJson();

    final result = await geo.geofenceSearch(polygons, message.geoPoint);
    if (result.isNotEmpty) {
      message.sendPort.send(result.first!.properties!['tzid']);
    }

    geo.dispose();
  }
}

class _IsolateMessage {
  ResultSet resultSet;
  GeoJsonPoint geoPoint;
  SendPort sendPort;

  _IsolateMessage(this.resultSet, this.geoPoint, this.sendPort);
}
