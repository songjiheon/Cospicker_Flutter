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

  User? get currentUser => FirebaseAuth.instance.currentUser;
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
    final user = currentUser;
    if (user == null) return;
    _currentUserData = await _getUserInfo(user.uid);
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

    List members = doc["users"];
    final user = currentUser;
    if (user == null) return;
    otherUid = members.firstWhere((uid) => uid != user.uid);

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

    final user = currentUser;
    if (user == null) return;
    await msgRef.add({
      "message": text,
      "imageUrl": imageUrl,
      "senderUid": user.uid,
      "senderName": _currentUserData?["name"],
      "senderPhoto": _currentUserData?["profileImageUrl"],
      "time": Timestamp.now(),
      "seenBy": [user.uid],
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
      "seenBy": FieldValue.arrayUnion([currentUser?.uid ?? ""])
    });
  }

  Widget _buildReadStatus(List seenBy) {
    final user = currentUser;
    if (user == null) return const SizedBox.shrink();
    final otherSeen = seenBy.any((id) => id != user.uid);

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
    final user = currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .collection("typing")
        .doc(user.uid)
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
              final user = currentUser;
              if (user == null) return;
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .update({
                "blocked": FieldValue.arrayUnion([otherUid])
              });
              if (!mounted) return;
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
                "reporter": currentUser?.uid ?? "",
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
                "users": FieldValue.arrayRemove([currentUser?.uid ?? ""])
              });
              if (!mounted) return;
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
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: profileImg.isNotEmpty
                    ? NetworkImage(profileImg)
                    : const AssetImage("assets/default_profile.png") as ImageProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    isTyping ? "입력 중..." : statusMsg,
                    style: TextStyle(
                      color: isTyping ? Colors.blue.shade600 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.black87, size: 20),
            ),
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
                    final bool isMe = m["senderUid"] == currentUser?.uid;

                    _markAsSeen(m.id);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,

                      children: [
                        if (!isMe)
                          CircleAvatar(
                            radius: 18,
                            child: m["senderPhoto"] != null &&
                                m["senderPhoto"] != ""
                                ? ClipOval(
                              child: Image.network(
                                m["senderPhoto"],
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? LinearGradient(
                                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isMe ? null : Colors.grey.shade200,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isMe
                                          ? Colors.blue.withValues(alpha: 0.2)
                                          : Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: [
                                    if (m["message"] != "")
                                      Text(
                                        m["message"],
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isMe ? Colors.white : Colors.black87,
                                        ),
                                      ),

                                    if (m["imageUrl"] != null &&
                                        m["imageUrl"] != "")
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          child: Image.network(
                                            m["imageUrl"],
                                            width: 180,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(m["time"]),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white.withValues(alpha: 0.8)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 읽음 여부
                              if (isMe) _buildReadStatus(m["seenBy"] ?? []),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.photo_camera_outlined, size: 24, color: Colors.grey.shade700),
                      onPressed: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 메시지 입력 필드
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        onChanged: (v) => _updateTyping(v.isNotEmpty),
                        decoration: InputDecoration(
                          hintText: "메시지를 입력하세요...",
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 전송 버튼
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
