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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // 현재 사용자 정보 로드
  Future<void> _loadCurrentUser() async {
    final user = currentUser;
    if (user == null) return;
    _currentUserData = await _getUserInfo(user.uid);
    setState(() {});
  }

  //상대방 이름


  /// Firestore에서 사용자 정보 가져오기
  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data() ?? {"name": "익명", "profileImageUrl": ""};
  }

  /// 메시지 전송
  Future<void> _sendMessage({String? imageUrl}) async {
    if (_currentUserData == null) return; // 초기화 전이면 전송하지 않음
    String text = _controller.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final senderName = _currentUserData?["name"] ?? "익명";
    final senderPhoto = _currentUserData?["profileImageUrl"];

    final msgRef = FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .collection("messages");

    await msgRef.add({
      "message": text,
      "imageUrl": imageUrl,
      "senderUid": currentUser?.uid ?? "",
      "senderName": senderName,
      "senderPhoto": senderPhoto,
      "time": Timestamp.now(),
    });

    // 채팅방 리스트 업데이트
    await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(widget.roomId)
        .update({
      "lastMessage": imageUrl != null ? "📷사진" : text,
      "lastTime": Timestamp.now(),
    });

    _controller.clear();

    // 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// 이미지 선택 및 전송
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    File file = File(picked.path);
    String fileName = "chat_${widget.roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

    TaskSnapshot upload = await FirebaseStorage.instance.ref("chat_images/$fileName").putFile(file);
    String imageUrl = await upload.ref.getDownloadURL();

    await _sendMessage(imageUrl: imageUrl);
  }

  /// 타임스탬프 포맷
  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,

        title: Text("COSPICKER",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),),
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chatRooms")
                  .doc(widget.roomId)
                  .collection("messages")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: msgs.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final data = msgs[index];
                    final bool isMe = data["senderUid"] == currentUser?.uid;

                    return FutureBuilder<Map<String, dynamic>>(
                      future: isMe
                          ? Future.value(_currentUserData)
                          : _getUserInfo(data["senderUid"]),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data ?? {"name": "익명", "profileImageUrl": ""};

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isMe)
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: userData["profileImageUrl"] != ""
                                    ? NetworkImage(userData["profileImageUrl"])
                                    : null,
                                child: userData["profileImageUrl"] == ""
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            if (!isMe) const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData["name"] ?? "익명",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.blue.shade200
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (data["message"] != null &&
                                            data["message"] != "")
                                          Text(data["message"]),
                                        if (data["imageUrl"] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Image.network(
                                              data["imageUrl"],
                                              width: 180,
                                            ),
                                          ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _formatTime(data["time"]),
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 메시지 입력창
          Container(
            height: 60,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "메시지 입력...",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _sendMessage(),
                  child: const Text("전송"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
