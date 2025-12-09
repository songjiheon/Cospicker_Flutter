import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomListScreen extends StatelessWidget {
  const ChatRoomListScreen({super.key});

  /// 현재 로그인한 사용자 UID
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  /// 유저 정보 가져오기
  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data() ?? {"name": "익명", "profileImageUrl": ""};
  }

  /// 시간 포맷
  String _formatTime(Timestamp? time) {
    if (time == null) return "";
    final date = time.toDate();
    return "${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "COSPICKER",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              "채팅",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chatRooms")
                  .where("users", arrayContains: uid)
                  .orderBy("lastTime", descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data!.docs;

                if (rooms.isEmpty) {
                  return const Center(child: Text("채팅방이 없습니다."));
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
                  builder: (context, meSnapshot) {
                    if (!meSnapshot.hasData) return const SizedBox();

                    final userData = meSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final blocked = List<String>.from(userData["blocked"] ?? []);
                    final muted = List<String>.from(userData["muteUsers"] ?? []);

                    /// 🔥 필터링: 차단된 상대 제외
                    final filteredRooms = rooms.where((room) {
                      final users = List<String>.from(room["users"]);
                      final otherUid = users.firstWhere((e) => e != uid, orElse: () => "");

                      // 내가 차단한 사람은 숨김
                      if (blocked.contains(otherUid)) return false;

                      return true;
                    }).toList();

                    if (filteredRooms.isEmpty) {
                      return const Center(child: Text("표시할 채팅방이 없습니다."));
                    }

                    return ListView.builder(
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        final room = filteredRooms[index];
                        final users = List<String>.from(room["users"]);
                        final otherUid = users.firstWhere((e) => e != uid, orElse: () => "");

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _getUserInfo(otherUid),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) {
                              return const SizedBox(height: 60);
                            }

                            final other = userSnap.data!;
                            final lastMessage = room["lastMessage"] ?? "메시지가 없습니다.";
                            final lastTime = room["lastTime"];

                            final isMuted = muted.contains(otherUid);

                            return InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  "/chatRoom",
                                  arguments: room.id,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 27,
                                      backgroundImage: other["profileImageUrl"] != ""
                                          ? NetworkImage(other["profileImageUrl"])
                                          : null,
                                      child: other["profileImageUrl"] == ""
                                          ? const Icon(Icons.person, size: 32)
                                          : null,
                                    ),

                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                other["name"],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),

                                              if (isMuted)
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 4),
                                                  child: Icon(Icons.volume_off,
                                                      size: 16, color: Colors.grey),
                                                ),
                                            ],
                                          ),

                                          const SizedBox(height: 4),
                                          Text(
                                            lastMessage,
                                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (lastTime != null)
                                      Text(
                                        _formatTime(lastTime),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
