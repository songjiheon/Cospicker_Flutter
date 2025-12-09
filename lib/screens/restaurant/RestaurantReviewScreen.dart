import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantReviewScreen extends StatefulWidget {
  final String contentid;
  final String title;

  const RestaurantReviewScreen({
    super.key,
    required this.contentid,
    required this.title,
  });

  @override
  State<RestaurantReviewScreen> createState() =>
      _RestaurantReviewScreenState();
}

class _RestaurantReviewScreenState
    extends State<RestaurantReviewScreen> {
  double rating = 0;
  final textController = TextEditingController();
  bool isSaving = false;

  Future<void> _saveReview() async {
    if (rating == 0 || textController.text.trim().isEmpty) return;

    setState(() => isSaving = true);

    await FirebaseFirestore.instance
        .collection("restaurantItems")
        .doc(widget.contentid)
        .collection("reviews")
        .add({
      "rating": rating,
      "text": textController.text.trim(),
      "images": [],
      "createdAt": FieldValue.serverTimestamp(),
      "userId": FirebaseAuth.instance.currentUser?.uid ?? "",
    });

    setState(() => isSaving = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.title} 리뷰 작성"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("별점", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // ⭐ 별점 UI
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => rating = index + 1.0),
                );
              }),
            ),

            const SizedBox(height: 20),
            const Text("리뷰 내용", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // 리뷰 입력칸
            TextField(
              controller: textController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "리뷰를 입력하세요",
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            // 저장 버튼
            ElevatedButton(
              onPressed: isSaving ? null : _saveReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "등록하기",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
