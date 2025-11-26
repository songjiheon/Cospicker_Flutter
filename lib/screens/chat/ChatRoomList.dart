import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'CreateChatRoom.dart';

class ChatRoomListScreen extends StatelessWidget {
  final String uid;
  const ChatRoomListScreen({super.key, required this.uid});

  Future<Map<String, dynamic>> getOtherUserInfo(List members) async {
    // 내 uid를 제외한 상대방 uid
    String otherUid = members.firstWhere((m) => m != uid);
    final doc = await FirebaseFirestore.instance.collection("users").doc(otherUid).get();
    return doc.data() ?? {"name": "알수없음", "profileImageUrl": ""};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("채팅방 목록"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateChatRoomScreen(uid: uid),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chatRooms")
            .where("members", arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Center(child: Text("참여중인 채팅방이 없습니다."));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];

              return FutureBuilder<Map<String, dynamic>>(
                future: getOtherUserInfo(room["members"]),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final otherUser = userSnapshot.data!;
                  final bgColor = index % 2 == 0 ? Colors.grey[100] : Colors.white;

                  return Container(
                    color: bgColor,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: otherUser["profileImageUrl"] != ""
                            ? NetworkImage(otherUser["profileImageUrl"])
                            : null,
                        child: otherUser["profileImageUrl"] == ""
                            ? Image.asset(
                          "assets/profile_icon.png",
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      title: Text(otherUser["name"]),
                      subtitle: Text(room["lastMessage"] ?? "메시지 없음"),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/chatRoom",
                          arguments: room.id,
                        );
                      },
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
}
