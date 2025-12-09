import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'CommunityPost.dart';

class MyCommentsScreen extends StatelessWidget {
  const MyCommentsScreen({super.key});

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
        title: Text("내 댓글"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup("Comments")
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
                "작성한 댓글이 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String postId = data['postId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Posts')
                    .doc(postId)
                    .get(),

                builder: (context, postSnapshot) {
                  if (!postSnapshot.hasData) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: EdgeInsets.all(14),
                      child: Text("게시글 불러오는 중..."),
                    );
                  }

                  final postData =
                  postSnapshot.data!.data() as Map<String, dynamic>?;

                  final postTitle =
                      postData?['title'] ?? "(삭제된 게시글)";
                  return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommunityPostScreen(postId: postId),
                          ),
                        );
                      },

                  child: Container(
                    margin:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          "게시글: $postTitle",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 6),

                        Text(
                          data['content'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),

                        Text(
                          _formatTimestamp(data['createdAt']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
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

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "";
    final dt = ts.toDate();
    return "${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute}";
  }
}

