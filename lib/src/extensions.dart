import 'package:geojson/geojson.dart';
import 'package:timezone_finder/src/geoBoundingBox.dart';

/// Geofencing search extensions.
///
/// The original geofencing search provided by the GeoJson package is not suitable to find in which polygons a single point is
/// when having a large number of polygons.
/// Indeed, it is necessary to search each polygon individually and as there is more than 1,000 polygons used to define
/// timezones, it was not a viable solution.
///
/// Thanks to lukepighetti (see link below), he proposed a fast solution using pre-computed bounding boxes.
///
/// Source: https://gist.github.com/lukepighetti/442fca7115c752b9a93b025fc04b4c18
extension GeoJsonSearchX on GeoJson {
  /// Given a list of polygons, find which one contains a given point.
  ///
  /// If the point isn't within any of these polygons, return `null`.
  Future<List<GeoJsonFeature<GeoJsonPolygon>?>> geofenceSearch(
    List<GeoJsonFeature<GeoJsonPolygon>> geofences,
    GeoJsonPoint query,
  ) async {
    final boundingBoxes = getBoundingBoxes(geofences);

    final filteredGeofences = [
      for (var box in boundingBoxes)
        if (box.contains(query.geoPoint.latitude, query.geoPoint.longitude))
          box.feature
    ];

    return await _geofencesContainingPointNaive(filteredGeofences, query);
  }

  /// Return all geofences that contain the point provided.
  ///
  /// Naive implementation. The geofences should be filtered first using a method such
  /// as searching bounding boxes first.
  Future<List<GeoJsonFeature<GeoJsonPolygon>?>> _geofencesContainingPointNaive(
    List<GeoJsonFeature<GeoJsonPolygon>?> geofences,
    GeoJsonPoint query,
  ) async {
    final futures = [
      for (var geofence in geofences)
        geofencePolygon(
          polygon: geofence!.geometry!,
          points: [query],
        ).then((results) {
          /// Nothing found
          if (results.isEmpty) return null;

          /// Found a result
          if (results.first.name == query.name) return geofence;
        })
    ];

    final unfilteredResults = await Future.wait(futures);
    return unfilteredResults.where((e) => e != null).toList();
  }

  /// Given a set of geofence polygons, find all of their bounding boxes, and the index at which they were found.
  List<GeoBoundingBox> getBoundingBoxes(
      List<GeoJsonFeature<GeoJsonPolygon>> geofences) {
    final boundingBoxes = <GeoBoundingBox>[];

    for (var i = 0; i <= geofences.length - 1; i++) {
      final geofence = geofences[i];

      double? maxLat;
      double? minLat;
      double? maxLong;
      double? minLong;

      for (var geoSerie in geofence.geometry!.geoSeries) {
        for (var geoPoint in geoSerie.geoPoints) {
          final lat = geoPoint.latitude;
          final long = geoPoint.longitude;

          /// Make sure they get seeded if they are null
          maxLat ??= lat;
          minLat ??= lat;
          maxLong ??= long;
          minLong ??= long;

          /// Update values
          if (maxLat < lat) maxLat = lat;
          if (minLat > lat) minLat = lat;
          if (maxLong < long) maxLong = long;
          if (minLong > long) minLong = long;
        }
      }

      boundingBoxes.add(GeoBoundingBox(
        feature: geofence,
        minLat: minLat!,
        maxLong: maxLong!,
        maxLat: maxLat!,
        minLong: minLong!,
      ));
    }

    return boundingBoxes;
  }
}
