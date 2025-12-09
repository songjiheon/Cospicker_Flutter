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
  @override
  _CommunityMainScreenState createState() => _CommunityMainScreenState();
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: "제목/내용 키워드 검색",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: (text) => setState(() => _keyword = text.trim()),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
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

              return GestureDetector(
                onTap: () {
                  // 여기서 Post 전체가 아닌 postId만 전달
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityPostScreen(postId: post.postId),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 태그 / 유형 표시
                      Row(
                        children: [
                          if (post.tag.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: EdgeInsets.only(right: 6, bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#${post.tag}',
                                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                              ),
                            ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              post.postType,
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: post.profileUrl.isNotEmpty
                                ? NetworkImage(post.profileUrl)
                                : AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.userName, style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(post.postType, style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Spacer(),
                          Text("${createdAt.hour}:${createdAt.minute}", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(post.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 6),
                      Text(post.content,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('${post.likeCount}', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 10),
                          Icon(Icons.comment, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('${post.commentCount}', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/communityWrite');
        },
        child: Icon(Icons.edit),
        backgroundColor: Colors.black,
      ),
      bottomNavigationBar: Container(
        height: 52,
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _tagFilters.map((tag) {
            final label = tag.isEmpty ? '전체' : '#$tag';
            final selected = tag == _selectedTag;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedTag = selected ? '' : tag;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
