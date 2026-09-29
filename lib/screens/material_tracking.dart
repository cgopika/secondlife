import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class MaterialTrackingScreen extends StatelessWidget {
  const MaterialTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tracking')),
        body: const Center(child: Text('Please log in to view tracking.')),
      );
    }

    // Query for requests where ownerId == current user
    final query = FirebaseFirestore.instance.collection('exchange_requests').where('ownerId', isEqualTo: user.uid).orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking'), leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No requests yet\nRequests involving your materials will appear here.', textAlign: TextAlign.center)));
            }

            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data() as Map<String, dynamic>;
                final status = (data['status'] ?? 'pending').toString().toLowerCase();
                final qty = data['quantity']?.toString() ?? '-';
                final price = data['price'];
                final requesterId = data['requesterId'] ?? '';
                final materialId = data['materialId'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['itemName'] ?? data['materialName'] ?? 'Material', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Requested by: ${data['requesterName'] ?? requesterId}'),
                      const SizedBox(height: 6),
                      Text('Quantity: $qty'),
                      const SizedBox(height: 6),
                      Text('Price: ${price == null || (price is num && price == 0) ? 'FREE' : '₹$price'}'),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(status[0].toUpperCase() + status.substring(1), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2F6B4F))),
                        const SizedBox(width: 12),
                        if (status == 'pending') ...[
                          ElevatedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Accept this request?'), content: const Text('Are you sure you want to accept this request?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept'))]));
                              if (confirm == true) {
                                await FirebaseFirestore.instance.collection('exchange_requests').doc(d.id).update({'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()});
                              }
                            },
                            child: const Text('Accept'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Reject this request?'), content: const Text('Are you sure you want to reject this request?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject'))]));
                              if (confirm == true) {
                                await FirebaseFirestore.instance.collection('exchange_requests').doc(d.id).update({'status': 'rejected', 'updatedAt': FieldValue.serverTimestamp()});
                              }
                            },
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: d.id))), child: const Text('View Request')),
                      ])
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _uploading = false;

  Future<void> _uploadOwnerPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _uploading = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1200) ?? await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (picked == null) return;
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child('request_proofs').child(widget.requestId).child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('exchange_requests').doc(widget.requestId).update({'ownerProofImageUrl': url, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('exchange_requests').doc(widget.requestId);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || !snap.data!.exists) return const Center(child: Text('Request not found'));
          final data = snap.data!.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          final ownerId = data['ownerId'] ?? '';
          final requesterId = data['requesterId'] ?? '';
          final ownerProof = data['ownerProofImageUrl'] as String?;

          final isOwner = user != null && user.uid == ownerId;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['itemName'] ?? data['materialName'] ?? 'Material', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Requested by: ${data['requesterName'] ?? requesterId}'),
                const SizedBox(height: 8),
                Text('Quantity: ${data['quantity'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('Price: ${data['price'] == null || (data['price'] is num && data['price'] == 0) ? 'FREE' : '₹${data['price']}'}'),
                const SizedBox(height: 12),
                Text('Status: ${status[0].toUpperCase()}${status.substring(1)}'),
                const SizedBox(height: 12),
                  if (isOwner) ...[
                  if (status == 'pending')
                    const SizedBox.shrink(),
                  if (status == 'accepted') ...[
                    const SizedBox(height: 12),
                    const Text('Transaction Update', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _uploading ? null : _uploadOwnerPhoto, child: _uploading ? const CircularProgressIndicator() : const Text('Upload Handover Photo')),
                    ),
                    const SizedBox(height: 8),
                    if (ownerProof != null) ...[
                      const SizedBox(height: 8),
                      const Text('Uploaded Photo:'),
                      const SizedBox(height: 8),
                      Image.network(ownerProof),
                    ],
                  ],
                ] else ...[
                  if (status == 'rejected') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('✕ Request Rejected', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
                        SizedBox(height: 6),
                        Text('The owner has rejected this request.'),
                      ]),
                    ),
                  ],
                  if (status == 'accepted') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('✓ Request Accepted', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2F6B4F))),
                        SizedBox(height: 6),
                        Text('The owner accepted your request.'),
                      ]),
                    ),
                  ],
                  if (ownerProof != null) ...[
                    const SizedBox(height: 12),
                    const Text('Owner uploaded photo:'),
                    const SizedBox(height: 8),
                    Image.network(ownerProof),
                  ],
                ],
              ]),
            ),
          );
        },
      ),
    );
  }
}
