import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GovernmentFarmerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> farmer;
  const GovernmentFarmerDetailScreen({super.key, required this.farmer});

  String _text(dynamic value, [String fallback = 'Not recorded']) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final flin = _text(farmer['flin'], '');
    return Scaffold(
      appBar: AppBar(title: Text('Farmer · $flin', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_text(farmer['name']), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), Text('FLIN: $flin', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          _row('Mobile', farmer['mobile']), _row('State', farmer['state']), _row('District', farmer['district']), _row('Village', farmer['village']), _row('Survey number', farmer['surveyNumber']), _row('Land area', farmer['landArea']), _row('Field area (acres)', farmer['fieldAreaAcres']), _row('Soil pH', farmer['soilPH']), _row('Latitude', farmer['latitude']), _row('Longitude', farmer['longitude']),
        ]))),
        const SizedBox(height: 12),
        Text('Registered crops', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (flin.isEmpty) const Text('This farmer record has no FLIN value.'),
        if (flin.isNotEmpty) StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('farmerCrops').where('farmerFlin', isEqualTo: flin).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _error('Could not load crop records. ${snapshot.error}');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No crop records found for this FLIN. Check that crop records store farmerFlin.')));
            return Column(children: snapshot.data!.docs.map((doc) {
              final crop = doc.data();
              final cropName = _text(crop['cropName'], _text(crop['name'], 'Crop'));
              return Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
                leading: const Icon(Icons.grass, color: Color(0xFF246B3B)),
                title: Text(cropName),
                subtitle: Text('Stage: ${_text(crop['stage'], 'Not recorded')} · Area: ${_text(crop['areaAcres'], _text(crop['area']))} acres'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _row('Variety', crop['variety']), _row('Season', crop['season']), _row('Sowing date', _date(crop['sowingDate'])), _row('Crop notes', crop['notes']),
                  const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(top: 10, bottom: 6), child: Text('Weekly crop reports', style: TextStyle(fontWeight: FontWeight.bold)))),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: doc.reference.collection('weeklyReports').orderBy('reportDate', descending: true).snapshots(),
                    builder: (context, reports) {
                      if (reports.hasError) return Text('Could not load weekly reports: ${reports.error}');
                      if (!reports.hasData) return const LinearProgressIndicator();
                      if (reports.data!.docs.isEmpty) return const Align(alignment: Alignment.centerLeft, child: Text('No weekly reports submitted yet.'));
                      return Column(children: reports.data!.docs.map((r) {
                        final data = r.data();
                        final urls = (data['photoUrls'] as List?)?.whereType<String>().toList() ?? <String>[];
                        return Card(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Report date: ${_date(data['reportDate'])}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          if ((data['observations'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Observation: ${data['observations']}')),
                          if ((data['irrigation'] ?? '').toString().isNotEmpty) Text('Irrigation: ${data['irrigation']}'),
                          if ((data['fertilizer'] ?? '').toString().isNotEmpty) Text('Fertilizer: ${data['fertilizer']}'),
                          if ((data['pestObservations'] ?? '').toString().isNotEmpty) Text('Pest observations: ${data['pestObservations']}'),
                          if (urls.isNotEmpty) SizedBox(height: 118, child: ListView(scrollDirection: Axis.horizontal, children: urls.map((url) => Padding(padding: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: 118, height: 118, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 118, child: Icon(Icons.broken_image)))))).toList())),
                        ])));
                      }).toList());
                    },
                  ),
                ],
              ));
            }).toList());
          },
        ),
      ]),
    );
  }

  static Widget _error(String text) => Padding(padding: const EdgeInsets.all(12), child: Text(text));
  static Widget _row(String label, dynamic value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 132, child: Text(label, style: const TextStyle(color: Color(0xFFFFD166)))), Expanded(child: Text(_display(value), style: const TextStyle(fontWeight: FontWeight.w500)))]));
  static String _display(dynamic value) => value == null || value.toString().trim().isEmpty ? 'Not recorded' : value.toString();
  static String _date(dynamic value) { if (value is Timestamp) return value.toDate().toLocal().toString().split(' ').first; if (value is DateTime) return value.toLocal().toString().split(' ').first; return _display(value); }
}
