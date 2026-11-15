import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Cloudinary unsigned image upload configuration. Never add your API secret here.
const String _cloudinaryCloudName = 'jk0lr1qx';
const String _cloudinaryUploadPreset = 'difms_crop_upload';

Future<String> _uploadToCloudinary(XFile photo) async {
  final uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
  );
  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = _cloudinaryUploadPreset
    ..fields['folder'] = 'difms/crop_photos'
    ..files.add(await http.MultipartFile.fromPath('file', photo.path));

  final streamedResponse = await request.send().timeout(
    const Duration(seconds: 90),
  );
  final response = await http.Response.fromStream(streamedResponse);
  Map<String, dynamic> result;
  try {
    result = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Cloudinary returned an unreadable response.');
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final error = result['error'];
    final message = error is Map ? error['message'] : null;
    throw Exception(message?.toString() ??
        'Cloudinary upload failed (HTTP ${response.statusCode}). Check the cloud name and unsigned preset.');
  }

  final secureUrl = result['secure_url']?.toString();
  if (secureUrl == null || secureUrl.isEmpty) {
    throw Exception('Cloudinary did not return an image URL.');
  }
  return secureUrl;
}

/// DIFMS crop marketplace: sellers publish crop lots and buyers submit offers.
class MarketplaceScreen extends StatelessWidget {
  final String farmerName;
  final String flin;
  final String latitude;
  final String longitude;

  const MarketplaceScreen({
    super.key,
    required this.farmerName,
    required this.flin,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DIFMS Market',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF246B3B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final compact = width < 360;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 20,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: compact ? 4 : 16),
                      Icon(
                        Icons.storefront,
                        size: compact ? 56 : 72,
                        color: const Color(0xFF246B3B),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome to the Crop Market',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 22 : 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose how you want to use the market, $farmerName.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: compact ? 15 : 17),
                      ),
                      SizedBox(height: compact ? 20 : 28),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: compact ? 4 : 8,
                          ),
                          minLeadingWidth: compact ? 44 : 52,
                          leading: CircleAvatar(
                            radius: compact ? 22 : 27,
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.agriculture,
                              size: compact ? 23 : 28,
                              color: Colors.green.shade900,
                            ),
                          ),
                          title: Text(
                            'Enter as Seller',
                            style: TextStyle(
                              fontSize: compact ? 17 : 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'List your crop, add photos and receive buyer offers.',
                            style: TextStyle(fontSize: compact ? 13 : 15),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _SellerPage(
                                farmerName: farmerName,
                                flin: flin,
                                latitude: latitude,
                                longitude: longitude,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: compact ? 4 : 8,
                          ),
                          minLeadingWidth: compact ? 44 : 52,
                          leading: CircleAvatar(
                            radius: compact ? 22 : 27,
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.shopping_basket,
                              size: compact ? 23 : 28,
                              color: Colors.green.shade900,
                            ),
                          ),
                          title: Text(
                            'Enter as Buyer',
                            style: TextStyle(
                              fontSize: compact ? 17 : 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Browse crops and submit your best price offer.',
                            style: TextStyle(fontSize: compact ? 13 : 15),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _BuyerPage(
                                buyerName: farmerName,
                                buyerFlin: flin,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Agree on quality, quantity, delivery and payment terms '
                        'directly before completing a trade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFD166),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SellerPage extends StatefulWidget {
  final String farmerName, flin, latitude, longitude;
  const _SellerPage({required this.farmerName, required this.flin, required this.latitude, required this.longitude});
  @override
  State<_SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<_SellerPage> {
  final _formKey = GlobalKey<FormState>();
  final _crop = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _quality = TextEditingController();
  final _harvest = TextEditingController();
  final _description = TextEditingController();
  final List<XFile> _photos = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_crop, _quantity, _unit, _price, _location, _quality, _harvest, _description]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 80, limit: 5);
      if (!mounted) return;
      setState(() {
        _photos
          ..clear()
          ..addAll(picked.take(5));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not select photos: $e')));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one crop photo.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final doc = FirebaseFirestore.instance.collection('marketListings').doc();
      final urls = <String>[];
      for (final photo in _photos) {
        urls.add(await _uploadToCloudinary(photo));
      }
      await doc.set({
        'listingId': doc.id,
        'sellerName': widget.farmerName,
        'sellerFlin': widget.flin,
        'cropName': _crop.text.trim(),
        'quantity': double.parse(_quantity.text.trim()),
        'unit': _unit.text.trim(),
        'askingPricePerUnit': double.parse(_price.text.trim()),
        'location': _location.text.trim(),
        'quality': _quality.text.trim(),
        'harvestDate': _harvest.text.trim(),
        'description': _description.text.trim(),
        'photoUrls': urls,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crop listed successfully. Buyers can now make offers.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not publish listing: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
  String? _positive(String? value) {
    final n = double.tryParse((value ?? '').trim());
    return n == null || n <= 0 ? 'Enter a number greater than zero' : null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sell Your Crop')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Crop listing details', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      TextFormField(controller: _crop, decoration: const InputDecoration(labelText: 'Crop name (e.g. paddy, chilli)'), validator: _required),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: TextFormField(controller: _quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantity'), validator: _positive)), const SizedBox(width: 10), Expanded(child: TextFormField(controller: _unit, decoration: const InputDecoration(labelText: 'Unit (kg, quintal)'), validator: _required))]),
      const SizedBox(height: 12),
      TextFormField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Asking price per unit (₹)'), validator: _positive),
      const SizedBox(height: 12),
      TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Market / village / delivery location'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: _quality, decoration: const InputDecoration(labelText: 'Quality / grade (e.g. moisture, grade)'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: _harvest, decoration: const InputDecoration(labelText: 'Harvest date (optional, e.g. 2026-10-20)')),
      const SizedBox(height: 12),
      TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Crop details, packaging and delivery notes')),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: _saving ? null : _pickPhotos, icon: const Icon(Icons.add_a_photo), label: Text('Add crop photos (${_photos.length}/5)')),
      if (_photos.isNotEmpty) ...[
        const SizedBox(height: 8),
        SizedBox(height: 105, child: ListView(scrollDirection: Axis.horizontal, children: _photos.map((p) => Padding(padding: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p.path), width: 105, height: 105, fit: BoxFit.cover)))).toList())),
      ],
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _saving ? null : _publish, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.publish), label: Text(_saving ? 'Publishing listing…' : 'Publish Crop for Sale')),
      const SizedBox(height: 8),
      const Text('Your photos are uploaded to Cloudinary; listing details and photo URLs are saved in Firestore.', style: TextStyle(fontSize: 12, color: Color(0xFFFFD166))),
    ])),
  );
}

class _BuyerPage extends StatefulWidget {
  final String buyerName, buyerFlin;
  const _BuyerPage({required this.buyerName, required this.buyerFlin});
  @override
  State<_BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<_BuyerPage> {
  final _search = TextEditingController();
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _makeOffer(QueryDocumentSnapshot<Map<String, dynamic>> listing) async {
    final data = listing.data();
    final price = TextEditingController();
    final quantity = TextEditingController(text: (data['quantity'] ?? '').toString());
    final message = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Offer for ${data['cropName'] ?? 'crop'}'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Seller asking ₹${data['askingPricePerUnit']} per ${data['unit']}. Enter your best price.'),
        const SizedBox(height: 12),
        TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Your offer per unit (₹)'), validator: (v) { final n = double.tryParse((v ?? '').trim()); return n == null || n <= 0 ? 'Enter a valid price' : null; }),
        const SizedBox(height: 10),
        TextFormField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Quantity (${data['unit']})'), validator: (v) { final n = double.tryParse((v ?? '').trim()); return n == null || n <= 0 ? 'Enter a valid quantity' : null; }),
        const SizedBox(height: 10),
        TextFormField(controller: message, maxLines: 2, decoration: const InputDecoration(labelText: 'Message / delivery proposal (optional)')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), ElevatedButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Send offer'))],
    ));
    if (accepted == true) {
      try {
        await listing.reference.collection('offers').add({
          'buyerName': widget.buyerName,
          'buyerFlin': widget.buyerFlin,
          'offerPricePerUnit': double.parse(price.text.trim()),
          'quantity': double.parse(quantity.text.trim()),
          'message': message.text.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent to seller.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send offer: $e')));
      }
    }
    price.dispose(); quantity.dispose(); message.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('DIFMS Crop Market'),
          actions: [
            IconButton(
              tooltip: 'Refresh listings',
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search paddy, chilli, village...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Row(
                children: [
                  Icon(Icons.local_florist, color: Color(0xFF246B3B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fresh crops from farmers',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // Read the collection without an orderBy composite index requirement.
                stream: FirebaseFirestore.instance
                    .collection('marketListings')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Could not load listings from Firestore.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final query = _search.text.trim().toLowerCase();
                  final listings = snapshot.data!.docs.where((doc) {
                    final d = doc.data();
                    // Only show active listings; tolerate case/space differences.
                    final status = (d['status'] ?? 'active')
                        .toString()
                        .trim()
                        .toLowerCase();
                    final searchable =
                        '${d['cropName'] ?? ''} ${d['location'] ?? ''} '
                        '${d['quality'] ?? ''} ${d['description'] ?? ''} '
                        '${d['sellerName'] ?? ''}'.toLowerCase();
                    return status == 'active' && searchable.contains(query);
                  }).toList();

                  // Sort newest first on the device so a composite index isn't needed.
                  listings.sort((a, b) {
                    final av = a.data()['createdAt'];
                    final bv = b.data()['createdAt'];
                    final ad = av is Timestamp ? av.toDate() : DateTime(2000);
                    final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);
                    return bd.compareTo(ad);
                  });

                  if (listings.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await FirebaseFirestore.instance
                            .collection('marketListings')
                            .get(const GetOptions(source: Source.server));
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 70),
                          Icon(Icons.storefront_outlined,
                              size: 76, color: Colors.grey.shade500),
                          const SizedBox(height: 14),
                          const Center(
                            child: Text(
                              'No active crops found',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'When a seller publishes a crop, it will appear here. '
                              'Clear the search if you are looking for a different crop.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final width = MediaQuery.sizeOf(context).width;
                  // One full-width card on phones prevents narrow text and button overflow.
                  // More columns are introduced only when there is enough horizontal room.
                  final columns = width < 520
                      ? 1
                      : width < 800
                          ? 2
                          : width < 1200
                              ? 3
                              : 4;
                  final tileHeight = width < 520
                      ? 390.0
                      : width < 800
                          ? 390.0
                          : 420.0;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: listings.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: tileHeight,
                    ),
                    itemBuilder: (context, index) {
                      final doc = listings[index];
                      final d = doc.data();
                      final photos = (d['photoUrls'] as List?)
                              ?.whereType<String>()
                              .toList() ??
                          <String>[];
                      final cropName = (d['cropName'] ?? 'Crop').toString();
                      final unit = (d['unit'] ?? '').toString();
                      final quantity = (d['quantity'] ?? '?').toString();
                      final isOwnListing = d['sellerFlin'] == widget.buyerFlin;

                      return Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: photos.isEmpty
                                  ? Container(
                                      color: Colors.green.shade50,
                                      child: const Icon(Icons.agriculture,
                                          size: 54, color: Color(0xFF246B3B)),
                                    )
                                  : PageView.builder(
                                      itemCount: photos.length,
                                      itemBuilder: (context, photoIndex) =>
                                          Image.network(
                                        photos[photoIndex],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        },
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.green.shade50,
                                          child: const Icon(
                                              Icons.broken_image_outlined,
                                              size: 48),
                                        ),
                                      ),
                                    ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cropName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${d['askingPricePerUnit'] ?? '?'} / $unit',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF246B3B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Available: $quantity $unit',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            (d['location'] ??
                                                    'Location not provided')
                                                .toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFFFD166)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 7, horizontal: 8),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: isOwnListing
                                            ? null
                                            : () => _makeOffer(doc),
                                        child: Text(
                                          isOwnListing ? 'Your listing' : 'Make offer',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}
