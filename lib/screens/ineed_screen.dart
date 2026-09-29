import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'material_tracking.dart';
import 'payment_screen.dart';

// Request Tracking screen for requester
class RequestTrackingScreen extends StatelessWidget {
  const RequestTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold(appBar: AppBar(title: const Text('Request Tracking')), body: const Center(child: Text('Please log in to view your requests.')));
    final query = FirebaseFirestore.instance.collection('exchange_requests').where('requesterId', isEqualTo: user.uid).orderBy('createdAt', descending: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Request Tracking')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No requests yet\nRequests you send will appear here.', textAlign: TextAlign.center)));
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final status = (data['status'] ?? 'pending').toString().toLowerCase();
              final price = data['price'];
              final createdAt = data['createdAt'];
              final requestedDate = createdAt is Timestamp ? MaterialLocalizations.of(context).formatMediumDate(createdAt.toDate()) : 'Date pending';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['itemName'] ?? data['materialName'] ?? 'Material', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Owner: ${data['ownerId'] ?? ''}'),
                    const SizedBox(height: 6),
                    Text('Quantity: ${data['quantity'] ?? '-'}'),
                    const SizedBox(height: 6),
                    Text('Price: ${price == null || (price is num && price == 0) ? 'FREE' : '₹$price'}'),
                    const SizedBox(height: 6),
                    Text('Requested: $requestedDate'),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(status[0].toUpperCase() + status.substring(1), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2F6B4F))),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: d.id))), child: const Text('View')),
                    ])
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class INeedScreen extends StatefulWidget {
  const INeedScreen({super.key});

  @override
  State<INeedScreen> createState() => _INeedScreenState();
}

class _INeedScreenState extends State<INeedScreen> {
  String _query = '';
  String _sort = 'lowest'; // lowest, highest, newest

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final stream = FirebaseFirestore.instance.collection('items').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('I Need'), leading: BackButton(onPressed: () => Navigator.pop(context)), bottom: PreferredSize(preferredSize: const Size.fromHeight(26), child: Padding(padding: const EdgeInsets.only(bottom:12.0), child: Text('Find something useful near you.', style: TextStyle(color: Colors.grey[700]))),),),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'Search materials...', suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _query = '')) : null, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'lowest', child: Text('Lowest Price')),
                  PopupMenuItem(value: 'highest', child: Text('Highest Price')),
                  PopupMenuItem(value: 'newest', child: Text('Newest')),
                ],
                child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.sort_rounded)),
              )
            ]),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16, vertical:6),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestTrackingScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Request Tracking', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height:4), Text('Track your requests', style: TextStyle(color: Color(0xFF69756D))) ]),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2F6B4F))
                ]),
              ),
            ),
          ),

          const Padding(padding: EdgeInsets.symmetric(horizontal:16, vertical:6), child: Row(children: [Expanded(child: Text('Available Items', style: TextStyle(fontWeight: FontWeight.w800))), SizedBox(width:8), Text('Sort:')]),),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Couldn\'t load materials: ${snap.error}'));

                final docs = snap.data?.docs ?? [];

                // convert and filter
                final items = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return {
                    'id': d.id,
                    'title': (data['title'] ?? data['name']) ?? 'Untitled',
                    'category': data['category'] ?? '',
                    'quantity': data['quantity'] ?? 1,
                    'unit': data['unit'] ?? '',
                    'condition': data['condition'] ?? '',
                    'price': data['price'],
                    'isPaid': data['isPaid'] ?? false,
                    'location': data['location'] ?? '',
                    'ownerId': data['ownerId']?.toString() ?? '',
                    'status': (data['status'] ?? '').toString(),
                    'imageUrls': (data['imageUrls'] as List?) ?? [],
                    'description': data['description'] ?? '',
                    'raw': data,
                  };
                }).where((it) {
                  final statusRaw = (it['status'] ?? '').toString().toLowerCase();
                  if (statusRaw != 'available') return false;
                  final ownerId = (it['ownerId'] ?? '').toString();
                  if (currentUserId != null && ownerId == currentUserId) return false;
                  // basic search across title/category/description
                  if (_query.isEmpty) return true;
                  final q = _query.toLowerCase();
                  return (it['title'] as String).toLowerCase().contains(q) || (it['category'] as String).toLowerCase().contains(q) || (it['description'] as String).toLowerCase().contains(q);
                }).toList();

                if (items.isEmpty) {
                  // distinguish no items vs no search results
                  if (_query.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No materials available right now.\nCheck back later or try another search.', textAlign: TextAlign.center)));
                  }
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No matching materials found.\nTry a different material or category.', textAlign: TextAlign.center)));
                }

                // price normalization
                for (var it in items) {
                  final isPaid = it['isPaid'] ?? false;
                  final p = it['price'];
                  double priceVal = 0;
                  if (isPaid) {
                    if (p is num) priceVal = p.toDouble();
                    else if (p is String) priceVal = double.tryParse(p.replaceAll(RegExp('[^0-9.]'), '')) ?? double.infinity;
                    else priceVal = double.infinity;
                  } else {
                    priceVal = 0;
                  }
                  it['_priceVal'] = priceVal;
                }

                if (_sort == 'lowest') items.sort((a, b) => (a['_priceVal'] as double).compareTo(b['_priceVal'] as double));
                else if (_sort == 'highest') items.sort((a, b) => (b['_priceVal'] as double).compareTo(a['_priceVal'] as double));
                else if (_sort == 'newest') items.sort((a, b) { final da = (a['raw']['createdAt'] as Timestamp?)?.toDate(); final db = (b['raw']['createdAt'] as Timestamp?)?.toDate(); if (da==null && db==null) return 0; if (da==null) return 1; if (db==null) return -1; return db.compareTo(da);} );

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final imageUrls = (it['imageUrls'] as List).cast<String>();
                    final title = it['title'] as String;
                    final category = it['category'] as String;
                    final qty = it['quantity']?.toString() ?? '-';
                    final unit = it['unit'] ?? '';
                    final condition = it['condition'] ?? '';
                    final priceVal = it['_priceVal'] as double;
                    final priceText = priceVal == 0 ? 'FREE' : '₹${priceVal.toStringAsFixed(priceVal.truncateToDouble() == priceVal ? 0 : 2)}';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialDetailForNeed(listing: it))),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(children: [
                            Container(width: 84, height: 84, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: imageUrls.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrls[0], fit: BoxFit.cover)) : const Icon(Icons.image, size: 42, color: Color(0xFF2F6B4F))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height:6), Text(category, style: const TextStyle(color: Color(0xFF69756D))), const SizedBox(height:6), Text('$qty ${unit.isNotEmpty ? unit : ''} · $condition', style: const TextStyle(color: Color(0xFF69756D))), const SizedBox(height:6), Row(children: [Text(priceText, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width:8), const Icon(Icons.location_on_outlined, size:14, color: Color(0xFF2F6B4F)), const SizedBox(width:4), Expanded(child: Text(it['location'] ?? '', style: const TextStyle(color: Color(0xFF69756D)), overflow: TextOverflow.ellipsis))])])),
                            const SizedBox(width:8),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(it['status'] ?? 'Available', style: const TextStyle(color: Color(0xFF2F6B4F), fontWeight: FontWeight.w700)), const SizedBox(height:8), const Icon(Icons.chevron_right_rounded)]),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}

class MaterialDetailForNeed extends StatefulWidget {
  final Map<String, dynamic> listing;
  const MaterialDetailForNeed({super.key, required this.listing});

  @override
  State<MaterialDetailForNeed> createState() => _MaterialDetailForNeedState();
}

class _MaterialDetailForNeedState extends State<MaterialDetailForNeed> {
  int _reqQty = 1;
  String _message = '';
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final images = (listing['imageUrls'] as List).cast<String>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final ownerId = listing['ownerId']?.toString();
    final isOwner = currentUserId != null && ownerId == currentUserId;
    final availableQty = (listing['quantity'] is num) ? (listing['quantity'] as num).toInt() : int.tryParse('${listing['quantity']}') ?? 1;
    final isPaid = listing['isPaid'] ?? false;
    final priceVal = listing['_priceVal'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(listing['title'] ?? 'Material')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (images.isNotEmpty) Image.network(images[0], height: 220, width: double.infinity, fit: BoxFit.cover) else Container(height:220, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size:64, color: Color(0xFF2F6B4F)))),
          const SizedBox(height:12),
          Text(listing['title'] ?? '', style: const TextStyle(fontSize:22, fontWeight: FontWeight.w800)),
          const SizedBox(height:8),
          Text(listing['category'] ?? '', style: const TextStyle(color: Color(0xFF2F6B4F), fontWeight: FontWeight.w700)),
          const SizedBox(height:12),
          Text('Location: ${listing['location'] ?? ''}'),
          const SizedBox(height:8),
          Text('Condition: ${listing['condition'] ?? ''}'),
          const SizedBox(height:12),
          Text(listing['description'] ?? ''),
          const Spacer(),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isPaid ? '₹${priceVal.toString()}' : 'FREE', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), Text('Available: $availableQty ${listing['unit'] ?? ''}')]),
          const SizedBox(height:8),
          Row(children: [Text('Quantity needed:'), const SizedBox(width:8), IconButton(onPressed: () => setState(() { if (_reqQty > 1) _reqQty--; }), icon: const Icon(Icons.remove_circle_outline)), Text('$_reqQty'), IconButton(onPressed: () => setState(() { if (_reqQty < availableQty) _reqQty++; }), icon: const Icon(Icons.add_circle_outline))]),
          const SizedBox(height:8),
          TextField(decoration: const InputDecoration(labelText: 'Message to owner (optional)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), maxLines: 3, onChanged: (v) => _message = v.trim()),
          const SizedBox(height:8),
          if (isOwner)
            const Center(child: Text('You cannot request your own listing.', style: TextStyle(color: Color(0xFF69756D))))
          else
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _sending ? null : _sendRequest, child: _sending ? const CircularProgressIndicator() : const Text('Request Material'))),
        ]),
      ),
    );
  }

  Future<void> _sendRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to request materials.')));
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _sending = true);
    try {
      final materialId = widget.listing['id'];

      // fetch authoritative material document to determine owner
      final itemDoc = await FirebaseFirestore.instance.collection('items').doc(materialId).get();
      if (!itemDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material not found.')));
        return;
      }
      final itemData = itemDoc.data() as Map<String, dynamic>;
      // possible owner fields in existing DB
      final ownerId = (itemData['ownerId'] ?? itemData['userId'] ?? itemData['owner'] ?? '') as String;
      if (ownerId == user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot request your own listing.')));
        return;
      }

      // prevent duplicate active request (Pending)
      final existing = await FirebaseFirestore.instance.collection('exchange_requests').where('itemId', isEqualTo: materialId).where('requesterId', isEqualTo: user.uid).where('status', isEqualTo: 'pending').limit(1).get();
      if (existing.docs.isNotEmpty) {
        final id = existing.docs.first.id;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have already requested this material.')));
        Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: id)));
        return;
      }

      final price = widget.listing['_priceVal'] ?? 0;

      // For paid items, route to payment first
      if (price > 0) {
        // navigate to payment screen and only create request after success
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(amount: price, title: widget.listing['title'] ?? '', onPaymentSuccess: () async {
          // After payment success, create request with payment info
          final reqRef = FirebaseFirestore.instance.collection('exchange_requests').doc();
          final resolvedName = itemData['title'] ?? itemData['name'] ?? widget.listing['title'];
          final Map<String, dynamic> reqData = {
            'requestId': reqRef.id,
            'materialId': materialId,
            'itemId': materialId,
            'itemName': resolvedName,
            'ownerId': ownerId,
            'requesterId': user.uid,
            'requesterName': user.displayName ?? user.email ?? user.uid,
            'quantity': _reqQty,
            'message': _message.isNotEmpty ? _message : null,
            'price': price == 0 ? 0 : price,
            'status': 'pending',
            'paymentStatus': 'Completed',
            'paymentId': 'mock_payment_${DateTime.now().millisecondsSinceEpoch}',
            'amountPaid': price,
            'paidAt': FieldValue.serverTimestamp(),
            'createdAt': Timestamp.now(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await reqRef.set(reqData);
          if (!mounted) return;
          Navigator.pop(context); // pop payment screen
          await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Request Sent!'), content: const Text('Your request has been sent to the owner.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Browsing')), TextButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: reqRef.id))); }, child: const Text('View Request'))]));
        })));
        return;
      }

      final reqRef = FirebaseFirestore.instance.collection('exchange_requests').doc();
      final resolvedName = itemData['title'] ?? itemData['name'] ?? widget.listing['title'];
      final Map<String, dynamic> reqData = {
        'requestId': reqRef.id,
        'materialId': materialId,
        'itemId': materialId,
        'itemName': resolvedName,
        'ownerId': ownerId,
        'requesterId': user.uid,
        'requesterName': user.displayName ?? user.email ?? user.uid,
        'quantity': _reqQty,
        'message': _message.isNotEmpty ? _message : null,
        'price': price == 0 ? 0 : price,
        'status': 'pending',
        'paymentStatus': (price == 0) ? 'Not Required' : 'Pending',
        'createdAt': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await reqRef.set(reqData);

      // show success dialog
      if (!mounted) return;
      await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Request Sent!'), content: const Text('Your request has been sent to the owner.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Browsing')), TextButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: reqRef.id))); }, child: const Text('View Request'))]));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// Reuse RequestDetailScreen from material_tracking by importing file where it's defined when navigating.
