import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/firebase_status.dart' as fb_status;
import '../../core/routes/app_routes.dart';

class CommunityHubScreen extends StatefulWidget {
  final bool isActive;
  const CommunityHubScreen({super.key, this.isActive = false});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  String activeTab = 'komunitas'; // 'komunitas' or 'event'
  final Set<String> joinedCommunities = {};
  final Set<String> joinedEvents = {};

  final List<String> _regions = [
    'Semua',
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Balikpapan',
    'Yogyakarta',
    'Medan',
    'Makassar',
    'Bali',
  ];
  String _selectedRegion = 'Semua';
  final TextEditingController _eventSearchController = TextEditingController();
  final TextEditingController _regionSearchController = TextEditingController();

  @override
  void dispose() {
    _eventSearchController.dispose();
    _regionSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadJoinedStatus();
  }

  @override
  void didUpdateWidget(covariant CommunityHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadJoinedStatus();
    }
  }

  Future<void> _loadJoinedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      joinedCommunities.clear();
      joinedCommunities.addAll(prefs.getStringList('joined_communities') ?? []);
      joinedEvents.clear();
      joinedEvents.addAll(prefs.getStringList('joined_events') ?? []);
    });
  }

  bool get _useFirestore => fb_status.isFirebaseReady &&
      FirebaseAuth.instance.currentUser != null &&
      !FirebaseAuth.instance.currentUser!.isAnonymous;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  IconData _getIconData(String name) {
    switch (name) {
      case 'code':
        return Icons.code_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'coffee':
      default:
        return Icons.coffee_rounded;
    }
  }

  Color _getColor(String colorStr) {
    switch (colorStr) {
      case 'primary':
        return AppTheme.primary;
      case 'secondary':
        return AppTheme.secondary;
      case 'orange':
        return Colors.orange.shade700;
      case 'teal':
        return Colors.teal.shade700;
      case 'purple':
        return Colors.purple.shade700;
      case 'blue':
        return Colors.blue.shade700;
      default:
        return AppTheme.primary;
    }
  }

  final List<Map<String, dynamic>> communities = [
    {
      'id': 'c1',
      'title': 'Programmer Coffee Club',
      'desc': 'Coding, caffeine, and collaborations in Bandung.',
      'location': 'Bandung',
      'icon': Icons.code_rounded,
      'color': AppTheme.primary,
      'memberCount': 128,
    },
    {
      'id': 'c2',
      'title': 'UI/UX Designers Jkt',
      'desc': 'Connecting pixels and people in Jakarta.',
      'location': 'Jakarta',
      'icon': Icons.brush_rounded,
      'color': AppTheme.secondary,
      'memberCount': 42,
    },
    {
      'id': 'c3',
      'title': 'Coffee Roasters Indo',
      'desc': 'Share and learn roasting profiles in Surabaya.',
      'location': 'Surabaya',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.orange.shade700,
      'memberCount': 57,
    },
    {
      'id': 'c4',
      'title': 'Book Worms & Beans',
      'desc': 'Weekly reading circles in quiet cafes of Yogyakarta.',
      'location': 'Yogyakarta',
      'icon': Icons.menu_book_rounded,
      'color': Colors.teal.shade700,
      'memberCount': 31,
    },
  ];

  final List<Map<String, dynamic>> events = [
    {
      'id': 'e1',
      'title': 'Startup Networking Event',
      'location': 'The Espresso Lab, Jakarta',
      'month': 'OCT',
      'day': '24',
      'time': '18:00 - 20:00',
      'going': '45 Going',
      'imageUrl': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&auto=format&fit=crop&q=80',
    },
    {
      'id': 'e2',
      'title': 'Latte Art Workshop',
      'location': 'Roast & Co. Braga, Bandung',
      'month': 'OCT',
      'day': '28',
      'time': '14:00 - 16:00',
      'going': '12 Going',
      'imageUrl': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80',
    },
    {
      'id': 'e3',
      'title': 'Indie Writers Meetup',
      'location': 'Navy Brew Space, Balikpapan',
      'month': 'NOV',
      'day': '02',
      'time': '15:00 - 17:00',
      'going': '18 Going',
      'imageUrl': 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=600&auto=format&fit=crop&q=80',
    },
    {
      'id': 'e4',
      'title': 'Surabaya Coffee Enthusiasts',
      'location': 'Kopi Tiam Gubeng, Surabaya',
      'month': 'NOV',
      'day': '10',
      'time': '16:00 - 18:00',
      'going': '30 Going',
      'imageUrl': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&auto=format&fit=crop&q=80',
    },
    {
      'id': 'e5',
      'title': 'Yogyakarta Barista Meetup',
      'location': 'Jogja Brew Hub, Yogyakarta',
      'month': 'DEC',
      'day': '05',
      'time': '19:00 - 21:00',
      'going': '25 Going',
      'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600&auto=format&fit=crop&q=80',
    },
  ];

  Future<void> _toggleCommunity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (joinedCommunities.contains(id)) {
        joinedCommunities.remove(id);
      } else {
        joinedCommunities.add(id);
      }
    });
    await prefs.setStringList('joined_communities', joinedCommunities.toList());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(joinedCommunities.contains(id)
            ? 'Berhasil bergabung dengan komunitas!'
            : 'Keluar dari komunitas.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleEvent(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (joinedEvents.contains(id)) {
        joinedEvents.remove(id);
      } else {
        joinedEvents.add(id);
      }
    });
    await prefs.setStringList('joined_events', joinedEvents.toList());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(joinedEvents.contains(id)
            ? 'Anda terdaftar untuk event ini!'
            : 'Batal mendaftar event.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleCommunityFirestore(String docId, List<String> currentMembers, int currentCount) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('communities').doc(docId);
    final isJoined = currentMembers.contains(uid);

    if (isJoined) {
      await docRef.update({
        'members': FieldValue.arrayRemove([uid]),
        'memberCount': currentCount - 1,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keluar dari komunitas.'), duration: Duration(seconds: 1)),
      );
    } else {
      await docRef.update({
        'members': FieldValue.arrayUnion([uid]),
        'memberCount': currentCount + 1,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil bergabung dengan komunitas!'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _toggleEventFirestore(String docId, List<String> currentGoingUsers, int currentGoingCount) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('events').doc(docId);
    final isGoing = currentGoingUsers.contains(uid);

    if (isGoing) {
      await docRef.update({
        'goingUsers': FieldValue.arrayRemove([uid]),
        'going': currentGoingCount - 1,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batal mendaftar event.'), duration: Duration(seconds: 1)),
      );
    } else {
      await docRef.update({
        'goingUsers': FieldValue.arrayUnion([uid]),
        'going': currentGoingCount + 1,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda terdaftar untuk event ini!'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showCreateDialog() {
    if (activeTab == 'komunitas') {
      _showCreateCommunityDialog();
    } else {
      _showCreateEventDialog();
    }
  }

  void _showCreateCommunityDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    IconData selectedIcon = Icons.code_rounded;
    Color selectedColor = AppTheme.primary;

    final locationController = TextEditingController(text: 'Jakarta');

    final icons = [
      Icons.code_rounded,
      Icons.brush_rounded,
      Icons.local_fire_department_rounded,
      Icons.menu_book_rounded,
      Icons.laptop_mac_rounded,
      Icons.coffee_rounded,
    ];

    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.purple.shade700,
      Colors.blue.shade700,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Tambah Komunitas Baru',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: AppTheme.text),
                      decoration: InputDecoration(
                        labelText: 'Nama Komunitas',
                        labelStyle: const TextStyle(color: AppTheme.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: TextStyle(color: AppTheme.text),
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Singkat',
                        labelStyle: const TextStyle(color: AppTheme.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      style: TextStyle(color: AppTheme.text),
                      decoration: InputDecoration(
                        labelText: 'Lokasi / Daerah',
                        labelStyle: const TextStyle(color: AppTheme.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Icon',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: icons.map((icon) {
                            final isSelected = selectedIcon == icon;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedIcon = icon;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: AppTheme.primary),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Warna Tema',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: colors.map((color) {
                            final isSelected = selectedColor == color;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();
                    final location = locationController.text.trim();
                    if (title.isEmpty || desc.isEmpty || location.isEmpty) return;

                    if (_useFirestore) {
                      String iconName = 'coffee';
                      if (selectedIcon == Icons.code_rounded) iconName = 'code';
                      if (selectedIcon == Icons.brush_rounded) iconName = 'brush';
                      if (selectedIcon == Icons.local_fire_department_rounded) iconName = 'local_fire_department';
                      if (selectedIcon == Icons.menu_book_rounded) iconName = 'menu_book';
                      if (selectedIcon == Icons.laptop_mac_rounded) iconName = 'laptop_mac';

                      String colorName = 'primary';
                      if (selectedColor == AppTheme.secondary) colorName = 'secondary';
                      if (selectedColor == Colors.orange.shade700) colorName = 'orange';
                      if (selectedColor == Colors.teal.shade700) colorName = 'teal';
                      if (selectedColor == Colors.purple.shade700) colorName = 'purple';
                      if (selectedColor == Colors.blue.shade700) colorName = 'blue';

                      await FirebaseFirestore.instance.collection('communities').add({
                        'title': title,
                        'desc': desc,
                        'location': location,
                        'icon': iconName,
                        'color': colorName,
                        'memberCount': 1,
                        'members': [_uid],
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      setState(() {
                        communities.add({
                          'id': 'c${communities.length + 1}',
                          'title': title,
                          'desc': desc,
                          'location': location,
                          'icon': selectedIcon,
                          'color': selectedColor,
                          'memberCount': 1,
                        });
                      });
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Komunitas baru berhasil ditambahkan!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final timeController = TextEditingController(text: '15:00 - 17:00');
    final monthController = TextEditingController(text: 'OCT');
    final dayController = TextEditingController(text: '30');
    String imageUrl = 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&auto=format&fit=crop&q=80';

    final presetImages = [
      'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&auto=format&fit=crop&q=80', // Seminar/Networking
      'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80', // Workshop/Latte Art
      'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=600&auto=format&fit=crop&q=80', // Writing/Study
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&auto=format&fit=crop&q=80', // Relax/Cafe
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Buat Event Baru',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: AppTheme.text),
                      decoration: InputDecoration(
                        labelText: 'Nama Event',
                        labelStyle: const TextStyle(color: AppTheme.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      style: TextStyle(color: AppTheme.text),
                      decoration: InputDecoration(
                        labelText: 'Lokasi Event',
                        labelStyle: const TextStyle(color: AppTheme.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dayController,
                            style: TextStyle(color: AppTheme.text),
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              labelStyle: const TextStyle(color: AppTheme.textLight),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: monthController,
                            style: TextStyle(color: AppTheme.text),
                            decoration: InputDecoration(
                              labelText: 'Bulan (OCT)',
                              labelStyle: const TextStyle(color: AppTheme.textLight),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      style: TextStyle(color: AppTheme.text),
                      decoration: InputDecoration(
                        labelText: 'Waktu (18:00 - 20:00)',
                        labelStyle: const TextStyle(color: AppTheme.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Gambar Cover',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: presetImages.map((img) {
                            final isSelected = imageUrl == img;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  imageUrl = img;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(img),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final location = locationController.text.trim();
                    final time = timeController.text.trim();
                    final day = dayController.text.trim();
                    final month = monthController.text.trim();
                    
                    if (title.isEmpty || location.isEmpty || time.isEmpty || day.isEmpty || month.isEmpty) return;

                    if (_useFirestore) {
                      await FirebaseFirestore.instance.collection('events').add({
                        'title': title,
                        'location': location,
                        'month': month.toUpperCase(),
                        'day': day,
                        'time': time,
                        'going': 1,
                        'goingUsers': [_uid],
                        'imageUrl': imageUrl,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      setState(() {
                        events.add({
                          'id': 'e${events.length + 1}',
                          'title': title,
                          'location': location,
                          'month': month.toUpperCase(),
                          'day': day,
                          'time': time,
                          'going': '1 Going',
                          'imageUrl': imageUrl,
                        });
                      });
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event baru berhasil didaftarkan!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Daftarkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BrewQuest',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // Switch tab to profile
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 22),
                    ),
                  )
                ],
              ),
            ),
            
            // Header Hero Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Community Hub',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Temukan ruang kolaborasi dan interaksi terbaik di kota Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sliding custom buttons tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => activeTab = 'komunitas'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: activeTab == 'komunitas' ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Komunitas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 'komunitas' ? Colors.white : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => activeTab = 'event'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: activeTab == 'event' ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Event',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 'event' ? Colors.white : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            _buildGlobalSearchAndFilterSection(),

            const SizedBox(height: 10),

            // Content scroll area
            Expanded(
              child: IndexedStack(
                index: activeTab == 'komunitas' ? 0 : 1,
                children: [
                  _useFirestore
                      ? _buildKomunitasTabFirestore()
                      : _buildKomunitasTabLocal(),
                  _useFirestore
                      ? _buildEventTabFirestore()
                      : _buildEventTabLocal(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.secondaryContainer,
        foregroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildKomunitasTabLocal() {
    final filteredCommunities = communities.where((c) {
      final title = (c['title'] as String).toLowerCase();
      final desc = (c['desc'] as String).toLowerCase();
      final location = (c['location'] as String? ?? '').toLowerCase();
      
      final query = _eventSearchController.text.toLowerCase();
      final matchesQuery = title.contains(query) || desc.contains(query);
      
      final regionQuery = _regionSearchController.text.toLowerCase();
      final matchesRegion = regionQuery.isEmpty || location.contains(regionQuery) || desc.contains(regionQuery);
      
      return matchesQuery && matchesRegion;
    }).toList();

    if (filteredCommunities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Tidak ada komunitas yang cocok.',
            style: TextStyle(color: AppTheme.textLight),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredCommunities.length,
      itemBuilder: (context, index) {
        final c = filteredCommunities[index];
        final id = c['id'] as String;
        final isJoined = joinedCommunities.contains(id);

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.communityDetail,
              arguments: {
                'type': 'community',
                'id': id,
                'title': c['title'] as String,
                'desc': c['desc'] as String,
                'location': c['location'] as String? ?? '',
                'icon': c['icon'],
                'color': c['color'],
                'memberCount': c['memberCount'],
                'members': <String>[],
              },
            ).then((_) => _loadJoinedStatus());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (c['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['desc'] as String,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${c['memberCount']} Anggota',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary.withValues(alpha: 0.6),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleCommunity(id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isJoined ? Colors.grey.shade100 : AppTheme.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isJoined ? Colors.grey.shade300 : AppTheme.secondary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                isJoined ? 'Joined' : 'Join',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isJoined ? Colors.grey.shade600 : AppTheme.secondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKomunitasTabFirestore() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final docs = snapshot.data!.docs;
        
        final filteredDocs = docs.where((doc) {
          final c = doc.data() as Map<String, dynamic>;
          final title = (c['title'] ?? '').toString().toLowerCase();
          final desc = (c['desc'] ?? '').toString().toLowerCase();
          final location = (c['location'] ?? '').toString().toLowerCase();
          
          final query = _eventSearchController.text.toLowerCase();
          final matchesQuery = title.contains(query) || desc.contains(query);
          
          final regionQuery = _regionSearchController.text.toLowerCase();
          final matchesRegion = regionQuery.isEmpty || location.contains(regionQuery) || desc.contains(regionQuery);
          
          return matchesQuery && matchesRegion;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Tidak ada komunitas yang cocok.',
                style: TextStyle(color: AppTheme.textLight),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final c = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final title = c['title'] ?? '';
            final desc = c['desc'] ?? '';
            final iconStr = c['icon'] ?? 'coffee';
            final colorStr = c['color'] ?? 'primary';
            final memberCount = c['memberCount'] ?? 0;
            final members = List<String>.from(c['members'] ?? []);
            
            final location = c['location'] ?? '';
            
            final isJoined = members.contains(_uid);

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.communityDetail,
                  arguments: {
                    'type': 'community',
                    'id': id,
                    'title': title,
                    'desc': desc,
                    'location': location,
                    'icon': iconStr,
                    'color': colorStr,
                    'memberCount': memberCount,
                    'members': members,
                  },
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _getColor(colorStr).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getIconData(iconStr), color: _getColor(colorStr), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$memberCount Anggota',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary.withValues(alpha: 0.6),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleCommunityFirestore(id, members, memberCount),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isJoined ? Colors.grey.shade100 : AppTheme.secondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isJoined ? Colors.grey.shade300 : AppTheme.secondary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    isJoined ? 'Joined' : 'Join',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isJoined ? Colors.grey.shade600 : AppTheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalSearchAndFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _eventSearchController,
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(color: AppTheme.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari kata kunci...',
                    hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.secondary, size: 18),
                    suffixIcon: _eventSearchController.text.isNotEmpty
                        ? GestureDetector(
                            child: const Icon(Icons.clear_rounded, color: AppTheme.secondary, size: 18),
                            onTap: () {
                              _eventSearchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFD4C3BA).withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFD4C3BA).withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _regionSearchController,
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(color: AppTheme.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ketik kota...',
                    hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                    prefixIcon: const Icon(Icons.location_city_rounded, color: AppTheme.secondary, size: 18),
                    suffixIcon: _regionSearchController.text.isNotEmpty
                        ? GestureDetector(
                            child: const Icon(Icons.clear_rounded, color: AppTheme.secondary, size: 18),
                            onTap: () {
                              _regionSearchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFD4C3BA).withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFD4C3BA).withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = _regionSearchController.text.toLowerCase() == region.toLowerCase() ||
                    (region == 'Semua' && _regionSearchController.text.isEmpty);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (region == 'Semua') {
                        _regionSearchController.clear();
                      } else {
                        _regionSearchController.text = region;
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : const Color(0xFFD4C3BA).withValues(alpha: 0.4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      region,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTabLocal() {
    final filteredEvents = events.where((ev) {
      final title = (ev['title'] as String).toLowerCase();
      final location = (ev['location'] as String).toLowerCase();
      
      final query = _eventSearchController.text.toLowerCase();
      final matchesQuery = title.contains(query) || location.contains(query);
      
      final regionQuery = _regionSearchController.text.toLowerCase();
      final matchesRegion = regionQuery.isEmpty || location.contains(regionQuery);
      
      return matchesQuery && matchesRegion;
    }).toList();

    if (filteredEvents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Tidak ada event yang cocok.',
            style: TextStyle(color: AppTheme.textLight),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final ev = filteredEvents[index];
        final id = ev['id'] as String;
        final isGoing = joinedEvents.contains(id);

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.communityDetail,
              arguments: {
                'type': 'event',
                'id': id,
                'title': ev['title'] as String,
                'desc': 'Ikuti event menarik ini untuk memperluas jaringan Anda dan mempelajari hal baru.',
                'location': ev['location'] as String,
                'month': ev['month'] as String,
                'day': ev['day'] as String,
                'time': ev['time'] as String,
                'goingCount': 45,
                'imageUrl': ev['imageUrl'] as String,
                'goingUsers': <String>[],
              },
            ).then((_) => _loadJoinedStatus());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      ev['imageUrl'] as String,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        child: const Center(
                          child: Icon(Icons.event_note_rounded, size: 54, color: AppTheme.primary),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ev['month'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              ev['day'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev['title'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ev['location'] as String,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            ev['time'] as String,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.groups_rounded, size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            ev['going'] as String,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _toggleEvent(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGoing ? Colors.grey.shade200 : AppTheme.primary,
                            foregroundColor: isGoing ? Colors.grey.shade700 : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isGoing ? 'Terdaftar' : 'Gabung Event',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (!isGoing) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventTabFirestore() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final docs = snapshot.data!.docs;
        
        final filteredDocs = docs.where((doc) {
          final ev = doc.data() as Map<String, dynamic>;
          final title = (ev['title'] ?? '').toString().toLowerCase();
          final location = (ev['location'] ?? '').toString().toLowerCase();
          
          final query = _eventSearchController.text.toLowerCase();
          final matchesQuery = title.contains(query) || location.contains(query);
          
          final regionQuery = _regionSearchController.text.toLowerCase();
          final matchesRegion = regionQuery.isEmpty || location.contains(regionQuery);
          
          return matchesQuery && matchesRegion;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Tidak ada event yang cocok.',
                style: TextStyle(color: AppTheme.textLight),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final ev = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final title = ev['title'] ?? '';
            final location = ev['location'] ?? '';
            final month = ev['month'] ?? 'OCT';
            final day = ev['day'] ?? '01';
            final time = ev['time'] ?? '18:00 - 20:00';
            final imageUrl = ev['imageUrl'] ?? '';
            final goingUsers = List<String>.from(ev['goingUsers'] ?? []);
            final goingCount = ev['going'] ?? goingUsers.length;

            final isGoing = goingUsers.contains(_uid);

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.communityDetail,
                  arguments: {
                    'type': 'event',
                    'id': id,
                    'title': title,
                    'desc': 'Ikuti event menarik ini untuk memperluas jaringan Anda dan mempelajari hal baru.',
                    'location': location,
                    'month': month,
                    'day': day,
                    'time': time,
                    'goingCount': goingCount,
                    'imageUrl': imageUrl,
                    'goingUsers': goingUsers,
                  },
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        imageUrl.isNotEmpty && imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 150,
                                  color: AppTheme.secondary.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: Icon(Icons.event_note_rounded, size: 54, color: AppTheme.primary),
                                  ),
                                ),
                              )
                            : Container(
                                height: 150,
                                color: AppTheme.secondary.withValues(alpha: 0.1),
                                child: const Center(
                                  child: Icon(Icons.event_note_rounded, size: 54, color: AppTheme.primary),
                                ),
                              ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  month,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.secondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.secondary),
                              const SizedBox(width: 6),
                              Text(
                                time,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.groups_rounded, size: 16, color: AppTheme.secondary),
                              const SizedBox(width: 6),
                              Text(
                                '$goingCount Going',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _toggleEventFirestore(id, goingUsers, goingCount),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isGoing ? Colors.grey.shade200 : AppTheme.primary,
                                foregroundColor: isGoing ? Colors.grey.shade700 : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isGoing ? 'Terdaftar' : 'Gabung Event',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (!isGoing) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
