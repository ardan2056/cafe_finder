import 'package:flutter/material.dart';

import '../../../models/cafe.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cafes = sampleCafes();

    return Scaffold(
      appBar: AppBar(title: const Text('Maps')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 72, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Google Maps integration placeholder',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: cafes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cafe = cafes[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: Colors.white,
                    leading: const CircleAvatar(child: Icon(Icons.coffee_rounded)),
                    title: Text(cafe.name),
                    subtitle: Text(cafe.address),
                    trailing: Text(cafe.distanceLabel),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
