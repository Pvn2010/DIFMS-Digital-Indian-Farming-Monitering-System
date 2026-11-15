
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FieldMappingResult {
  final List<LatLng> corners;
  final double areaAcres;

  const FieldMappingResult({
    required this.corners,
    required this.areaAcres,
  });
}

class FieldMappingScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const FieldMappingScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<FieldMappingScreen> createState() =>
      _FieldMappingScreenState();
}

class _FieldMappingScreenState extends State<FieldMappingScreen> {
  final List<LatLng> corners = [];

  LatLng get mapCenter {
    final lat = widget.initialLatitude;
    final lon = widget.initialLongitude;

    if (lat != null &&
        lon != null &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180) {
      return LatLng(lat, lon);
    }

    return const LatLng(17.3850, 78.4867);
  }

  double get areaAcres {
    if (corners.length < 3) return 0;

    const earthRadiusMeters = 6371008.8;
    double sum = 0;

    for (var i = 0; i < corners.length; i++) {
      final current = corners[i];
      final next = corners[(i + 1) % corners.length];

      final lat1 = current.latitude * math.pi / 180;
      final lat2 = next.latitude * math.pi / 180;

      final lonDifference =
          (next.longitude - current.longitude) * math.pi / 180;

      sum += lonDifference *
          (2 + math.sin(lat1) + math.sin(lat2));
    }

    final squareMeters =
    (sum * earthRadiusMeters * earthRadiusMeters / 2).abs();

    return squareMeters / 4046.8564224;
  }

  void _undoCorner() {
    if (corners.isNotEmpty) {
      setState(() => corners.removeLast());
    }
  }

  void _clearCorners() {
    setState(corners.clear);
  }

  void _saveField() {
    if (corners.length < 3) return;

    Navigator.pop(
      context,
      FieldMappingResult(
        corners: List<LatLng>.from(corners),
        areaAcres: areaAcres,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Your Farm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Text(
                'Tap the map to mark each field corner in order. '
                    'Mark at least 3 corners.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 16,
                  onTap: (tapPosition, point) {
                    setState(() => corners.add(point));
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.difms',
                  ),

                  if (corners.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: corners,
                          color: Colors.green.withValues(alpha: 0.25),
                          borderColor: Colors.green,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),

                  if (corners.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: corners,
                          strokeWidth: 3,
                          color: Colors.green,
                        ),
                      ],
                    ),

                  MarkerLayer(
                    markers: corners.asMap().entries.map((entry) {
                      return Marker(
                        point: entry.value,
                        width: 38,
                        height: 42,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 28,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Responsive footer: buttons can wrap on narrow screens.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Corners marked: ${corners.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Area: ${areaAcres.toStringAsFixed(3)} acres',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed:
                        corners.isEmpty ? null : _undoCorner,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo'),
                      ),
                      TextButton.icon(
                        onPressed:
                        corners.isEmpty ? null : _clearCorners,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear'),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                        corners.length < 3 ? null : _saveField,
                        icon: const Icon(Icons.check),
                        label: const Text('Save Field'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Area is approximate and depends on the points '
                        'selected. This map is not a legal land survey.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFD166),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
