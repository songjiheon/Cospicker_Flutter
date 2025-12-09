import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/chat/ChatRoomScreen.dart';

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

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Post(
      postId: data['postId'] ?? doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userName: data['userName'] ?? '익명',
      profileUrl: data['profileUrl'] ?? '',
      postType: data['postType'] ?? '자유',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class CommunityPostScreen extends StatefulWidget {
  final String postId;

  const CommunityPostScreen({super.key, required this.postId});

  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  Post? post;
  bool isLiked = false;

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  String? replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final doc = await FirebaseFirestore.instance
        .collection("Posts")
        .doc(widget.postId)
        .get();

    if (doc.exists) {
      setState(() {
        post = Post.fromFirestore(doc);
      });
      _checkIfLiked();
    }
  }

  Future<void> _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || post == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("Posts")
        .doc(post!.postId)
        .collection("Likes")
        .doc(user.uid)
        .get();

    setState(() {
      isLiked = doc.exists;
    });
  }

  Future<void> _toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likeDoc = FirebaseFirestore.instance
        .collection("Posts")
        .doc(postId)
        .collection("Likes")
        .doc(user.uid);

    if (isLiked) {
      await likeDoc.delete();
      await FirebaseFirestore.instance
          .collection("Posts")
          .doc(postId)
          .update({"likeCount": FieldValue.increment(-1)});
    } else {
      await likeDoc.set({
        "uid": user.uid,
        "createdAt": Timestamp.now(),
      });
      await FirebaseFirestore.instance
          .collection("Posts")
          .doc(postId)
          .update({"likeCount": FieldValue.increment(1)});
    }

    setState(() => isLiked = !isLiked);
  }

  // ---------------------------
  // 댓글 + 대댓글 추가
  // ---------------------------
  Future<void> _addComment({String? parentId}) async {
    final text = parentId == null
        ? _commentController.text.trim()
        : _replyController.text.trim();

    if (text.isEmpty || post == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
    await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(post!.postId)
        .collection("Comments")
        .add({
      "uid": user.uid,
      "userName": userDoc["name"] ?? "익명",
      "profileUrl": userDoc["profileImageUrl"] ?? "",
      "content": text,
      "createdAt": Timestamp.now(),
      "postId": post!.postId,
      "parentId": parentId,
    });

    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(post!.postId)
        .update({"commentCount": FieldValue.increment(1)});

    if (parentId == null) {
      _commentController.clear();
    } else {
      _replyController.clear();
      setState(() => replyingToCommentId = null);
    }
  }

  // =============================================================
  // 🔥 FIXED: DM 방 생성 — lastTime을 null로 설정해야 목록에 정상 표시됨
  // =============================================================
  Future<String> _createChatRoom(String otherUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인 상태가 아닙니다.');
    }
    final myUid = user.uid;

    final roomId = myUid.compareTo(otherUid) < 0
        ? "${myUid}_$otherUid"
        : "${otherUid}_$myUid";

    final roomRef = FirebaseFirestore.instance.collection("chatRooms").doc(roomId);
    final doc = await roomRef.get();

    if (!doc.exists) {
      await roomRef.set({
        "users": [myUid, otherUid],
        "createdAt": Timestamp.now(),
        "lastMessage": "대화를 시작해보세요!",
        "lastTime": Timestamp.now(),
        "muteUsers": [],
      });
    } else {
      await roomRef.set({
        "users": [myUid, otherUid],
        "lastTime": Timestamp.now(),
      }, SetOptions(merge: true));
    }

    return roomId;
  }


  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("게시글 상세"),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _postHeader(),
                  const SizedBox(height: 16),
                  _postContent(),
                  const SizedBox(height: 20),
                  _postActions(),
                  const Divider(),
                  const Text("댓글",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _commentList(),
                ],
              ),
            ),
          ),
          _commentInputArea(),
        ],
      ),
    );
  }
  // ------------------ UI : 게시글 상단 ------------------
  Widget _postHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: post!.profileUrl.isNotEmpty
              ? NetworkImage(post!.profileUrl)
              : const AssetImage("assets/default_profile.png")
          as ImageProvider,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post!.userName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              post!.postType,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          "${post!.createdAt.hour.toString().padLeft(2, '0')}:${post!.createdAt.minute.toString().padLeft(2, '0')}",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  // ------------------ UI : 게시글 내용 ------------------
  Widget _postContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post!.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(post!.content, style: const TextStyle(fontSize: 16)),
        if (post!.imageUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(post!.imageUrl),
          ),
        ],
      ],
    );
  }

  // ------------------ UI : 좋아요 / 댓글 / DM ------------------
  Widget _postActions() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Posts")
          .doc(post!.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final likeCount = data["likeCount"] ?? 0;
        final commentCount = data["commentCount"] ?? 0;

        return Row(
          children: [
            IconButton(
              icon: Icon(Icons.favorite,
                  color: isLiked ? Colors.red : Colors.grey),
              onPressed: () => _toggleLike(post!.postId),
            ),
            Text("$likeCount"),
            const SizedBox(width: 20),
            const Icon(Icons.chat_bubble_outline),
            Text(" $commentCount"),
            const SizedBox(width: 20),

            // DM 버튼
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                final otherUid = post!.uid;
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인 상태가 아닙니다.')),
                  );
                  return;
                }
                final myUid = user.uid;

                if (otherUid == myUid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("본인에게 메시지를 보낼 수 없습니다.")),
                  );
                  return;
                }

                final roomId = await _createChatRoom(otherUid);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(roomId: roomId),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ------------------ UI : 댓글 + 대댓글 리스트 ------------------
  Widget _commentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Posts")
          .doc(post!.postId)
          .collection("Comments")
          .orderBy("createdAt", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final all = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            "id": doc.id,
            "parentId": data["parentId"], // null or string
          };
        }).toList();

        final parents = all.where((c) => c["parentId"] == null).toList();
        final replies = all.where((c) => c["parentId"] != null).toList();

        return Column(
          children: parents.map((parent) {
            final parentId = parent["id"];

            final childReplies =
            replies.where((r) => r["parentId"] == parentId).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _commentItem(parent, isReply: false),

                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Column(
                    children: childReplies
                        .map((reply) => _commentItem(reply, isReply: true))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  // ------------------ UI : 개별 댓글 ------------------
  Widget _commentItem(Map<String, dynamic> c, {required bool isReply}) {
    final createdAt = (c["createdAt"] as Timestamp?)?.toDate();
    final timeString = createdAt == null
        ? ""
        : "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 14 : 18,
          backgroundImage: (c["profileUrl"] ?? "").isNotEmpty
              ? NetworkImage(c["profileUrl"])
              : const AssetImage("assets/default_profile.png")
          as ImageProvider,
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    c["userName"] ?? "익명",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeString,
                    style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(c["content"] ?? ""),
              const SizedBox(height: 4),

              GestureDetector(
                onTap: () {
                  setState(() => replyingToCommentId = c["id"]);
                },
                child: Text(
                  "답글쓰기",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------ UI : 댓글 입력창 ------------------
  Widget _commentInputArea() {
    final isReplying = replyingToCommentId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          if (isReplying)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "답글 작성 중...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => setState(() => replyingToCommentId = null),
                  child: const Text("취소",
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: isReplying
                      ? _replyController
                      : _commentController,
                  decoration: InputDecoration(
                    hintText:
                    isReplying ? "답글을 입력하세요" : "댓글을 입력하세요",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              ElevatedButton(
                onPressed: () =>
                    _addComment(parentId: replyingToCommentId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("완료"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
