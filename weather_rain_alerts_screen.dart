import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A separate alert-focused screen based on the latest available NASA POWER observations.
/// This is not a forecast and does not send push notifications.
class WeatherRainAlertsScreen extends StatefulWidget {
  final String latitude;
  final String longitude;
  final String farmName;

  const WeatherRainAlertsScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.farmName,
  });

  @override
  State<WeatherRainAlertsScreen> createState() => _WeatherRainAlertsScreenState();
}

class _WeatherRainAlertsScreenState extends State<WeatherRainAlertsScreen> {
  bool loading = false;
  String? error;
  DateTime? readingTimeUtc;
  double? rain24Hours;
  double? temperature;
  double? humidity;
  double? wind;

  @override
  void initState() {
    super.initState();
    refreshAlerts();
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  double? _valid(dynamic value) {
    final n = double.tryParse(value.toString());
    if (n == null || !n.isFinite || n <= -900) return null;
    return n;
  }

  Future<void> refreshAlerts() async {
    final lat = double.tryParse(widget.latitude.trim());
    final lon = double.tryParse(widget.longitude.trim());
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'The farmer profile has no valid GPS coordinates. Update the saved farm latitude and longitude.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final now = DateTime.now().toUtc();
      final start = now.subtract(const Duration(days: 7));
      final uri = Uri.https('power.larc.nasa.gov', '/api/temporal/hourly/point', {
        'parameters': 'PRECTOTCORR,T2M,RH2M,WS10M',
        'community': 'AG',
        'longitude': lon.toStringAsFixed(4),
        'latitude': lat.toStringAsFixed(4),
        'start': _dateKey(start),
        'end': _dateKey(now),
        'format': 'JSON',
        'time-standard': 'UTC',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 35));
      if (response.statusCode != 200) {
        throw Exception('NASA POWER returned HTTP ${response.statusCode}. Try again later.');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final properties = json['properties'] as Map<String, dynamic>?;
      final parameters = properties?['parameter'] as Map<String, dynamic>?;
      if (parameters == null) throw Exception('NASA response did not include the requested parameters.');

      Map<String, dynamic> series(String key) {
        final raw = parameters[key];
        return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      }
      final rain = series('PRECTOTCORR');
      final temps = series('T2M');
      final humiditySeries = series('RH2M');
      final winds = series('WS10M');
      final keys = <String>{...rain.keys, ...temps.keys, ...humiditySeries.keys, ...winds.keys}.toList()..sort();
      String? newestKey;
      for (final key in keys.reversed) {
        if (_valid(rain[key]) != null || _valid(temps[key]) != null || _valid(humiditySeries[key]) != null || _valid(winds[key]) != null) {
          newestKey = key;
          break;
        }
      }
      if (newestKey == null || newestKey.length < 10) {
        throw Exception('No valid readings were returned for this farm and date range.');
      }
      final newestDate = DateTime.tryParse('${newestKey.substring(0, 4)}-${newestKey.substring(4, 6)}-${newestKey.substring(6, 8)}T${newestKey.substring(8, 10)}:00:00Z');
      final rainKeys = rain.keys.where((k) => k.compareTo(newestKey!) <= 0).toList()..sort();
      final last24 = rainKeys.length > 24 ? rainKeys.sublist(rainKeys.length - 24) : rainKeys;
      var total = 0.0;
      var count = 0;
      for (final key in last24) {
        final value = _valid(rain[key]);
        if (value != null) { total += value; count++; }
      }
      if (!mounted) return;
      setState(() {
        readingTimeUtc = newestDate;
        rain24Hours = count > 0 ? total : null;
        temperature = _valid(temps[newestKey]);
        humidity = _valid(humiditySeries[newestKey]);
        wind = _valid(winds[newestKey]);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load rain alert data. Check internet access and try again.\n$e';
      });
    }
  }

  String get alertTitle {
    if (rain24Hours == null) return 'Rain status unavailable';
    if (rain24Hours! >= 20) return 'HIGH: Heavy recent rainfall';
    if (rain24Hours! >= 10) return 'CAUTION: Significant rainfall';
    if (rain24Hours! >= 2) return 'NOTICE: Rainfall recorded';
    return 'LOW: Little recent rainfall';
  }

  Color get alertColor {
    if (rain24Hours == null) return Colors.blueGrey;
    if (rain24Hours! >= 20) return Colors.red.shade800;
    if (rain24Hours! >= 10) return Colors.deepOrange.shade800;
    if (rain24Hours! >= 2) return Colors.blue.shade800;
    return const Color(0xFF246B3B);
  }

  String get advice {
    if (rain24Hours == null) return 'Rainfall data is unavailable. Refresh later and check local weather advisories.';
    if (rain24Hours! >= 20) return 'Recent rainfall is high in the latest available data. Inspect field drainage, avoid waterlogged areas, and postpone irrigation until soil conditions are checked.';
    if (rain24Hours! >= 10) return 'Notable recent rainfall was detected. Check drainage and field moisture before irrigation or fertilizer application.';
    if (rain24Hours! >= 2) return 'Some rainfall was detected. Check actual soil moisture before watering.';
    return 'Little rainfall was recorded in the latest available observation window. Check soil moisture and local forecasts before irrigation.';
  }

  String fmt(double? n, String unit) => n == null ? 'Unavailable' : '${n.toStringAsFixed(1)}$unit';

  Widget metric(IconData icon, String title, String value, String subtitle) => Card(
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF246B3B), size: 30),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: SizedBox(width: 115, child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final date = readingTimeUtc == null ? 'Not available' : '${readingTimeUtc!.toLocal().toString().substring(0, 16)} (local time)';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & Rain Alerts'),
        actions: [IconButton(tooltip: 'Refresh alerts', onPressed: loading ? null : refreshAlerts, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.notifications_active, color: Color(0xFF246B3B)), SizedBox(width: 8), Text('FARM ALERT CENTRE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
              const SizedBox(height: 8),
              Text(widget.farmName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('GPS: ${widget.latitude}, ${widget.longitude}', style: const TextStyle(color: Color(0xFFFFD166), fontSize: 12)),
              const SizedBox(height: 6),
              Text('Latest observation: $date', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD166))),
            ]),
          )),
          if (loading) const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
          if (error != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const Icon(Icons.error_outline, color: Colors.deepOrange, size: 38),
            const SizedBox(height: 8), Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12), ElevatedButton.icon(onPressed: loading ? null : refreshAlerts, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ]))),
          if (!loading && error == null && readingTimeUtc != null) ...[
            Card(color: alertColor.withValues(alpha: 0.10), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.umbrella, color: alertColor, size: 34), const SizedBox(width: 10), Expanded(child: Text(alertTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: alertColor)))]),
              const SizedBox(height: 12),
              Text('Rainfall in latest available 24-hour window: ${fmt(rain24Hours, ' mm')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8), Text(advice, style: const TextStyle(height: 1.45)),
            ]))),
            metric(Icons.thermostat, 'Air temperature', fmt(temperature, ' °C'), 'Latest available reading'),
            metric(Icons.water_drop, 'Humidity', fmt(humidity, ' %'), 'Latest available reading'),
            metric(Icons.air, 'Wind speed', fmt(wind, ' m/s'), 'Latest available reading'),
          ],
          const SizedBox(height: 8),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Text(
            'Important: these are observation-based guidance alerts, not future rain forecasts, official severe-weather warnings, or push notifications. NASA POWER is not live local sensor data; meteorological data can be delayed by around 2–3 days. For imminent rain or storms, check official IMD/local alerts. The rainfall thresholds are simple guidance indicators, not an official warning scale.',
            style: TextStyle(fontSize: 12, color: Color(0xFFFFD166), height: 1.45),
          ))),
        ],
      ),
    );
  }
}
