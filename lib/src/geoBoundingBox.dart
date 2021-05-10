import 'package:geojson/geojson.dart';

class GeoBoundingBox {
  /// The polygon bounded by this bounding box
  final GeoJsonFeature<GeoJsonPolygon> feature;

  final double maxLat;
  final double maxLong;
  final double minLat;
  final double minLong;

  /// A geographical rectangle. Typically used as a bounding box for a polygon
  /// for fast search of point-in-multiple-polygon.
  GeoBoundingBox({
    this.feature,
    this.maxLat,
    this.maxLong,
    this.minLat,
    this.minLong,
  });

  double get bottom => minLong;
  double get left => minLat;
  double get right => maxLat;
  double get top => maxLong;

  bool contains(double lat, double long) {
    final containsLat = maxLat >= lat && minLat <= lat;
    final containsLong = maxLong >= long && minLong <= long;
    return containsLat && containsLong;
  }

  @override
  String toString() => 'GeoRect($minLat,$minLong,$maxLat,$maxLong)';
}
