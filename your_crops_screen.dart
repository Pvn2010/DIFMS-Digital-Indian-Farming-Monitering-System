import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'crop_detail_screen.dart';

/// Responsive list of the signed-in farmer's saved crop records.
class YourCropsScreen extends StatelessWidget {
  final String farmerFlin;
  const YourCropsScreen({super.key, required this.farmerFlin});

  static const _stages = ['Sowing', 'Germination', 'Seedling', 'Vegetative', 'Flowering', 'Fruiting', 'Maturity', 'Harvested'];

  Future<void> _updateStage(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc, String stage) async {
    try {
      await doc.reference.update({
        'stage': stage,
        'status': stage == 'Harvested' ? 'completed' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crop stage updated.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update crop: $e')));
    }
  }

  String _dateText(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return 'Not recorded';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Crops')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('farmerCrops').where('farmerFlin', isEqualTo: farmerFlin).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load crops. Check Firestore rules and connection.\n${snapshot.error}', textAlign: TextAlign.center)));
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs.toList() ?? [];
            docs.sort((a, b) {
              final av = a.data()['createdAt']; final bv = b.data()['createdAt'];
              final ad = av is Timestamp ? av.toDate() : DateTime(2000);
              final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);
              return bd.compareTo(ad);
            });
            if (docs.isEmpty) {
              return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.grass, size: 72, color: Colors.green.shade700),
                const SizedBox(height: 12),
                const Text('No crops registered yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Use Add Crop from the dashboard to register your first crop.', textAlign: TextAlign.center),
              ])));
            }
            return LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1050 ? 3 : width >= 680 ? 2 : 1;
              if (columns == 1) {
                return ListView.builder(padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (context, i) => _CropCard(doc: docs[i], stages: _stages, dateText: _dateText, onStageChanged: (stage) => _updateStage(context, docs[i], stage), onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CropDetailScreen(cropId: docs[i].id, crop: docs[i].data(), farmerFlin: farmerFlin)))));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: width >= 1050 ? 1.15 : 1.0),
                itemBuilder: (context, i) => _CropCard(doc: docs[i], stages: _stages, dateText: _dateText, onStageChanged: (stage) => _updateStage(context, docs[i], stage), onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CropDetailScreen(cropId: docs[i].id, crop: docs[i].data(), farmerFlin: farmerFlin)))),
              );
            });
          },
        ),
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final List<String> stages;
  final String Function(dynamic) dateText;
  final ValueChanged<String> onStageChanged;
  final VoidCallback onOpen;
  const _CropCard({required this.doc, required this.stages, required this.dateText, required this.onStageChanged, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() ?? <String, dynamic>{};
    final stage = stages.contains(d['stage']) ? d['stage'] as String : 'Sowing';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: Colors.green.shade50, child: Icon(Icons.grass, color: Colors.green.shade800)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((d['cropName'] ?? 'Crop').toString(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            Text('${d['season'] ?? 'Season not set'} • ${d['areaAcres'] ?? '?'} acres', style: const TextStyle(color: Color(0xFFFFD166))),
          ])),
        ]),
        const SizedBox(height: 12),
        if ((d['variety'] ?? '').toString().trim().isNotEmpty) Text('Variety: ${d['variety']}'),
        Text('Sowing date: ${dateText(d['sowingDate'])}'),
        if ((d['soilPH'] ?? '').toString().trim().isNotEmpty) Text('Registered soil pH: ${d['soilPH']}'),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onOpen, icon: const Icon(Icons.analytics_outlined), label: const Text('View crop overall data'))),
        const SizedBox(height: 8),
        const Text('Growth stage', style: TextStyle(fontWeight: FontWeight.w600)),
        DropdownButtonFormField<String>(
          value: stage,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) { if (v != null && v != stage) onStageChanged(v); },
        ),
        if ((d['notes'] ?? '').toString().trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(d['notes'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ])),
    );
  }
}
