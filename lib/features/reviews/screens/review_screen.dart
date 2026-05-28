import 'package:flutter/material.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _reviewController = TextEditingController();
  double _rating = 4;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = const [
      ('Brew House', 'Tempatnya nyaman untuk kerja, kopi enak.', 5.0),
      ('Morning Roast', 'Suka area outdoor dan pastry-nya.', 4.5),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Leave a review', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Slider(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: _rating.toStringAsFixed(1),
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write your review here',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review placeholder saved locally')),
                );
              }
            },
            child: const Text('Submit review'),
          ),
          const SizedBox(height: 32),
          Text('Recent reviews', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...reviews.map(
            (review) => Card(
              child: ListTile(
                leading: const Icon(Icons.reviews_rounded),
                title: Text(review.$1),
                subtitle: Text(review.$2),
                trailing: Text(review.$3.toStringAsFixed(1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
