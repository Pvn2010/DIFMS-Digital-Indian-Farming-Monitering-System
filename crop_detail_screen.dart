import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'crop_overall_data_screen.dart';

/// Crop-specific overview. Photo reports are stored in DIFMS; actual submission
/// to a government portal is not claimed because no official endpoint is configured.
class CropDetailScreen extends StatefulWidget {
  final String cropId;
  final Map<String, dynamic> crop;
  final String farmerFlin;

  const CropDetailScreen({super.key, required this.cropId, required this.crop, required this.farmerFlin});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  static const _cloudName = 'jk0lr1qx';
  static const _uploadPreset = 'difms_crop_upload';
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  final _observation = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  String _str(String key, [String fallback = 'Not recorded']) {
    final value = widget.crop[key];
    return value == null || value.toString().trim().isEmpty ? fallback : value.toString();
  }

  List<String> _suggestions() {
    final name = _str('cropName', 'Crop').toLowerCase();
    final stage = _str('stage', 'Sowing').toLowerCase();
    final common = <String>[
      'Compare the latest field observations with local weather and soil conditions before changing irrigation or inputs.',
      'Record irrigation, fertilizer use, pest symptoms, and a dated photo in each weekly update.',
      'Use soil-test results and local agricultural-extension guidance before applying fertilizer or pesticide.',
    ];
    if (stage.contains('sow') || stage.contains('germ')) {
      common.insert(0, 'Check seedling establishment and field moisture regularly; avoid waterlogging unless the crop system requires it.');
    } else if (stage.contains('flower') || stage.contains('fruit')) {
      common.insert(0, 'Inspect flowering/fruiting plants frequently for water stress and pest or disease symptoms.');
    } else if (stage.contains('matur')) {
      common.insert(0, 'Monitor maturity and plan harvest based on crop-specific signs and local agricultural advice.');
    }
    if (name.contains('paddy') || name.contains('rice')) {
      common.add('For paddy, manage water according to the variety, growth stage, soil, and local extension recommendations; avoid relying on demo readings alone.');
    } else if (name.contains('chilli')) {
      common.add('For chilli, scout for thrips, mites, and fruit damage; confirm any suspected pest before treatment.');
    } else if (name.contains('cotton')) {
      common.add('For cotton, scout regularly for sucking pests and boll damage, and follow integrated pest-management guidance.');
    }
    return common;
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
      if (picked.isNotEmpty && mounted) setState(() => _photos.addAll(picked));
    } catch (e) {
      if (mounted) _message('Could not select photos: $e');
    }
  }

  Future<String> _uploadPhoto(XFile photo) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'difms/crop_reports/${widget.cropId}'
      ..files.add(await http.MultipartFile.fromPath('file', photo.path));
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (streamed.statusCode < 200 || streamed.statusCode >= 300 || data['secure_url'] == null) {
      throw Exception('Photo upload failed (${streamed.statusCode}). Check Cloudinary unsigned preset.');
    }
    return data['secure_url'].toString();
  }

  Future<void> _prepareReport() async {
    if (_photos.isEmpty) {
      _message('Please add at least one crop photo first.');
      return;
    }
    setState(() => _saving = true);
    try {
      final urls = <String>[];
      for (final photo in _photos) {
        urls.add(await _uploadPhoto(photo));
      }
      await FirebaseFirestore.instance.collection('farmerCrops').doc(widget.cropId).collection('weeklyReports').add({
        'farmerFlin': widget.farmerFlin,
        'cropId': widget.cropId,
        'cropName': _str('cropName', 'Crop'),
        'reportDate': FieldValue.serverTimestamp(),
        'photoUrls': urls,
        'observations': _observation.text.trim(),
        'stage': _str('stage', 'Sowing'),
        'latitude': widget.crop['latitude'],
        'longitude': widget.crop['longitude'],
        'submissionStatus': 'Prepared in DIFMS — not submitted to a government portal',
        'governmentPortalConfigured': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() { _photos.clear(); _observation.clear(); _saving = false; });
      _message('Crop report and photos saved in DIFMS. Government submission is not connected; use the official portal to submit.');
    } catch (e) {
      if (mounted) { setState(() => _saving = false); _message('Could not prepare crop report: $e'); }
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final cropName = _str('cropName', 'Crop');
    final lat = _str('latitude', '');
    final lon = _str('longitude', '');
    return Scaffold(
      appBar: AppBar(title: Text(cropName, overflow: TextOverflow.ellipsis)),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 760 ? 760.0 : constraints.maxWidth;
        return Align(alignment: Alignment.topCenter, child: SizedBox(width: maxWidth, child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$cropName overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detail('Variety', _str('variety', 'Not specified')),
            _detail('Area planted', '${_str('areaAcres', '?')} acres'),
            _detail('Season', _str('season')),
            _detail('Growth stage', _str('stage', 'Sowing')),
            _detail('Sowing date', _date(widget.crop['sowingDate'])),
            _detail('Soil pH at registration', _str('soilPH')),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('NASA and ground-level comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Open the comparison to fetch NASA POWER weather estimates for this crop’s field coordinates and compare them with the latest saved ground reading. Ground readings are simulated until Arduino sensors are connected.'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CropOverallDataScreen(
                farmerFlin: widget.farmerFlin,
                farmerName: _str('farmerName', 'Farmer'),
                latitude: lat,
                longitude: lon,
              ))),
              icon: const Icon(Icons.compare_arrows), label: const Text('Compare NASA and ground data'),
            )),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Suggestions for this crop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._suggestions().map((s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(s))]))),
            const Text('Suggestions are general guidance, not a diagnosis. Confirm local actions with an agricultural extension officer.', style: TextStyle(fontSize: 12, color: Color(0xFFFFD166))),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Weekly crop photos and government report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Add dated crop photos and observations. DIFMS can save a report, but actual submission requires integration with the relevant official government portal or API.'),
            const SizedBox(height: 12),
            TextField(controller: _observation, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Weekly observations', hintText: 'Growth, irrigation, pests, fertilizer, etc.', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _saving ? null : _pickPhotos, icon: const Icon(Icons.add_photo_alternate), label: Text('Choose crop photos (${_photos.length})')),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(height: 100, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _photos.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_photos[i].path), width: 100, height: 100, fit: BoxFit.cover)))),
            ],
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _saving ? null : _prepareReport, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.assignment_turned_in_outlined), label: Text(_saving ? 'Saving report…' : 'Save report / prepare for government submission'))),
          ]))),
        ])));
      })),
    );
  }

  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: Text(label, style: const TextStyle(color: Color(0xFFFFD166)))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));

  String _date(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return 'Not recorded';
  }
}
