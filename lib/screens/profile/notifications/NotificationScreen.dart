import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  // 알림 타입별 아이콘 구분
  IconData _getIcon(String type) {
    switch (type) {
      case "message":
        return Icons.message_rounded;
      case "booking":
        return Icons.hotel_rounded;
      case "restaurant":
        return Icons.restaurant_rounded;
      case "system":
      default:
        return Icons.notifications_rounded;
    }
  }

  // 알림 읽음 처리
  Future<void> _markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(id)
        .update({"isRead": true});
  }

  // 전체 삭제
  Future<void> _deleteAll() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // 날짜 표시 포맷
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.year}.${date.month}.${date.day}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "알림",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _deleteAll,
            child: const Text(
              "전체삭제",
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          )
        ],
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("notifications")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "받은 알림이 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final isRead = data["isRead"] ?? false;
              final type = data["type"] ?? "system";

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection("notifications")
                      .doc(doc.id)
                      .delete();
                },

                child: GestureDetector(
                  onTap: () {
                    _markAsRead(doc.id);

                    // 알림 타입별 이동 처리
                    if (type == "message") {
                      Navigator.pushNamed(context, "/chatRoomList");
                    } else if (type == "booking") {
                      Navigator.pushNamed(context, "/myBookingList");
                    } else if (type == "restaurant") {
                      Navigator.pushNamed(context, "/myRestaurantBookings");
                    }
                  },

                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey[100] : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getIcon(type),
                          size: 30,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data["title"] ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                data["body"] ?? "",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                _formatDate(data["createdAt"]),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
