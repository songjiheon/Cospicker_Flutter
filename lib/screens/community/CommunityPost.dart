import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class Post {
  final String postId;
  final String uid;
  final String title;
  final String content;
  final DateTime createdAt;
  final String userName;
  final String profileUrl;
  final String postType;
  final int likeCount;
  final int commentCount;
  final String imageUrl;

  Post({
    required this.postId,
    required this.title,
    required this.uid,
    required this.content,
    required this.createdAt,
    required this.userName,
    required this.profileUrl,
    required this.postType,
    required this.likeCount,
    required this.commentCount,
    required this.imageUrl,
  });

  // Firestore 문서로부터 Post 객체 생성
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String? profileUrlData = data['profileUrl'] is String ? data['profileUrl'] : null;
    final String? imageUrlData = data['imageUrl'] is String ? data['imageUrl'] : null;

    return Post(
      postId: data['postId'] ?? doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userName: data['userName'] ?? '익명',
      profileUrl: profileUrlData ?? '',
      postType: data['postType'] ?? '자유',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      imageUrl: imageUrlData ?? '',
    );
  }
}

class CommunityPostScreen extends StatefulWidget {
  final String postId; // postId만 전달

  const CommunityPostScreen({super.key, required this.postId});

  @override
  createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPostScreen> {
  Post? post;
  bool isLiked = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadPost() async {
    final doc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .get();

    if (!doc.exists) return;

    setState(() {
      post = Post.fromFirestore(doc);
    });

    _checkIfLiked();
  }

  void _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || post == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(post!.postId)
        .collection('Likes')
        .doc(user.uid)
        .get();

    setState(() {
      isLiked = doc.exists;
    });
  }

  void _toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likeDoc = FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .collection('Likes')
        .doc(user.uid);

    if (isLiked) {
      await likeDoc.delete();
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeDoc.set({'uid': user.uid, 'createdAt': Timestamp.now()});
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .update({'likeCount': FieldValue.increment(1)});
    }

    setState(() {
      isLiked = !isLiked;
    });
  }

  void _addComment(String postId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userName = userDoc.data()?['name'] ?? '익명';
    final profileUrl = userDoc.data()?['profileImageUrl'] ?? '';

    await FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .add({
      'uid': user.uid,
      'userName': userName,
      'profileUrl': profileUrl,
      'content': content,
      'createdAt': Timestamp.now(),
      'postId': postId,
    });

    await FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .update({'commentCount': FieldValue.increment(1)});

    _commentController.clear();


  }
  void _showEditDialog() {
    final titleController = TextEditingController(text: post!.title);
    final contentController = TextEditingController(text: post!.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("게시글 수정"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: "제목"),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(labelText: "내용"),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = titleController.text.trim();
                final newContent = contentController.text.trim();

                if (newTitle.isEmpty || newContent.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('Posts')
                    .doc(post!.postId)
                    .update({
                  'title': newTitle,
                  'content': newContent,
                });

                if (!mounted) return;
                setState(() {
                  post = Post(
                    uid: post!.uid,
                    postId: post!.postId,
                    title: newTitle,
                    content: newContent,
                    createdAt: post!.createdAt,
                    userName: post!.userName,
                    profileUrl: post!.profileUrl,
                    postType: post!.postType,
                    likeCount: post!.likeCount,
                    commentCount: post!.commentCount,
                    imageUrl: post!.imageUrl,
                  );
                });

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text("저장"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("게시글 상세", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          elevation: 1,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final createdAt = post!.createdAt;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("게시글 상세", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          if (FirebaseAuth.instance.currentUser?.uid == post?.uid) // 작성자만 보이도록
            IconButton(
              icon: Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                _showEditDialog();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 + 시간
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post!.profileUrl.isNotEmpty
                            ? NetworkImage(post!.profileUrl)
                            : AssetImage('assets/default_profile.png')
                        as ImageProvider,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post!.userName,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(post!.postType,
                              style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Spacer(),
                      Text("${createdAt.hour}:${createdAt.minute}",
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 16),

                  Text(post!.title,
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),

                  //이미지 표시
                  Text(post!.content, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  if (post!.imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.network(
                        post!.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                  SizedBox(height: 16),

                  // 좋아요 + 댓글 (실시간)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Posts')
                        .doc(post!.postId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      final postData =
                      snapshot.data!.data() as Map<String, dynamic>;

                      final likeCount = postData['likeCount'] ?? 0;
                      final commentCount = postData['commentCount'] ?? 0;

                      return Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _toggleLike(post!.postId),
                          ),
                          Text('$likeCount'),
                          SizedBox(width: 16),
                          Icon(Icons.comment, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('$commentCount'),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 8),
                  Text("댓글",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),

                  // 댓글 리스트
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Posts')
                        .doc(post!.postId)
                        .collection('Comments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Text("댓글 없음");

                      final comments = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final data =
                          comments[index].data() as Map<String, dynamic>;
                          final commentId = comments[index].id;
                          final commentUid = data['uid'] ?? '';
                          final commentTime =
                          (data['createdAt'] as Timestamp).toDate();
                          void showEditCommentDialog() {
                            final commentController =
                            TextEditingController(text: data['content']);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("댓글 수정"),
                                content: TextField(
                                  controller: commentController,
                                  maxLines: 3,
                                  decoration: InputDecoration(hintText: "댓글 내용"),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("취소"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final newContent = commentController.text.trim();
                                      if (newContent.isEmpty) return;
                                      await FirebaseFirestore.instance
                                          .collection('Posts')
                                          .doc(post!.postId)
                                          .collection('Comments')
                                          .doc(commentId)
                                          .update({'content': newContent});
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    },
                                    child: Text("저장"),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  radius: 16,
                                  backgroundImage:
                                  (data['profileUrl'] != null &&
                                      data['profileUrl'] != "")
                                      ? NetworkImage(data['profileUrl'])
                                      : AssetImage(
                                      'assets/profile_icon.png')
                                  as ImageProvider,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(data['userName'] ?? '익명',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(data['content'] ?? ''),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${commentTime.hour}:${commentTime.minute}",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                if(FirebaseAuth.instance.currentUser?.uid == commentUid)
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 18),
                                    onPressed: showEditCommentDialog,
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 댓글 입력창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "댓글을 입력하세요",
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addComment(post!.postId),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    backgroundColor: Colors.black,
                  ),
                  child: Text("완료"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
