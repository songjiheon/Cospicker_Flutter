import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../community/CommunityPostScreen.dart';


class Post {
  final String postId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String userName;
  final String profileUrl;
  final String postType;
  final int likeCount;
  final int commentCount;

  Post({
    required this.postId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.userName,
    required this.profileUrl,
    required this.postType,
    required this.likeCount,
    required this.commentCount,
  });
}

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

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
        title: Text("내 글"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Posts")
            .where("uid", isEqualTo: uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "작성한 글이 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityPostScreen(postId: data['postId']),
                      ),
                    );
                  },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      data['content'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text("${data['likeCount'] ?? 0}"),
                        SizedBox(width: 16),
                        Icon(Icons.comment, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text("${data['commentCount'] ?? 0}"),
                      ],
                    )
                  ],
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }
}