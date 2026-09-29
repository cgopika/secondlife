import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaterialHistoryScreen extends StatelessWidget {
  const MaterialHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: Text('Please log in to view your history.')),
      );
    }

    final query = FirebaseFirestore.instance.collection('items').where('ownerId', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text("Couldn't load your materials."),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () => (query.get()), child: const Text('Try again')),
                    const SizedBox(height: 6),
                    Text(snapshot.error.toString(), style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                  ]),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No materials yet\nMaterials you list will appear here.', textAlign: TextAlign.center),
                ),
              );
            }

            // convert docs to typed map and sort by createdAt (serverTimestamp may be null briefly)
            final listings = docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {
                'id': d.id,
                'title': (data['title'] ?? data['name']) ?? 'Untitled',
                'quantity': data['quantity'],
                'unit': data['unit'] ?? '',
                'category': data['category'] ?? '',
                'condition': data['condition'] ?? '',
                'price': data['price'],
                'isPaid': data['isPaid'] ?? false,
                'location': data['location'] ?? '',
                'status': data['status'] ?? 'available',
                'createdAt': data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null,
                'imageUrls': (data['imageUrls'] as List?) ?? [],
                'raw': data,
              };
            }).toList();

            listings.sort((a, b) {
              final da = a['createdAt'] as DateTime?;
              final db = b['createdAt'] as DateTime?;
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return db.compareTo(da);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: listings.length,
              itemBuilder: (context, i) {
                final listing = listings[i];
                final title = listing['title'] as String? ?? 'Untitled';
                final qty = listing['quantity']?.toString() ?? '-';
                final unit = listing['unit'] ?? '';
                final category = listing['category'] ?? '';
                final condition = listing['condition'] ?? '';
                final price = listing['price'];
                final isPaid = listing['isPaid'] ?? false;
                final location = listing['location'] ?? '';
                final status = listing['status'] ?? 'available';
                final created = listing['createdAt'] as DateTime?;
                final imageUrls = (listing['imageUrls'] as List).cast<String>();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialDetailScreen(listing: listing['raw'] ?? {})));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                            child: imageUrls.isNotEmpty
                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrls[0], fit: BoxFit.cover))
                                : const Icon(Icons.image, size: 42, color: Color(0xFF2F6B4F)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text('$qty ${unit.isNotEmpty ? unit : ''} · $category', style: const TextStyle(color: Color(0xFF69756D))),
                                const SizedBox(height: 6),
                                Text(condition, style: const TextStyle(color: Color(0xFF69756D))),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Text(isPaid ? '₹${price ?? '-'}' : 'FREE', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF2F6B4F)),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(location, style: const TextStyle(color: Color(0xFF69756D)), overflow: TextOverflow.ellipsis)),
                                ])
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(status, style: const TextStyle(color: Color(0xFF2F6B4F), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              if (created != null) Text('Listed ${_shortDate(created)}', style: const TextStyle(color: Color(0xFF69756D), fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _shortDate(DateTime d) {
    return '${d.day} ${_monthName(d.month)} ${d.year}';
  }

  static String _monthName(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m-1];
  }
}

class MaterialDetailScreen extends StatelessWidget {
  final Map<String, dynamic> listing;
  const MaterialDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final imageUrls = (listing['imageUrls'] as List?) ?? [];
    final title = listing['title'] ?? listing['name'] ?? 'Untitled';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imageUrls.isNotEmpty) Image.network(imageUrls[0], height: 220, width: double.infinity, fit: BoxFit.cover) else Container(height:220, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size: 64, color: Color(0xFF2F6B4F)))),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(listing['category'] ?? '', style: const TextStyle(color: Color(0xFF2F6B4F), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Location: ${listing['location'] ?? ''}'),
          const SizedBox(height: 8),
          Text('Condition: ${listing['condition'] ?? ''}'),
          const SizedBox(height: 12),
          Text(listing['description'] ?? ''),
        ]),
      ),
    );
  }
}
