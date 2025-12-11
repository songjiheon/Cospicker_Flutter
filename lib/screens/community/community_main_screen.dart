import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_post_screen.dart';
import 'CommunitySearchScreen.dart';
import 'CommunitySearchDetailScreen.dart';

class Post {
  final String postId;
  final String uid;
  final String userName;
  final String title;
  final String content;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final String postType;
  final String profileUrl;
  final List<String> tags;

  Post({
    required this.postId,
    required this.uid,
    required this.userName,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.postType,
    required this.profileUrl,
    required this.tags,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      postId: data['postId'],
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '익명',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      postType: data['postType'] ?? '일반글',
      profileUrl: data['profileUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
}

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  CommunityMainScreenState createState() => CommunityMainScreenState();
}

class CommunityMainScreenState extends State<CommunityMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // -------------------------
      // 상단 AppBar (뒤로가기 추가 + 디자인 개선)
      // -------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups, size: 28, color: Colors.black87),
            SizedBox(width: 6),
            Text(
              "커뮤니티",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          // -------------------------
          // 검색창 UI 강화
          // -------------------------
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CommunitySearchScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.black54),
                    SizedBox(width: 10),
                    Text(
                      "검색어를 입력하세요",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------
          // 게시글 리스트
          // -------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs
                    .map((doc) => Post.fromFirestore(doc))
                    .toList();

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 140),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) =>
                      Container(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    return _postItem(posts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // -------------------------
      // 글쓰기 버튼 (둥글고 깔끔하게)
      // -------------------------
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/communityWrite'),
          backgroundColor: Colors.black,
          elevation: 3,
          label: Text(
            "+ 글쓰기",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 게시글 UI 디자인 업그레이드
  // ==========================================================
  Widget _postItem(Post post) {
    final timeString = _formatTime(post.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostScreen(postId: post.postId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // 프로필 + 시간
            // -------------------------
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: post.profileUrl.isNotEmpty
                      ? NetworkImage(post.profileUrl)
                      : null,
                  child: post.profileUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      post.postType,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                Spacer(),

                Text(
                  timeString,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            SizedBox(height: 14),

            // -------------------------
            // 제목
            // -------------------------
            Text(
              post.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            SizedBox(height: 10),

            // -------------------------
            // 말풍선 형태의 내용
            // -------------------------
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                post.content,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),

            SizedBox(height: 12),

            // -------------------------
            // 태그 표시
            // -------------------------
            if (post.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunitySearchDetailScreen(
                            keyword: tag,
                            isTagSearch: true,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            if (post.tags.isNotEmpty) SizedBox(height: 12),

            // -------------------------
            // 좋아요 / 댓글
            // -------------------------
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red, size: 18),
                SizedBox(width: 5),
                Text("${post.likeCount}"),

                SizedBox(width: 18),

                Icon(Icons.chat_bubble_outline,
                    color: Colors.grey.shade600, size: 18),
                SizedBox(width: 5),
                Text("${post.commentCount}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // 시간 포맷
  // -------------------------
  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 60) return "${diff.inMinutes}분전";
    if (diff.inHours < 24) return "${diff.inHours}시간전";
    return "${diff.inDays}일전";
  }
}

