import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateChatRoomScreen extends StatefulWidget {
  final String uid;
  const CreateChatRoomScreen({super.key, required this.uid});

  @override
  State<CreateChatRoomScreen> createState() => _CreateChatRoomScreenState();
}

class _CreateChatRoomScreenState extends State<CreateChatRoomScreen> {
  final TextEditingController _friendCodeController = TextEditingController();
  bool loading = false;

  String createRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  Future<void> createRoom() async {
    setState(() => loading = true);

    String friendCode = _friendCodeController.text.trim();
    if (friendCode.isEmpty) {
      setState(() => loading = false);
      return;
    }

    // 🔎 친구코드로 상대 UID 조회
    final userQuery = await FirebaseFirestore.instance
        .collection("users")
        .where("friendCode", isEqualTo: friendCode)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("해당 친구코드를 가진 사용자가 없습니다.")),
      );
      return;
    }

    String targetUid = userQuery.docs.first.id;

    // 🚫 자기 자신 추가 방지
    if (targetUid == widget.uid) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("자기 자신은 추가할 수 없습니다.")),
      );
      return;
    }

    // 🔥 방 ID 생성
    String roomId = createRoomId(widget.uid, targetUid);

    // 🔥 기존 방 존재 확인
    final roomDoc = await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(roomId)
        .get();

    if (roomDoc.exists) {
      setState(() => loading = false);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/chatRoom", arguments: roomId);
      return;
    }

    // 🔥 없다면 방 생성
    await FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(roomId)
        .set({
      "members": [widget.uid, targetUid],
      "createdAt": FieldValue.serverTimestamp(),
      "lastMessage": "",
    });

    setState(() => loading = false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/chatRoom", arguments: roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("채팅방 생성")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _friendCodeController,
              decoration: const InputDecoration(
                labelText: "친구 코드 입력",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : createRoom,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("채팅방 생성"),
            ),
          ],
        ),
      ),
    );
  }
}



