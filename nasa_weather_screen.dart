import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// NASA POWER daily meteorological data for a farmer's registered GPS point.
/// NASA POWER is near-real-time gridded data, not a live local weather station.
class NasaWeatherScreen extends StatefulWidget {
  final String latitude;
  final String longitude;
  final String farmName;

  const NasaWeatherScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.farmName,
  });

  @override
  State<NasaWeatherScreen> createState() => _NasaWeatherScreenState();
}

class _NasaWeatherScreenState extends State<NasaWeatherScreen> {
  bool loading = false;
  String? error;
  DateTime? dataDate;
  Map<String, double?> values = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
          '${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}';

  Future<void> fetchData() async {
    final lat = double.tryParse(widget.latitude);
    final lon = double.tryParse(widget.longitude);
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      setState(() {
        loading = false;
        error = 'This farmer profile does not have valid GPS coordinates. Update the farm latitude and longitude first.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 14));
      final uri = Uri.https(
        'power.larc.nasa.gov',
        '/api/temporal/daily/point',
        {
          'parameters': 'T2M,T2M_MAX,T2M_MIN,PRECTOTCORR,RH2M,WS10M,ALLSKY_SFC_SW_DWN',
          'community': 'AG',
          'longitude': lon.toStringAsFixed(4),
          'latitude': lat.toStringAsFixed(4),
          'start': _dateString(start),
          'end': _dateString(now),
          'format': 'JSON',
          'time-standard': 'UTC',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('NASA returned HTTP ${response.statusCode}. Please try again later.');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final properties = decoded['properties'] as Map<String, dynamic>?;
      final parameterData = properties?['parameter'] as Map<String, dynamic>?;
      if (parameterData == null) {
        throw Exception('NASA response did not contain weather parameters.');
      }

      final parsed = <String, double?>{};
      DateTime? latestDate;
      for (final parameter in parameterData.entries) {
        final daily = parameter.value as Map<String, dynamic>;
        final available = daily.entries.where((entry) {
          final number = double.tryParse(entry.value.toString());
          return number != null && number > -900;
        }).toList()
          ..sort((a, b) => b.key.compareTo(a.key));
        if (available.isNotEmpty) {
          parsed[parameter.key] = double.parse(available.first.value.toString());
          final key = available.first.key;
          final date = DateTime.tryParse(
            '${key.substring(0, 4)}-${key.substring(4, 6)}-${key.substring(6, 8)}',
          );
          if (date != null && (latestDate == null || date.isAfter(latestDate))) {
            latestDate = date;
          }
        } else {
          parsed[parameter.key] = null;
        }
      }

      if (!mounted) return;
      setState(() {
        values = parsed;
        dataDate = latestDate;
        loading = false;
        if (parsed.values.every((value) => value == null)) {
          error = 'NASA has no valid readings for this date range. Please try again later.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load NASA data. Check your internet connection and try again.\n$e';
      });
    }
  }

  String _value(String key, {int decimals = 1, String suffix = ''}) {
    final value = values[key];
    if (value == null) return 'Unavailable';
    return '${value.toStringAsFixed(decimals)}$suffix';
  }

  Widget _metric({required IconData icon, required String label, required String value, required String note}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3D8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF246B3B), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFFFFD166), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF204B2C))),
                  const SizedBox(height: 3),
                  Text(note, style: const TextStyle(fontSize: 11, color: Color(0xFFFFD166))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = '${double.tryParse(widget.latitude)?.toStringAsFixed(4) ?? widget.latitude}, '
        '${double.tryParse(widget.longitude)?.toStringAsFixed(4) ?? widget.longitude}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('NASA Farm Data'),
        actions: [
          IconButton(
            tooltip: 'Refresh NASA data',
            onPressed: loading ? null : fetchData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.satellite_alt, color: Color(0xFF246B3B)), SizedBox(width: 8), Text('NASA POWER', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))]),
                  const SizedBox(height: 8),
                  Text(widget.farmName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('Farm coordinates: $coordinates', style: const TextStyle(color: Color(0xFFFFD166), fontSize: 12)),
                  if (dataDate != null) ...[
                    const SizedBox(height: 8),
                    Text('Latest available reading: ${dataDate!.day.toString().padLeft(2, '0')}/${dataDate!.month.toString().padLeft(2, '0')}/${dataDate!.year}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF246B3B))),
                  ],
                ],
              ),
            ),
          ),
          if (loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (error != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Icon(Icons.info_outline, color: Colors.deepOrange, size: 34),
                  const SizedBox(height: 8),
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: loading ? null : fetchData, icon: const Icon(Icons.refresh), label: const Text('Try again')),
                ]),
              ),
            ),
          ],
          if (!loading && error == null) ...[
            _metric(icon: Icons.thermostat, label: 'Average air temperature', value: _value('T2M', suffix: ' °C'), note: 'NASA daily average'),
            _metric(icon: Icons.wb_sunny_outlined, label: 'Maximum temperature', value: _value('T2M_MAX', suffix: ' °C'), note: 'Daily maximum'),
            _metric(icon: Icons.ac_unit, label: 'Minimum temperature', value: _value('T2M_MIN', suffix: ' °C'), note: 'Daily minimum'),
            _metric(icon: Icons.water_drop_outlined, label: 'Precipitation', value: _value('PRECTOTCORR', suffix: ' mm'), note: 'Estimated daily precipitation'),
            _metric(icon: Icons.water, label: 'Relative humidity', value: _value('RH2M', suffix: ' %'), note: 'At 2 metres'),
            _metric(icon: Icons.air, label: 'Wind speed', value: _value('WS10M', suffix: ' m/s'), note: 'At 10 metres'),
            _metric(icon: Icons.light_mode_outlined, label: 'Solar radiation', value: _value('ALLSKY_SFC_SW_DWN', suffix: ' kWh/m²/day'), note: 'Daily surface solar energy'),
          ],
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Data note: NASA POWER provides gridded satellite/model-based environmental data updated near real time, not instant local sensor readings. Some dates or parameters may be unavailable. Use local forecasts and official advisories for urgent farm decisions.',
                style: TextStyle(fontSize: 12, color: Color(0xFFFFD166), height: 1.4),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => launchNASA(),
              child: const Text('Open NASA POWER website'),
            ),
          ),
        ],
      ),
    );
  }

  void launchNASA() {
    // Keeping this screen dependency-light: users can visit the official service
    // by copying the public URL from NASA POWER's homepage if needed.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('NASA POWER: https://power.larc.nasa.gov/')),
    );
  }
}
