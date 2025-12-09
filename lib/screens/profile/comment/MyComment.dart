import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../community/CommunityPostScreen.dart';

class MyCommentScreen extends StatelessWidget {
  const MyCommentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인 상태가 아닙니다.')),
      );
    }
    final String uid = user.uid;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: const Text(
          "내 댓글",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup("Comments")
            .where("uid", isEqualTo: uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "작성한 댓글이 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String postId = data["postId"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Posts')
                    .doc(postId)
                    .get(),

                builder: (context, postSnapshot) {
                  if (!postSnapshot.hasData) {
                    return _loadingCommentCard();
                  }

                  final postData =
                  postSnapshot.data!.data() as Map<String, dynamic>?;

                  final String postTitle =
                      postData?['title'] ?? "(삭제된 게시글)";

                  return GestureDetector(
                    onTap: () {
                      if (postData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommunityPostScreen(postId: postId),
                          ),
                        );
                      }
                    },

                    child: _commentCard(
                      title: postTitle,
                      content: data["content"] ?? "",
                      date: _formatTimestamp(data["createdAt"]),
                      deleted: postData == null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // 📌 댓글 카드 UI
  // ==========================================================
  Widget _commentCard({
    required String title,
    required String content,
    required String date,
    required bool deleted,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: deleted ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 게시글 제목
          Text(
            deleted ? "삭제된 게시글입니다" : "게시글: $title",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: deleted ? Colors.red : Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          // 댓글 내용
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // 작성일
          Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 📌 로딩 중 스켈레톤 UI
  // ==========================================================
  Widget _loadingCommentCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  // ==========================================================
  // 📌 날짜 포맷
  // ==========================================================
  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "";

    final dt = ts.toDate();
    String two(int n) => n < 10 ? "0$n" : "$n";

    return "${dt.year}.${two(dt.month)}.${two(dt.day)}  "
        "${two(dt.hour)}:${two(dt.minute)}";
  }
}
