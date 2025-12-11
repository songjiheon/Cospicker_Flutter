import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final currentUser = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? _currentUserData;

  String? otherUid;
  Map<String, dynamic>? otherUserData;

  bool isTyping = false; // 상대 typing 여부

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadRoomUsers();
  }

  @override
  void dispose() {
    _updateTyping(false);
    super.dispose();
  }
  // ---------------------------
  // 현재 유저 정보 로드
  // ---------------------------
  Future<void> _loadCurrentUser() async {
    _currentUserData = await _getUserInfo(currentUser.uid);
    setState(() {});
  }

  // ---------------------------
  // 채팅방 멤버 로드 (상대방 UID 찾기)
  // ---------------------------
  Future<void> _loadRoomUsers() async {
    final doc = await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .get();

    if (!doc.exists) {
      // 채팅방이 존재하지 않으면 뒤로가기
      if (mounted) Navigator.pop(context);
      return;
    }

    final members = (doc["users"] as List<dynamic>?) ?? [];
    otherUid = members.firstWhere(
      (uid) => uid != currentUser.uid,
      orElse: () => null,
    ) as String?;

    if (otherUid == null) {
      // 상대방을 찾을 수 없으면 뒤로가기
      if (mounted) Navigator.pop(context);
      return;
    }

    otherUserData = await _getUserInfo(otherUid!);
    setState(() {});

    _listenTypingStatus();
  }

  // ---------------------------
  // Firestore 유저 정보 가져오기
  // ---------------------------
  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    return doc.data() ??
        {
          "name": "익명",
          "profileImageUrl": "",
          "status": "",
        };
  }

  // ---------------------------
  // 메시지 전송
  // ---------------------------
  Future<void> _sendMessage({String? imageUrl}) async {
    if (_currentUserData == null) return;

    String text = _controller.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    await _updateTyping(false);

    final msgRef = FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .collection("messages");

    await msgRef.add({
      "message": text,
      "imageUrl": imageUrl,
      "senderUid": currentUser.uid,
      "senderName": (_currentUserData?["name"] as String?) ?? "익명",
      "senderPhoto": (_currentUserData?["profileImageUrl"] as String?) ?? "",
      "time": Timestamp.now(),
      "seenBy": [currentUser.uid],
    });

    // 채팅방 업데이트
    await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .update({
      "lastMessage": imageUrl != null ? "📷 사진을 보냈습니다" : text,
      "lastTime": Timestamp.now(),
    });

    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent + 50,
        );
      }
    });
  }

  // ---------------------------
  // 이미지 선택
  // ---------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    File file = File(picked.path);
    String fileName =
        "chat_${widget.roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

    TaskSnapshot upload = await FirebaseStorage.instance
        .ref("chat_images/$fileName")
        .putFile(file);

    String url = await upload.ref.getDownloadURL();
    await _sendMessage(imageUrl: url);
  }

  // ---------------------------
  // 읽음 처리
  // ---------------------------
  Future<void> _markAsSeen(String messageId) async {
    await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .collection("messages")
        .doc(messageId)
        .update({
      "seenBy": FieldValue.arrayUnion([currentUser.uid])
    });
  }

  Widget _buildReadStatus(List<dynamic> seenBy) {
    final otherSeen = seenBy.any((id) => id != currentUser.uid);

    return Padding(
      padding: const EdgeInsets.only(top: 3, right: 5),
      child: Text(
        otherSeen ? "✔✔" : "✔",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: otherSeen ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  // ---------------------------
  // Typing 기능
  // ---------------------------
  Future<void> _updateTyping(bool typing) async {
    if (otherUid == null) return;

    await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .collection("typing")
        .doc(currentUser.uid)
        .set({"typing": typing});
  }

  void _listenTypingStatus() {
    if (otherUid == null) return;

    FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .collection("typing")
        .doc(otherUid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      setState(() {
        isTyping = doc["typing"] == true;
      });
    });
  }

  // ---------------------------
  // 시간 표시
  // ---------------------------
  String _formatTime(dynamic ts) {
    if (ts is! Timestamp) return "";
    final date = ts.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // ---------------------------
  // 메뉴 기능 (차단 / 신고 / 나가기)
  // ---------------------------
  void _openMenu() {
    if (otherUid == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text("차단하기"),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(currentUser.uid)
                  .update({
                "blocked": FieldValue.arrayUnion([otherUid])
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text("신고하기"),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection("reports")
                  .add({
                "reporter": currentUser.uid,
                "target": otherUid,
                "roomId": widget.roomId,
                "time": Timestamp.now(),
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text("채팅방 나가기"),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection("chatRooms")
                  .doc(widget.roomId)
                  .update({
                "users": FieldValue.arrayRemove([currentUser.uid])
              });
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }
  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final otherName = otherUserData?["name"] ?? "상대방";
    final statusMsg = otherUserData?["status"] ?? "";
    final profileImg = otherUserData?["profileImageUrl"] ?? "";

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),

        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: profileImg.isNotEmpty
                  ? NetworkImage(profileImg)
                  : const AssetImage("assets/default_profile.png")
              as ImageProvider,
            ),
            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherName,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  isTyping ? "입력 중..." : statusMsg,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
              ],
            )
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _openMenu,
          )
        ],
      ),

      body: Column(
        children: [
          // ---------------- 메시지 목록 ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chatRooms")
                  .doc(widget.roomId)
                  .collection("messages")
                  .orderBy("time", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final bool isMe = (m["senderUid"] as String?) == currentUser.uid;

                    _markAsSeen(m.id);
                    
                    // null-safe 처리
                    final senderPhoto = (m["senderPhoto"] as String?) ?? "";
                    final message = (m["message"] as String?) ?? "";
                    final imageUrl = (m["imageUrl"] as String?) ?? "";
                    final seenBy = (m["seenBy"] as List<dynamic>?) ?? [];

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,

                      children: [
                        if (!isMe)
                          CircleAvatar(
                            radius: 18,
                            child: senderPhoto.isNotEmpty
                                ? ClipOval(
                              child: Image.network(
                                senderPhoto,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person);
                                },
                              ),
                            )
                                : const Icon(Icons.person),
                          ),
                        if (!isMe) const SizedBox(width: 8),

                        // ===== 말풍선 영역 =====
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin:
                                const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue.shade200
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: [
                                    if (message.isNotEmpty)
                                      Text(
                                        message,
                                        style: const TextStyle(fontSize: 15),
                                      ),

                                    if (imageUrl.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          child: Image.network(
                                            imageUrl,
                                            width: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const SizedBox(
                                                width: 180,
                                                height: 100,
                                                child: Icon(Icons.error),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(m["time"]),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),

                              // 읽음 여부
                              if (isMe) _buildReadStatus(seenBy),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ---------------- 입력창 ----------------
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, size: 28),
                  onPressed: _pickImage,
                ),

                // 메시지 입력 필드
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (v) => _updateTyping(v.isNotEmpty),
                    decoration: InputDecoration(
                      hintText: "메시지 입력...",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // 전송 버튼
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
