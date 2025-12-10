import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CommunityPost.dart';

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
  final String tag;

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
    required this.tag,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      postId: data['postId'],
      profileUrl: data['profileUrl'] ?? '',
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '익명',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      postType: data['postType'] ?? '일반글',
      tag: data['tag'] ?? '',
    );
  }
}



class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  String _keyword = '';
  String _selectedTag = '';
  final List<String> _tagFilters = const [
    '',
    '맛집',
    '숙소',
    '정보',
    '질문',
    '자유',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: "제목/내용 키워드 검색",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (text) => setState(() => _keyword = text.trim()),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tagFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tag = _tagFilters[index];
                final isSelected = tag == _selectedTag;
                return ChoiceChip(
                  label: Text(tag.isEmpty ? '전체' : '#$tag'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedTag = selected ? tag : '');
                  },
                  selectedColor: Colors.blue.shade400,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final posts = snapshot.data!.docs.map((doc) => Post.fromFirestore(doc)).toList();
          final lower = _keyword.toLowerCase();
          final filtered = posts.where((p) {
            final matchKeyword = lower.isEmpty ||
                p.title.toLowerCase().contains(lower) ||
                p.content.toLowerCase().contains(lower);
            final matchTag = _selectedTag.isEmpty || p.tag == _selectedTag;
            return matchKeyword && matchTag;
          }).toList();

          return ListView.builder(
            padding: EdgeInsets.only(bottom: 90),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final post = filtered[index];
              final createdAt = post.createdAt;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityPostScreen(postId: post.postId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 태그 / 유형 표시
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (post.tag.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '#${post.tag}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              post.postType,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: post.profileUrl.isNotEmpty
                                  ? NetworkImage(post.profileUrl)
                                  : AssetImage('assets/default_profile.png') as ImageProvider,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${createdAt.month}월 ${createdAt.day}일 ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite, size: 16, color: Colors.red.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.likeCount}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.comment_outlined, size: 16, color: Colors.blue.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.commentCount}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                        ),
                      ),
                    ),
                  );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/communityWrite');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }
}
