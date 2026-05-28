import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/review_service.dart';

class ReviewScreen extends StatefulWidget {
  final String cafeId;

  const ReviewScreen({
    super.key,
    required this.cafeId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final commentController = TextEditingController();
  final reviewService = ReviewService();

  double rating = 5;
  bool isLoading = false;

  final List<String> tags = [
    'Tenang',
    'Cozy',
    'Wi-Fi',
    'Colokan',
    'Estetik',
    'Ramai',
    'Murah',
  ];

  final List<String> selectedTags = [];

  Future<void> submitReview() async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await reviewService.addReview(
        cafeId: widget.cafeId,
        rating: rating,
        comment: commentController.text,
        tags: selectedTags,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim review: $e')),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Tulis Review'),
        backgroundColor: AppTheme.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating'),
            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: AppTheme.gold,
              label: rating.toString(),
              onChanged: (value) {
                setState(() => rating = value);
              },
            ),
            const SizedBox(height: 20),
            const Text('Pilih Tag'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tags.map((tag) {
                final selected = selectedTags.contains(tag);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selected
                          ? selectedTags.remove(tag)
                          : selectedTags.add(tag);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.gold
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tulis pengalamanmu...',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Kirim Review',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
