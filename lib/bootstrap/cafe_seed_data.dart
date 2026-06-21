import 'package:cloud_firestore/cloud_firestore.dart';

final List<Map<String, dynamic>> initialCafes = [
  {
    'name': "Sa'adah Bakery",
    'description': "Toko roti legendaris dengan aneka pastry lezat, donat premium, dan area santai untuk menikmati kopi susu bersama keluarga.",
    'address': "Jl. Soekarno Hatta KM 4,5 (Jl. Subulussalam), Batu Ampar, Balikpapan Utara",
    'latitude': -1.2014,
    'longitude': 116.8523,
    'facilities': ['Wi-Fi', 'Indoor', 'AC', 'Parkir Area', 'Toilet'],
    'atmosphere': ['Nyaman', 'Hangat'],
    'categories': ['Santai', 'Belajar'],
    'priceRange': r'$$',
    'rating': 4.6,
    'images': [
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "Cold 'N Brew - Batu Ampar",
    'description': "Tempat kerja paling favorit dengan workspace luas, colokan di setiap meja, internet super cepat, dan menu signature cold brew legendaris.",
    'address': "Jl. Soekarno Hatta No.2a, Batu Ampar, Balikpapan Utara",
    'latitude': -1.2052,
    'longitude': 116.8530,
    'facilities': ['Wi-Fi', 'Colokan', 'AC', 'Indoor', 'Outdoor', 'Parkir Area', 'Mushola'],
    'atmosphere': ['Tenang', 'Produktif'],
    'categories': ['Kerja', 'Belajar', 'Meeting'],
    'priceRange': r'$$',
    'rating': 4.8,
    'images': [
      'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507133750040-4a8f57021571?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "Kopi Luru Martadinata",
    'description': "Kafe estetik di lereng bukit dengan pemandangan kota Balikpapan yang memukau. Sangat cocok untuk nongkrong sore hari menikmati senja.",
    'address': "Jl. RE Martadinata No.88, Gunungsari Ilir, Balikpapan Tengah",
    'latitude': -1.2483,
    'longitude': 116.8375,
    'facilities': ['Wi-Fi', 'Outdoor', 'Semi-Outdoor', 'Live Music', 'Parkir Area'],
    'atmosphere': ['Nyaman', 'Pemandangan Indah', 'Santai'],
    'categories': ['Nongkrong', 'Santai'],
    'priceRange': r'$$',
    'rating': 4.5,
    'images': [
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "Kopi Luru Pantai",
    'description': "Menikmati kopi artisan dengan deburan ombak dan pemandangan laut lepas. Tempat terbaik untuk bersantai di sore dan malam hari.",
    'address': "Jl. Jenderal Sudirman No.14, Damai, Balikpapan Kota",
    'latitude': -1.2720,
    'longitude': 116.8432,
    'facilities': ['Wi-Fi', 'Outdoor', 'Deburan Ombak', 'Parkir Area', 'Toilet'],
    'atmosphere': ['Santai', 'Pantai', 'Romantis'],
    'categories': ['Nongkrong', 'Santai'],
    'priceRange': r'$$',
    'rating': 4.7,
    'images': [
      'https://images.unsplash.com/photo-1507133750040-4a8f57021571?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "28 Coffee (KM 2.5)",
    'description': "Warung kopi minimalis modern dengan cita rasa kopi lokal premium. Pilihan terbaik untuk quick fix kopi harianmu.",
    'address': "Jl. Soekarno Hatta km 2.5 No.70, Batu Ampar, Balikpapan Utara",
    'latitude': -1.2210,
    'longitude': 116.8505,
    'facilities': ['Wi-Fi', 'Indoor', 'AC', 'Minimalis', 'Parkir Area'],
    'atmosphere': ['Tenang', 'Nyaman'],
    'categories': ['Kerja', 'Nongkrong'],
    'priceRange': r'$',
    'rating': 4.4,
    'images': [
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "Potokoffie Grand City",
    'description': "Tempat berkumpulnya komunitas kreatif. Dengan dekorasi estetik instagramable dan aneka specialty coffee manual brew.",
    'address': "Ruko Golden Boulevard, Grand City AC/15, Balikpapan Utara",
    'latitude': -1.2185,
    'longitude': 116.8850,
    'facilities': ['Wi-Fi', 'AC', 'Indoor', 'Manual Brew Bar', 'Spot Foto'],
    'atmosphere': ['Kreatif', 'Instagramable'],
    'categories': ['Kreatif', 'Nongkrong'],
    'priceRange': r'$$$',
    'rating': 4.6,
    'images': [
      'https://images.unsplash.com/photo-1453614512568-c4024d13c247?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "BREWFORIA",
    'description': "Hadir dengan konsep industrial modern, Brewforia menawarkan suasana nongkrong yang asik, live music mingguan, dan pilihan kopi/non-kopi variatif.",
    'address': "Jl. Indrakila 3 RT 32 No. 26B, Gn. Samarinda, Balikpapan Utara",
    'latitude': -1.2285,
    'longitude': 116.8590,
    'facilities': ['Wi-Fi', 'Outdoor', 'Live Music', 'Colokan', 'Meeting Room'],
    'atmosphere': ['Ramai', 'Asik'],
    'categories': ['Nongkrong', 'Meeting', 'Komunitas'],
    'priceRange': r'$$',
    'rating': 4.5,
    'images': [
      'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "Madden Space and Coffee",
    'description': "Kolaborasi antara art space dan specialty coffee shop. Dapatkan inspirasi karyamu di sini sambil menikmati latte hangat.",
    'address': "Jl. Kapten Piere Tendean No.6, Klandasan Ulu, Balikpapan Kota",
    'latitude': -1.2765,
    'longitude': 116.8290,
    'facilities': ['Wi-Fi', 'AC', 'Art Gallery', 'Indoor', 'Workspace'],
    'atmosphere': ['Kreatif', 'Hening'],
    'categories': ['Kreatif', 'Kerja', 'Belajar'],
    'priceRange': r'$$$',
    'rating': 4.8,
    'images': [
      'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  },
  {
    'name': "Blob Coffee Bar",
    'description': "Coffee bar kekinian dengan desain colorful dan pop-art. Pilihan menu fusion coffee yang menyegarkan untuk hang out seru.",
    'address': "Jl. Belibis II No.53, RT.01, Gn. Bahagia, Balikpapan Selatan",
    'latitude': -1.2495,
    'longitude': 116.8685,
    'facilities': ['Wi-Fi', 'AC', 'Indoor', 'Pop Art Design', 'Games Corner'],
    'atmosphere': ['Playful', 'Ceria'],
    'categories': ['Nongkrong', 'Santai'],
    'priceRange': r'$$',
    'rating': 4.6,
    'images': [
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&auto=format&fit=crop&q=80'
    ],
    'isActive': true
  }
];

Future<void> seedCafesIfEmpty() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('cafes').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final batch = firestore.batch();
      for (final cafe in initialCafes) {
        final docRef = firestore.collection('cafes').doc();
        batch.set(docRef, {
          ...cafe,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      // ignore: avoid_print
      print('Seeded ${initialCafes.length} initial cafes successfully.');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error checking/seeding initial cafes: $e');
  }
}

Future<void> seedCommunitiesAndEventsIfEmpty() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final comSnap = await firestore.collection('communities').limit(1).get();
    if (comSnap.docs.isEmpty) {
      final batch = firestore.batch();
      final list = [
        {
          'title': 'Programmer Coffee Club',
          'desc': 'Coding, caffeine, and collaborations.',
          'icon': 'code',
          'color': 'primary',
          'memberCount': 128,
          'members': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'UI/UX Designers Jkt',
          'desc': 'Connecting pixels and people in Jakarta.',
          'icon': 'brush',
          'color': 'secondary',
          'memberCount': 42,
          'members': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Coffee Roasters Indo',
          'desc': 'Share and learn roasting profiles.',
          'icon': 'local_fire_department',
          'color': 'orange',
          'memberCount': 57,
          'members': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Book Worms & Beans',
          'desc': 'Weekly reading circles in quiet cafes.',
          'icon': 'menu_book',
          'color': 'teal',
          'memberCount': 31,
          'members': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];
      for (final item in list) {
        final docRef = firestore.collection('communities').doc();
        batch.set(docRef, item);
      }
      await batch.commit();
      // ignore: avoid_print
      print('Seeded initial communities.');
    }

    final evSnap = await firestore.collection('events').limit(1).get();
    if (evSnap.docs.isEmpty) {
      final batch = firestore.batch();
      final list = [
        {
          'title': 'Startup Networking Event',
          'location': 'The Espresso Lab, Jakarta',
          'month': 'OCT',
          'day': '24',
          'time': '18:00 - 20:00',
          'going': 45,
          'goingUsers': <String>[],
          'imageUrl': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&auto=format&fit=crop&q=80',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Latte Art Workshop',
          'location': 'Roast & Co. Menteng',
          'month': 'OCT',
          'day': '28',
          'time': '14:00 - 16:00',
          'going': 12,
          'goingUsers': <String>[],
          'imageUrl': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Indie Writers Meetup',
          'location': 'Navy Brew Space, Balikpapan',
          'month': 'NOV',
          'day': '02',
          'time': '15:00 - 17:00',
          'going': 18,
          'goingUsers': <String>[],
          'imageUrl': 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=600&auto=format&fit=crop&q=80',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];
      for (final item in list) {
        final docRef = firestore.collection('events').doc();
        batch.set(docRef, item);
      }
      await batch.commit();
      // ignore: avoid_print
      print('Seeded initial events.');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error checking/seeding initial communities/events: $e');
  }
}
