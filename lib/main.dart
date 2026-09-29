import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/welcome_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/impact_screen.dart';
import 'screens/ihave_landing.dart';
import 'screens/material_success.dart';
import 'screens/ineed_screen.dart';
import 'package:uuid/uuid.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SecondLifeApp());
}

class SecondLifeApp extends StatefulWidget {
  const SecondLifeApp({super.key});

  @override
  State<SecondLifeApp> createState() => _SecondLifeAppState();
}

class _SecondLifeAppState extends State<SecondLifeApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      // If user is signed out, remove authenticated routes and show the FIRST / Welcome screen
      if (user == null) {
        _navKey.currentState?.pushNamedAndRemoveUntil('/', (r) => false);
      } else {
        _navKey.currentState?.pushNamedAndRemoveUntil('/home', (r) => false);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      debugShowCheckedModeBanner: false,
      title: 'SecondLife',
      theme: AppTheme.light(),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/': (_) => const WelcomeScreen(),
        '/register': (_) => const RegisterScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomePage(),
        '/ihave': (_) => const IHaveLandingScreen(),
        '/ineed': (_) => const INeedScreen(),
      },
    );
  }
}

// ------------------------------------------------------------
// HOME
// ------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  List<Map<String, dynamic>> items = [];
  StreamSubscription<QuerySnapshot>? _itemsSub;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeContent(
            items: items,
            onViewItem: (item) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailsPage(item: item),
                ),
              );
            },
          ),
          BrowsePage(
            items: items,
            onViewItem: (item) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailsPage(item: item),
                ),
              );
            },
          ),
          const ImpactPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(selectedIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
                color: selectedIndex == 0 ? AppTheme.light().colorScheme.primary : Colors.grey[700],
                onPressed: () => setState(() => selectedIndex = 0),
              ),
              IconButton(
                icon: Icon(selectedIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded),
                color: selectedIndex == 3 ? AppTheme.light().colorScheme.primary : Colors.grey[700],
                onPressed: () => setState(() => selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
      // Home page removes central '+' action — Add Material is reached via I HAVE landing.
    );
  }

  @override
  void initState() {
    super.initState();
    _itemsSub = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs.map((d) => _docToItem(d)).toList();
      setState(() => items = list);
    }, onError: (e) {
      // simple error handling — show snackbar if mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load items.')));
      }
    });
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _docToItem(QueryDocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;
    String category = (data['category'] ?? '') as String;
    return {
      'id': d.id,
      'name': data['title'] ?? data['name'] ?? 'Untitled',
      'category': category,
      'location': data['location'] ?? '',
      'condition': data['condition'] ?? '',
      'description': data['description'] ?? '',
      'ownerId': data['ownerId'],
      'ownerEmail': data['ownerEmail'],
      'imageUrl': data['imageUrl'],
      'createdAt': data['createdAt'],
      'status': data['status'] ?? 'available',
      'icon': _iconForCategory(category),
      'color': _colorForCategory(category),
    };
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('book')) return Icons.menu_book_rounded;
    if (c.contains('furn') || c.contains('chair')) return Icons.chair_rounded;
    if (c.contains('cloth') || c.contains('clothes')) return Icons.checkroom_rounded;
    if (c.contains('elect')) return Icons.devices_rounded;
    return Icons.inventory_2_rounded;
  }

  Color _colorForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('book')) return const Color(0xFFF2EBDD);
    if (c.contains('furn') || c.contains('chair')) return const Color(0xFFE8F0E8);
    if (c.contains('cloth') || c.contains('clothes')) return const Color(0xFFE8EEF3);
    return const Color(0xFFF1F7F2);
  }

  void _showAddItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddItemSheet()),
    );
  }
}

// ------------------------------------------------------------
// HOME CONTENT
// ------------------------------------------------------------

class HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onViewItem;

  const HomeContent({
    super.key,
    required this.items,
    required this.onViewItem,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B6B52),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: const Center(
                          child: Icon(
                            Icons.recycling_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SecondLife',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF20362A),
                          ),
                        ),
                        Text(
                          'Give things a second life.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF728078),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF315C47),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -25,
                      top: -25,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(.06),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waste less.\nShare more.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Turn unused things into useful resources for someone else.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.82),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                  icon: Icons.add_rounded,
                                  label: 'I Have',
                                  onTap: () {
                                    Navigator.pushNamed(context, '/ihave');
                                  },
                                ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _ActionButton(
                                  icon: Icons.search_rounded,
                                  label: 'I Need',
                                  onTap: () { Navigator.pushNamed(context, '/ineed'); },
                                  light: true,
                                ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: _AnimatedToteBag(),
              ),
            ),
          ),

          // Removed Browse categories and Nearby items sections per spec; keep Home focused on primary actions.
        ],
      ),
    );
  }

  void _showAddItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) => const AddItemSheet(),
    );
  }
}

// ------------------------------------------------------------
// EXPLORE
// ------------------------------------------------------------

class BrowsePage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onViewItem;

  const BrowsePage({
    super.key,
    required this.items,
    required this.onViewItem,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 25, 24, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Explore',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20362A),
                ),
              ),
            ),
          ),

          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 4, 24, 18),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Find something useful near you.',
                style: TextStyle(
                  color: Color(0xFF78837D),
                  fontSize: 14,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                child: const Column(children: [
                  Icon(Icons.info_outline, size: 65, color: Color(0xFF315C47)),
                  SizedBox(height: 16),
                  Text('Explore is for discovery. I Need marketplace moved to Home → I Need.', textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// ITEM DETAILS
// ------------------------------------------------------------

class ItemDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailsPage({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && item['ownerId']?.toString() == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Item details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: item['color'],
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                item['icon'],
                size: 110,
                color: const Color(0xFF3B6B52),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              item['name'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20362A),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              item['category'],
              style: const TextStyle(
                color: Color(0xFF3B6B52),
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 22),

            _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'Location',
              value: item['location'],
            ),

            _InfoRow(
              icon: Icons.auto_awesome_outlined,
              title: 'Condition',
              value: item['condition'],
            ),

            _InfoRow(
              icon: Icons.swap_horiz_rounded,
              title: 'Exchange',
              value: 'Free / Exchange',
            ),

            const SizedBox(height: 25),

            const Text(
              'About this item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'This item is available for reuse. Instead of being thrown away, it can find a new home and become useful to someone else.',
              style: TextStyle(
                color: Color(0xFF68746D),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            if (isOwner)
              const Center(child: Text('You cannot request your own listing.', style: TextStyle(color: Color(0xFF69756D))))
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to request items.')));
                    Navigator.pushNamed(context, '/login');
                    return;
                  }

                  final itemId = item['id'] as String?;
                  if (itemId == null) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Request sent!'),
                        content: Text('Your request for ${item['name']} has been sent to the owner.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                        ],
                      ),
                    );
                    return;
                  }

                  try {
                    final reqs = FirebaseFirestore.instance.collection('exchange_requests');
                    final existing = await reqs
                        .where('itemId', isEqualTo: itemId)
                        .where('requesterId', isEqualTo: user.uid)
                        .where('status', isEqualTo: 'pending')
                        .limit(1)
                        .get();

                    if (existing.docs.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You already have a pending request for this item.')));
                      return;
                    }

                    await reqs.add({
                      'itemId': itemId,
                      'itemName': item['name'],
                      'ownerId': item['ownerId'],
                      'requesterId': user.uid,
                      'requesterName': user.displayName ?? user.email ?? user.uid,
                      'quantity': 1,
                      'price': 0,
                      'status': 'pending',
                      'createdAt': Timestamp.now(),
                    });

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Request sent!'),
                        content: Text('Your request for ${item['name']} has been sent to the owner.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                        ],
                      ),
                    );
                  } on FirebaseException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Failed to send request.')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request.')));
                  }
                  },
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text(
                    'Request Exchange',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// REQUESTS
// ------------------------------------------------------------

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            const Text(
              'Requests',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20362A),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Track your exchanges in one place.',
              style: TextStyle(
                color: Color(0xFF78837D),
              ),
            ),

            const SizedBox(height: 35),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.swap_horizontal_circle_outlined,
                    size: 65,
                    color: Color(0xFF3B6B52),
                  ),

                  SizedBox(height: 16),

                  Text(
                    'No active requests',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'When you request an item, it will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF78837D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PROFILE
// ------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 15),

          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20362A),
            ),
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF315C47),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Color(0xFF315C47),
                  ),
                ),

                SizedBox(width: 15),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SecondLife Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Making things useful again',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _ProfileTile(
            icon: Icons.inventory_2_outlined,
            title: 'My Listings',
          ),

          _ProfileTile(
            icon: Icons.favorite_border_rounded,
            title: 'Saved Items',
          ),

          _ProfileTile(
            iconWidget: Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: SizedBox(height: 20, width: 20, child: SvgPicture.asset('assets/icons/secondlife_mark.svg', color: Color(0xFF315C47))),
            ),
            title: 'My Impact',
          ),

          _ProfileTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
          ),
          const SizedBox(height: 14),
          StatefulBuilder(
            builder: (context, setState) {
              bool signingOut = false;
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: signingOut
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Logout?'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Logout')),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          setState(() => signingOut = true);

                          // show modal progress
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            await FirebaseAuth.instance.signOut();
                            // dismiss progress
                            Navigator.of(context).pop();
                            // clear navigation and go to FIRST / Welcome
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                          } catch (e) {
                            // dismiss progress
                            Navigator.of(context).pop();
                            setState(() => signingOut = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: ${e.toString()}')));
                          }
                        },
                  child: signingOut
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Signing out...'),
                          ],
                        )
                      : const Text('Log Out'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// ADD ITEM
// ------------------------------------------------------------

class _LocationConfirmationDialog extends StatelessWidget {
  final String address;
  final double latitude;
  final double longitude;

  const _LocationConfirmationDialog({required this.address, required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 126,
            width: double.infinity,
            child: CustomPaint(
              painter: _LocationPickerPainter(),
              child: const Center(child: Icon(Icons.location_on_rounded, color: Color(0xFF2F6B4F), size: 38)),
            ),
          ),
          const SizedBox(height: 12),
          Text(address, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}', style: const TextStyle(color: Color(0xFF69756D), fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Use This Location')),
      ],
    );
  }
}

class _LocationPickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE8F3EC);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), background);
    final road = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final path = Path()
      ..moveTo(-10, size.height * .72)
      ..quadraticBezierTo(size.width * .3, size.height * .2, size.width * .58, size.height * .65)
      ..quadraticBezierTo(size.width * .78, size.height * .95, size.width + 10, size.height * .25);
    canvas.drawPath(path, road);
    final grid = Paint()
      ..color = const Color(0x33708F70)
      ..strokeWidth = 1;
    for (var x = 18.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x - 18, size.height), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  String? _category;
  int? _quantity;
  String _unit = 'kg';
  String? _condition;
  final locationController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _isPaid = false;
  double? _price;
  final descriptionController = TextEditingController();
  bool _saving = false;
  List<XFile> _images = [];
  // store image bytes for reliable immediate preview (some platforms return content URIs)
  List<Uint8List> _imageBytes = [];

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final picker = ImagePicker();
      if (src == ImageSource.gallery) {
        final pickedList = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1200);
        if (pickedList == null || pickedList.isEmpty) return;
        final available = 4 - _images.length;
        final toAdd = pickedList.take(available).toList();
        if (toAdd.length < pickedList.length) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 4 photos allowed.')));
        }
        // read bytes for immediate preview and store XFile references
        final bytesList = await Future.wait(toAdd.map((f) => f.readAsBytes()));
        setState(() {
          _images = [..._images, ...toAdd];
          _imageBytes = [..._imageBytes, ...bytesList];
        });
      } else {
        final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1200);
        if (picked == null) return;
        final pickedBytes = await picked.readAsBytes();
        setState(() {
          // If there is already at least one photo, treat camera as a "retake" and replace the first
          if (_images.isNotEmpty) {
            _images[0] = picked;
            _imageBytes[0] = pickedBytes;
          } else {
            _images = [..._images, picked].take(4).toList();
            _imageBytes = [..._imageBytes, pickedBytes];
          }
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: ${e.toString()}')));
    }
  }

  void _removeImage(int idx) => setState(() {
        if (idx >= 0 && idx < _images.length) {
          _images.removeAt(idx);
        }
        if (idx >= 0 && idx < _imageBytes.length) {
          _imageBytes.removeAt(idx);
        }
      });

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied) {
          _showLocationMessage('Location permission denied. You can enter it manually.');
          return;
        }
        if (req == LocationPermission.deniedForever) {
          _showLocationMessage('Location permission is disabled. Enable it in Android settings or enter it manually.');
          return;
        }
      } else if (permission == LocationPermission.deniedForever) {
        _showLocationMessage('Location permission is disabled. Enable it in Android settings or enter it manually.');
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        _showLocationMessage('Location services are disabled. Turn on GPS or enter the location manually.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 10)));
      var readableLocation = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [place.name, place.locality, place.administrativeArea, place.country].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).toSet().toList();
          if (parts.isNotEmpty) readableLocation = parts.join(', ');
        }
      } catch (_) {
        // Keep the real coordinates readable if reverse geocoding is unavailable.
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _LocationConfirmationDialog(
          address: readableLocation,
          latitude: pos.latitude,
          longitude: pos.longitude,
        ),
      );
      if (confirmed == true && mounted) {
        setState(() {
          locationController.text = readableLocation;
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
      }
    } catch (e) {
      _showLocationMessage('Could not get your current location. You can enter it manually.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationMessage(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to publish.')));
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _saving = true);
    try {
      // NOTE: Firebase Storage uploads removed for hackathon — create item in Firestore without uploading images.
      // Keep local preview functionality; do NOT attempt to upload to Storage (avoids requiring Blaze plan).
      final List<String> urls = [];

      // create item document
      final coll = FirebaseFirestore.instance.collection('items');
      final docRef = coll.doc();

      final Map<String, dynamic> itemData = {
        'materialId': docRef.id,
        'title': nameController.text.trim(),
        'category': _category,
        'quantity': _quantity,
        'unit': _unit,
        'condition': _condition,
        'location': locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'isPaid': _isPaid,
        'price': _price,
        'description': descriptionController.text.trim(),
        'ownerId': user.uid,
        'ownerEmail': user.email,
        'imageUrls': urls,
        'imageUrl': urls.isNotEmpty ? urls.first : null,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(itemData);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MaterialSuccessScreen(listingId: docRef.id)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to publish material.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFBF6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: const Text('I Have', style: TextStyle(color: Color(0xFF20362A), fontWeight: FontWeight.w800)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(26),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text('Give something you no longer need a second life.', style: TextStyle(color: Colors.grey[700])),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo area
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFFE8F0E8), borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                          if (_images.isEmpty) ...[
                          const Icon(Icons.photo_camera_outlined, size: 48, color: Color(0xFF3B6B52)),
                          const SizedBox(height: 8),
                          const Text('Add item photos', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text('Show others what you have', style: TextStyle(color: Color(0xFF68746D))),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery')),
                          ])
                        ] else ...[
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageBytes.isNotEmpty
                                  ? Image.memory(_imageBytes.first, fit: BoxFit.cover, width: double.infinity)
                                  : Image.file(File(_images.first.path), fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 72,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageBytes.length > i
                                        ? Image.memory(_imageBytes[i], width: 72, height: 72, fit: BoxFit.cover)
                                        : Image.file(File(_images[i].path), width: 72, height: 72, fit: BoxFit.cover),
                                  ),
                                  Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => _removeImage(i), child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54), child: const Icon(Icons.close, size: 18, color: Colors.white))))
                                ]),
                              ),
                            ),
                          )
                        ],
                        const SizedBox(height: 8),
                        const Text('Add up to 4 photos', style: TextStyle(fontSize: 12, color: Color(0xFF68746D))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Material name
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Material name', hintText: 'e.g. Cardboard boxes', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a material name.' : null,
                  ),
                  const SizedBox(height: 12),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(labelText: 'Category', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    items: ['Cardboard', 'Wood', 'Fabric', 'Furniture', 'Books', 'Plastic', 'Electronics', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) => v == null ? 'Please select a category.' : null,
                  ),
                  const SizedBox(height: 12),

                  // Quantity and units
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Quantity', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        onChanged: (v) => _quantity = int.tryParse(v),
                        validator: (v) => (v == null || int.tryParse(v) == null || int.tryParse(v)! <= 0) ? 'Enter a valid quantity.' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        items: ['kg', 'pieces', 'litres', 'metres', 'boxes', 'sets'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => _unit = v ?? 'kg'),
                        decoration: InputDecoration(labelText: 'Unit', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      ),
                    )
                  ]),
                  const SizedBox(height: 12),

                  // Condition chips
                  const Text('Condition', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: ['New', 'Like New', 'Good', 'Used'].map((c) {
                    final selected = _condition == c;
                    return ChoiceChip(label: Text(c), selected: selected, onSelected: (_) => setState(() => _condition = c), selectedColor: const Color(0xFF2F6B4F));
                  }).toList()),
                  const SizedBox(height: 12),

                  // Location selector
                  const Text('Pickup location', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: locationController,
                    maxLines: 2,
                    onChanged: (_) {
                      if (_latitude != null || _longitude != null) setState(() { _latitude = null; _longitude = null; });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter location',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: _locating
                          ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: const Icon(Icons.my_location_outlined), tooltip: 'Use current location', onPressed: _useCurrentLocation),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _locating ? null : _useCurrentLocation, icon: const Icon(Icons.location_searching_rounded, size: 18), label: const Text('Use Current Location'))),
                  const SizedBox(height: 12),

                  // Price
                  const Text('Price', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: ChoiceChip(label: const Text('FREE\nGive it away'), selected: !_isPaid, onSelected: (_) => setState(() => _isPaid = false), selectedColor: const Color(0xFF2F6B4F))),
                    const SizedBox(width: 8),
                    Expanded(child: ChoiceChip(label: const Text('₹ PAID\nSet a price'), selected: _isPaid, onSelected: (_) => setState(() => _isPaid = true), selectedColor: const Color(0xFF2F6B4F))),
                  ]),
                  const SizedBox(height: 8),
                  if (_isPaid) ...[
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Price', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      onChanged: (v) => _price = double.tryParse(v),
                      validator: (v) => (_isPaid && (v == null || double.tryParse(v) == null || double.tryParse(v)! <= 0)) ? 'Please enter a price.' : null,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(controller: descriptionController, maxLines: 4, decoration: InputDecoration(labelText: 'Description', hintText: 'Tell people about the material, its condition, and possible uses...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 12),

                  // Preview
                  const Text('Listing preview', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: _images.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_images.first.path), fit: BoxFit.cover)) : const Icon(Icons.image, color: Colors.grey)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nameController.text.isEmpty ? 'Material name' : nameController.text, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('${_quantity ?? '-'} ${_unit} · ${_condition ?? '-'}', style: const TextStyle(color: Color(0xFF68746D))),
                      const SizedBox(height: 6),
                      Text(locationController.text.isEmpty ? 'No location' : locationController.text, style: const TextStyle(color: Color(0xFF68746D))),
                    ]))
                  ])),
                  const SizedBox(height: 12),

                  const Text('♻ Giving this material another chance keeps it in circulation.', style: TextStyle(color: Color(0xFF728078))),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _publish,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Publish Material'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6B4F),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// COMPONENTS
// ------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool light;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light
          ? Colors.white.withOpacity(.13)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: light
                    ? Colors.white
                    : const Color(0xFF315C47),
              ),

              const SizedBox(width: 7),

              Text(
                label,
                style: TextStyle(
                  color: light
                      ? Colors.white
                      : const Color(0xFF315C47),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF3B6B52),
            size: 27,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(21),
                  ),
                ),
                child: Icon(
                  item['icon'],
                  size: 65,
                  color: const Color(0xFF3B6B52),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                13,
                12,
                13,
                13,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    item['condition'],
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Color(0xFF3B6B52),
                      ),

                      const SizedBox(width: 3),

                      Text(
                        item['location'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF68746D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3B6B52),
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF8A948E),
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;

  const _ProfileTile({
    this.icon,
    this.iconWidget,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: ListTile(
        leading: iconWidget ?? Icon(
          icon ?? Icons.info_outline,
          color: const Color(0xFF3B6B52),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
      ),
    );
  }
}

class _AnimatedToteBag extends StatefulWidget {
  const _AnimatedToteBag();

  @override
  State<_AnimatedToteBag> createState() => _AnimatedToteBagState();
}

class _AnimatedToteBagState extends State<_AnimatedToteBag> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          return Transform.translate(
            offset: Offset(0, -2 + math.sin(phase) * 2.5),
            child: Transform.scale(
              scale: 1.22,
              child: Transform.rotate(
                angle: math.sin(phase) * .012,
                child: CustomPaint(
                  size: const Size(190, 150),
                  painter: _ToteBagPainter(handleSway: math.sin(phase)),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Icon(
                        Icons.recycling_rounded,
                        size: 38,
                        color: Color(0xFF5A8056),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToteBagPainter extends CustomPainter {
  final double handleSway;

  const _ToteBagPainter({required this.handleSway});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bag = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, 91), width: 104, height: 94),
      const Radius.circular(7),
    );

    final shadowPaint = Paint()..color = const Color(0x1A315C47);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, 143), width: 126, height: 12),
      shadowPaint,
    );

    final handlePaint = Paint()
      ..color = const Color(0xFFB08C68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final handlePath = Path()
      ..moveTo(centerX - 34, 48)
      ..cubicTo(centerX - 43, 8 + handleSway * 2, centerX - 12, 3 - handleSway * 2, centerX, 42)
      ..moveTo(centerX + 34, 48)
      ..cubicTo(centerX + 43, 8 - handleSway * 2, centerX + 12, 3 + handleSway * 2, centerX, 42);
    canvas.drawPath(handlePath, handlePaint);

    final bagPaint = Paint()..color = const Color(0xFFF1E6D1);
    canvas.drawRRect(bag, bagPaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF8F755C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(bag, outlinePaint);

    final foldPaint = Paint()
      ..color = const Color(0xFFD7C2A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(centerX - 52, 54), Offset(centerX + 52, 54), foldPaint);
    canvas.drawLine(Offset(centerX + 45, 57), Offset(centerX + 45, 132), foldPaint);

    final leafPaint = Paint()..color = const Color(0xFF78966B);
    final leafPath = Path()
      ..moveTo(centerX - 50, 43)
      ..quadraticBezierTo(centerX - 68, 26, centerX - 72, 43)
      ..quadraticBezierTo(centerX - 62, 53, centerX - 50, 43)
      ..moveTo(centerX + 53, 39)
      ..quadraticBezierTo(centerX + 68, 22, centerX + 72, 39)
      ..quadraticBezierTo(centerX + 62, 49, centerX + 53, 39);
    canvas.drawPath(leafPath, leafPaint);

    final stemPaint = Paint()
      ..color = const Color(0xFF5A8056)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(centerX - 50, 43), Offset(centerX - 64, 34), stemPaint);
    canvas.drawLine(Offset(centerX + 53, 39), Offset(centerX + 65, 30), stemPaint);
  }

  @override
  bool shouldRepaint(covariant _ToteBagPainter oldDelegate) => oldDelegate.handleSway != handleSway;
}