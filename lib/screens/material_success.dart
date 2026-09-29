import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialSuccessScreen extends StatelessWidget {
  final String listingId;

  const MaterialSuccessScreen({super.key, required this.listingId});

  Future<Map<String, dynamic>?> _fetchListing() async {
    final doc = await FirebaseFirestore.instance.collection('items').doc(listingId).get();
    if (!doc.exists) return null;
    final data = doc.data()! as Map<String, dynamic>;
    return {
      'id': doc.id,
      'title': data['title'] ?? data['name'] ?? 'Untitled',
      'category': data['category'] ?? '',
      'location': data['location'] ?? '',
      'condition': data['condition'] ?? '',
      'description': data['description'] ?? '',
      'imageUrls': (data['imageUrls'] as List?) ?? [],
      'status': data['status'] ?? 'available',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline, size: 88, color: Color(0xFF2F6B4F)),
            const SizedBox(height: 18),
            const Text('Material Listed Successfully', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Your material is now available on SecondLife.'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () async {
                final listing = await _fetchListing();
                if (listing == null) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(listing['title'])),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if ((listing['imageUrls'] as List).isNotEmpty) Image.network(listing['imageUrls'][0], height: 220, width: double.infinity, fit: BoxFit.cover),
                      const SizedBox(height: 12),
                      Text(listing['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(listing['category'], style: const TextStyle(color: Color(0xFF3B6B52), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text('Location: ${listing['location']}'),
                      const SizedBox(height: 8),
                      Text('Condition: ${listing['condition']}'),
                      const SizedBox(height: 12),
                      Text(listing['description'] ?? ''),
                    ]),
                  ),
                )));
              }, child: const Text('View My Listing')),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Go Home'))),
          ]),
        ),
      ),
    );
  }
}
