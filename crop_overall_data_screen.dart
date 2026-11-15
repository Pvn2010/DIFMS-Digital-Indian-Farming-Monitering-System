import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Compares NASA POWER gridded weather estimates with explicitly simulated
/// ground IoT readings until the farmer's Arduino sensors are connected.
class CropOverallDataScreen extends StatefulWidget {
  final String farmerFlin;
  final String farmerName;
  final String latitude;
  final String longitude;

  const CropOverallDataScreen({
    super.key,
    required this.farmerFlin,
    required this.farmerName,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CropOverallDataScreen> createState() => _CropOverallDataScreenState();
}

class _CropOverallDataScreenState extends State<CropOverallDataScreen> {
  bool _loadingNasa = false;
  bool _savingSample = false;
  String? _nasaError;
  DateTime? _nasaDate;
  double? _nasaTemperature;
  double? _nasaHumidity;
  double? _nasaRainfall;
  Map<String, dynamic>? _ground;

  @override
  void initState() {
    super.initState();
    _loadNasa();
    _loadLatestGroundSample();
  }

  String _nasaDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
          '${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadNasa() async {
    final lat = double.tryParse(widget.latitude);
    final lon = double.tryParse(widget.longitude);
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      if (mounted) setState(() => _nasaError = 'Valid farm GPS coordinates are required to fetch NASA data.');
      return;
    }
    setState(() { _loadingNasa = true; _nasaError = null; });
    try {
      final now = DateTime.now().toUtc();
      final start = now.subtract(const Duration(days: 14));
      final uri = Uri.https('power.larc.nasa.gov', '/api/temporal/daily/point', {
        'parameters': 'T2M,RH2M,PRECTOTCORR',
        'community': 'AG',
        'longitude': lon.toStringAsFixed(4),
        'latitude': lat.toStringAsFixed(4),
        'start': _nasaDateKey(start),
        'end': _nasaDateKey(now),
        'format': 'JSON',
        'time-standard': 'UTC',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) throw Exception('NASA POWER returned HTTP ${response.statusCode}.');
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final properties = root['properties'] as Map<String, dynamic>?;
      final parameters = properties?['parameter'] as Map<String, dynamic>?;
      if (parameters == null) throw Exception('NASA response did not include weather parameters.');

      double? latestValue(String name) {
        final daily = parameters[name];
        if (daily is! Map) return null;
        final valid = daily.entries.where((e) {
          final n = double.tryParse(e.value.toString());
          return n != null && n > -900;
        }).toList()..sort((a, b) => b.key.toString().compareTo(a.key.toString()));
        if (valid.isEmpty) return null;
        return double.tryParse(valid.first.value.toString());
      }

      DateTime? latestDate;
      for (final name in ['T2M', 'RH2M', 'PRECTOTCORR']) {
        final daily = parameters[name];
        if (daily is Map) {
          final validKeys = daily.entries.where((e) {
            final n = double.tryParse(e.value.toString());
            return n != null && n > -900;
          }).map((e) => e.key.toString()).toList()..sort();
          if (validKeys.isNotEmpty) {
            final key = validKeys.last;
            final parsed = DateTime.tryParse('${key.substring(0, 4)}-${key.substring(4, 6)}-${key.substring(6, 8)}');
            if (parsed != null && (latestDate == null || parsed.isAfter(latestDate))) latestDate = parsed;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _nasaTemperature = latestValue('T2M');
        _nasaHumidity = latestValue('RH2M');
        _nasaRainfall = latestValue('PRECTOTCORR');
        _nasaDate = latestDate;
        _loadingNasa = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingNasa = false; _nasaError = 'Could not load NASA POWER data: $e'; });
    }
  }

  Future<void> _loadLatestGroundSample() async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('farmerGroundReadings')
          .where('farmerFlin', isEqualTo: widget.farmerFlin)
          .get();
      final docs = result.docs.toList()..sort((a, b) {
        final av = a.data()['createdAt'];
        final bv = b.data()['createdAt'];
        final ad = av is Timestamp ? av.toDate() : DateTime(2000);
        final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);
        return bd.compareTo(ad);
      });
      if (mounted && docs.isNotEmpty) setState(() => _ground = docs.first.data());
    } catch (_) {
      // Keep the page usable; the save action will show a helpful permissions error.
    }
  }

  Future<void> _addSampleReadings() async {
    setState(() => _savingSample = true);
    // Illustrative values only. Never label these as live sensor readings.
    final sample = <String, dynamic>{
      'farmerFlin': widget.farmerFlin,
      'farmerName': widget.farmerName,
      'controller': 'Arduino (planned)',
      'dataType': 'simulated_demo',
      'isSimulated': true,
      'soilMoisturePercent': 42.0,
      'airTemperatureC': 30.2,
      'relativeHumidityPercent': 68.0,
      'soilPH': 6.2,
      'createdAt': FieldValue.serverTimestamp(),
      'note': 'SIMULATED DEMO DATA — not collected from connected sensors.',
    };
    try {
      await FirebaseFirestore.instance.collection('farmerGroundReadings').add(sample);
      if (!mounted) return;
      setState(() {
        _ground = {
          ...sample,
          'createdAt': Timestamp.now(),
        };
        _savingSample = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo ground readings saved. They are not live sensor data.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingSample = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save demo readings. Check Firestore rules. $e')));
    }
  }

  String _fmt(double? value, String unit) => value == null ? 'Unavailable' : '${value.toStringAsFixed(1)} $unit';

  // Explicitly return a nullable numeric result only when both measurements exist.
  num? _calculateDifference(double? nasa, double? ground) {
    if (nasa == null || ground == null) return null;
    return ground - nasa;
  }

  Widget _metric(String title, String value, IconData icon, {String? note}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 28, color: const Color(0xFF246B3B)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), softWrap: true),
          if (note != null) Text(note, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ])),
      ]),
    ),
  );

  Widget _sectionTitle(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
    child: Row(children: [Icon(icon, color: const Color(0xFF246B3B)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFB8C8D8)))]))]),
  );

  @override
  Widget build(BuildContext context) {
    final g = _ground;
    final groundTemp = (g?['airTemperatureC'] as num?)?.toDouble();
    final groundHumidity = (g?['relativeHumidityPercent'] as num?)?.toDouble();
    final groundMoisture = (g?['soilMoisturePercent'] as num?)?.toDouble();
    final groundPH = (g?['soilPH'] as num?)?.toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Overall Data'), actions: [IconButton(tooltip: 'Refresh NASA data', onPressed: _loadingNasa ? null : _loadNasa, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final maxContentWidth = constraints.maxWidth > 850 ? 850.0 : constraints.maxWidth;
        return Center(child: SizedBox(width: maxContentWidth, child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(color: const Color(0xFFEAF3E6), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Farm environmental overview', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF183047))),
            const SizedBox(height: 5),
            Text('Farmer: ${widget.farmerName} • FLIN: ${widget.farmerFlin}', style: const TextStyle(color: Color(0xFF183047))),
            const SizedBox(height: 6),
            const Text('NASA POWER provides gridded environmental estimates. Ground values below are simulated until the Arduino and sensors are connected.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF183047))),
          ]))),
          _sectionTitle('NASA vs Ground-Level Data', 'Side-by-side comparison table', Icons.compare_arrows),
          if (_loadingNasa)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          if (_nasaError != null)
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              Text(_nasaError!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: _loadNasa, icon: const Icon(Icons.refresh), label: const Text('Retry NASA data')),
            ]))),
          if (!_loadingNasa && _nasaError == null && _nasaDate != null)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(
              'NASA latest available date: ${_nasaDate!.day.toString().padLeft(2, '0')}/${_nasaDate!.month.toString().padLeft(2, '0')}/${_nasaDate!.year}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFFFD166)),
            )),
          if (g == null)
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              const Text('No ground-level readings found yet. Sample values are simulated, not live sensor data.', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FilledButton.icon(onPressed: _savingSample ? null : _addSampleReadings,
                  icon: _savingSample ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_chart),
                  label: Text(_savingSample ? 'Saving sample…' : 'Add Sample Ground Readings')),
            ]))),
          if (g != null)
            Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                child: const Text('GROUND DATA IS SIMULATED — not collected from connected Arduino sensors.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5B4300)))),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF203A50)),
                headingTextStyle: const TextStyle(color: Color(0xFFEAF3E6), fontWeight: FontWeight.bold),
                dataTextStyle: const TextStyle(color: Color(0xFFE6EEF7)),
                border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFF344B60))),
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('Parameter', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('NASA data', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Ground-level data', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: [
                  DataRow(cells: [const DataCell(Text('Air temperature')), DataCell(Text(_fmt(_nasaTemperature, '°C'))), DataCell(Text(_fmt(groundTemp, '°C')))]),
                  DataRow(cells: [const DataCell(Text('Relative humidity')), DataCell(Text(_fmt(_nasaHumidity, '%'))), DataCell(Text(_fmt(groundHumidity, '%')))]),
                  DataRow(cells: [const DataCell(Text('Precipitation')), DataCell(Text(_fmt(_nasaRainfall, 'mm/day'))), const DataCell(Text('Not measured'))]),
                  DataRow(cells: [const DataCell(Text('Soil moisture')), const DataCell(Text('Not provided')), DataCell(Text(_fmt(groundMoisture, '%')))]),
                  DataRow(cells: [const DataCell(Text('Soil pH')), const DataCell(Text('Not provided')), DataCell(Text(_fmt(groundPH, 'pH')))]),
                ],
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 6, bottom: 4), child: Text(
            'NASA POWER values are gridded environmental estimates. Ground values are simulated until real sensors are connected. Compare temperature and humidity only when both values are available.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
          )),
          _sectionTitle('Suggestions', 'Simple guidance based on available readings; verify before taking action', Icons.lightbulb_outline),
          ..._buildSuggestions(groundMoisture, groundPH, _nasaRainfall),
          if (g != null)
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _savingSample ? null : _addSampleReadings,
              icon: const Icon(Icons.add_chart), label: const Text('Add Another Sample Reading'),
            )),
          const SizedBox(height: 12),

        ])));
      })),
    );
  }

  List<Widget> _buildSuggestions(double? soilMoisture, double? soilPH, double? rainfall) {
    final suggestions = <String>[];
    if (soilMoisture == null) {
      suggestions.add('Soil moisture is unavailable. Check the field sensor or take a manual soil-moisture reading before deciding to irrigate.');
    } else if (soilMoisture < 30) {
      suggestions.add('The displayed soil-moisture value is low. Check soil conditions and crop requirements; consider irrigation only after field verification.');
    } else if (soilMoisture > 75) {
      suggestions.add('The displayed soil-moisture value is high. Check drainage and avoid unnecessary irrigation.');
    } else {
      suggestions.add('The displayed soil-moisture value is in a moderate range. Continue monitoring and follow the needs of your specific crop.');
    }
    if (soilPH == null) {
      suggestions.add('Soil pH is unavailable. Test the soil before making pH-correction decisions.');
    } else if (soilPH < 5.5) {
      suggestions.add('The displayed soil pH is acidic. Confirm with a soil test and local agricultural guidance before applying amendments.');
    } else if (soilPH > 7.5) {
      suggestions.add('The displayed soil pH is alkaline. Confirm with a soil test and crop-specific guidance before applying amendments.');
    } else {
      suggestions.add('The displayed soil pH is within a commonly suitable range for many crops, but suitability depends on the crop.');
    }
    if (rainfall != null && rainfall >= 5) {
      suggestions.add('NASA estimates recent daily precipitation at ${rainfall.toStringAsFixed(1)} mm. Check field conditions before scheduling irrigation.');
    } else if (rainfall != null) {
      suggestions.add('NASA estimates recent daily precipitation at ${rainfall.toStringAsFixed(1)} mm. This estimate may differ from rainfall at your field.');
    } else {
      suggestions.add('Precipitation data is unavailable. Check a local forecast or rain gauge before irrigation planning.');
    }
    return suggestions.map((suggestion) => Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF246B3B)),
        const SizedBox(width: 10),
        Expanded(child: Text(suggestion, style: const TextStyle(height: 1.4))),
      ])),
    )).toList();
  }

  Widget _comparisonRow(String label, String nasa, String ground, num? difference, String unit) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 8, children: [Text('NASA: $nasa'), Text('Ground demo: $ground')]),
      const SizedBox(height: 6),
      Text(difference == null ? 'Difference: unavailable until both values exist' : 'Ground demo − NASA: ${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(1)} $unit', style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ])),
  );
}
