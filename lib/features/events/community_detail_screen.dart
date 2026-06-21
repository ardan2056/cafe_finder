import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/firebase_status.dart' as fb_status;
import '../../core/routes/app_routes.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  bool isJoined = false;
  bool isLoading = false;
  int currentCount = 0;
  List<String> membersList = [];

  bool get _useFirestore => fb_status.isFirebaseReady &&
      FirebaseAuth.instance.currentUser != null &&
      !FirebaseAuth.instance.currentUser!.isAnonymous;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkJoinedStatus(String type, String id, List<String> initialMembers, int initialCount) async {
    if (_useFirestore) {
      final docRef = FirebaseFirestore.instance.collection(type == 'community' ? 'communities' : 'events').doc(id);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final members = List<String>.from(data[type == 'community' ? 'members' : 'goingUsers'] ?? []);
        setState(() {
          membersList = members;
          isJoined = members.contains(_uid);
          currentCount = data[type == 'community' ? 'memberCount' : 'going'] ?? members.length;
        });
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final key = type == 'community' ? 'joined_communities' : 'joined_events';
      final joined = prefs.getStringList(key) ?? [];
      setState(() {
        isJoined = joined.contains(id);
        currentCount = initialCount + (isJoined ? 1 : 0);
      });
    }
  }

  Future<void> _toggleJoin(String type, String id, Map<String, dynamic> data) async {
    setState(() => isLoading = true);
    try {
      if (_useFirestore) {
        final docRef = FirebaseFirestore.instance.collection(type == 'community' ? 'communities' : 'events').doc(id);
        final isGoing = membersList.contains(_uid);

        if (isGoing) {
          await docRef.update({
            type == 'community' ? 'members' : 'goingUsers': FieldValue.arrayRemove([_uid]),
            type == 'community' ? 'memberCount' : 'going': FieldValue.increment(-1),
          });
          membersList.remove(_uid);
          isJoined = false;
          currentCount -= 1;
        } else {
          await docRef.update({
            type == 'community' ? 'members' : 'goingUsers': FieldValue.arrayUnion([_uid]),
            type == 'community' ? 'memberCount' : 'going': FieldValue.increment(1),
          });
          membersList.add(_uid);
          isJoined = true;
          currentCount += 1;
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final key = type == 'community' ? 'joined_communities' : 'joined_events';
        final joined = prefs.getStringList(key) ?? [];

        if (joined.contains(id)) {
          joined.remove(id);
          isJoined = false;
          currentCount -= 1;
        } else {
          joined.add(id);
          isJoined = true;
          currentCount += 1;
        }
        await prefs.setStringList(key, joined);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isJoined
              ? (type == 'community' ? 'Berhasil bergabung dengan komunitas!' : 'Anda terdaftar untuk event ini!')
              : (type == 'community' ? 'Keluar dari komunitas.' : 'Batal mendaftar event.')),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final type = args['type'] as String; // 'community' or 'event'
    final id = args['id'] as String;
    final title = args['title'] as String;
    final desc = args['desc'] as String;

    // Optional event parameters
    final location = args['location'] as String?;
    final time = args['time'] as String?;
    final month = args['month'] as String?;
    final day = args['day'] as String?;
    final imageUrl = args['imageUrl'] as String?;

    // Optional community parameters
    final iconData = args['icon']; // IconData or String
    final colorData = args['color']; // Color or String

    final initialCount = args['memberCount'] ?? args['goingCount'] ?? 0;
    final initialMembers = List<String>.from(args['members'] ?? args['goingUsers'] ?? []);

    // Perform check on build once
    if (membersList.isEmpty && currentCount == 0) {
      _checkJoinedStatus(type, id, initialMembers, initialCount);
      currentCount = initialCount;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Dynamic Header/SliverAppBar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: type == 'event' && imageUrl != null && imageUrl.startsWith('http')
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            type == 'community' && colorData is Color
                                ? colorData
                                : AppTheme.primary,
                            AppTheme.primaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          type == 'community' && iconData is IconData
                              ? iconData
                              : Icons.groups_rounded,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Meta Info
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badge & Stats Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: type == 'community'
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : Colors.orange.shade50.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type == 'community' ? 'Komunitas' : 'Event',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: type == 'community' ? AppTheme.primary : Colors.orange.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        type == 'community' ? Icons.people_rounded : Icons.calendar_today_rounded,
                        size: 16,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type == 'community' ? '$currentCount Anggota' : '$currentCount Hadir',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFD4C3BA)),

                  // Location/Daerah Specific Details (for both event and community)
                  if (location != null && location.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppTheme.secondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type == 'community' ? 'Daerah / Lokasi' : 'Lokasi',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                location,
                                style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (type == 'event') const SizedBox(height: 16),
                  ],

                  if (type == 'event') ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.schedule_rounded, color: AppTheme.secondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Waktu & Tanggal', style: TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.bold)),
                              Text(
                                '${day ?? ''} ${month ?? ''} • ${time ?? ''}',
                                style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((location != null && location.isNotEmpty) || type == 'event')
                    const Divider(height: 32, color: Color(0xFFD4C3BA)),

                  // Description Section
                  const Text(
                    'Tentang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mock Members List
                  const Text(
                    'Anggota Terdaftar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        // Stack of avatars
                        ...List.generate(
                          (currentCount > 5) ? 5 : (currentCount == 0 ? 1 : currentCount),
                          (index) => Align(
                            widthFactor: 0.7,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-${1500000000000 + (index * 1000000)}?w=100&auto=format&fit=crop&q=80',
                                ),
                                child: currentCount == 0
                                    ? const Icon(Icons.person, color: Colors.grey, size: 20)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        if (currentCount > 5) ...[
                          const SizedBox(width: 8),
                          Text(
                            '+${currentCount - 5} lainnya',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                        if (currentCount == 0) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Jadilah yang pertama bergabung!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Actions Buttons
                  Row(
                    children: [
                      // Join / Leave Button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _toggleJoin(type, id, args),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isJoined ? Colors.grey.shade200 : AppTheme.primary,
                              foregroundColor: isJoined ? Colors.grey.shade700 : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: AppTheme.primary)
                                : Text(
                                    isJoined
                                        ? (type == 'community' ? 'Joined' : 'Batal Daftar')
                                        : (type == 'community' ? 'Join Komunitas' : 'Gabung Event'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ),
                      ),

                      // Chat Icon Button (Visible only if Joined)
                      if (isJoined) ...[
                        const SizedBox(width: 14),
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.groupChat,
                                arguments: {
                                  'id': id,
                                  'title': title,
                                  'type': type,
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
