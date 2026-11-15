import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Responsive crop registration screen. Each crop is stored under farmerCrops.
class AddCropScreen extends StatefulWidget {
  final String farmerFlin;
  final String farmerName;
  final String latitude;
  final String longitude;
  final String soilPH;

  const AddCropScreen({
    super.key,
    required this.farmerFlin,
    required this.farmerName,
    required this.latitude,
    required this.longitude,
    required this.soilPH,
  });

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _varietyController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  String _crop = 'Paddy';
  String _season = 'Kharif';
  String _stage = 'Sowing';
  DateTime? _sowingDate;
  bool _saving = false;

  static const _crops = ['Paddy', 'Chilli', 'Cotton', 'Wheat', 'Maize', 'Groundnut', 'Other'];
  static const _seasons = ['Kharif', 'Rabi', 'Zaid', 'Perennial'];
  static const _stages = ['Sowing', 'Germination', 'Seedling', 'Vegetative', 'Flowering', 'Fruiting', 'Maturity', 'Harvested'];

  @override
  void dispose() {
    _varietyController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validateArea(String? value) {
    final area = double.tryParse((value ?? '').trim());
    if (area == null || !area.isFinite || area <= 0) return 'Enter an area greater than 0 acres';
    if (area > 1000000) return 'Please check the area entered';
    return null;
  }

  Future<void> _chooseSowingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? now,
      firstDate: DateTime(now.year - 15),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select sowing date',
    );
    if (picked != null && mounted) setState(() => _sowingDate = picked);
  }

  Future<void> _saveCrop() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_sowingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select the sowing date.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final doc = FirebaseFirestore.instance.collection('farmerCrops').doc();
      await doc.set({
        'cropId': doc.id,
        'farmerFlin': widget.farmerFlin,
        'farmerName': widget.farmerName,
        'cropName': _crop,
        'variety': _varietyController.text.trim(),
        'areaAcres': double.parse(_areaController.text.trim()),
        'season': _season,
        'sowingDate': Timestamp.fromDate(_sowingDate!),
        'stage': _stage,
        'notes': _notesController.text.trim(),
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'soilPH': widget.soilPH,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': _stage == 'Harvested' ? 'completed' : 'active',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crop saved successfully to DIFMS.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save crop: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Crop')),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 20.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Register a new crop', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Farmer: ${widget.farmerName} • FLIN: ${widget.farmerFlin}', style: const TextStyle(color: Color(0xFFFFD166))),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          value: _crop,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Crop name', prefixIcon: Icon(Icons.grass)),
                          items: _crops.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: _saving ? null : (v) { if (v != null) setState(() => _crop = v); },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(controller: _varietyController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Variety / seed name (optional)', prefixIcon: Icon(Icons.eco))),
                        const SizedBox(height: 14),
                        TextFormField(controller: _areaController, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _validateArea, decoration: const InputDecoration(labelText: 'Area planted (acres)', hintText: 'e.g. 2.5', prefixIcon: Icon(Icons.landscape))),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _season,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Season', prefixIcon: Icon(Icons.calendar_month)),
                          items: _seasons.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: _saving ? null : (v) { if (v != null) setState(() => _season = v); },
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _chooseSowingDate,
                          icon: const Icon(Icons.event),
                          label: Text(_sowingDate == null ? 'Select sowing date *' : 'Sowing date: ${_sowingDate!.day.toString().padLeft(2, '0')}/${_sowingDate!.month.toString().padLeft(2, '0')}/${_sowingDate!.year}'),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _stage,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Initial growth stage', prefixIcon: Icon(Icons.timeline)),
                          items: _stages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: _saving ? null : (v) { if (v != null) setState(() => _stage = v); },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(controller: _notesController, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'Seed source, irrigation plan, etc.', alignLabelWithHint: true)),
                      ]))),
                      const SizedBox(height: 14),
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveCrop,
                        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                        label: Text(_saving ? 'Saving crop…' : 'Save Crop'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      )),
                      const SizedBox(height: 8),
                      const Text('Crop details are saved in Firebase Firestore. Variety and notes are optional; area and sowing date are required.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFFFFD166))),
                    ]),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
