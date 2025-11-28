import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'StayRoomDetailScreen.dart';

class StayRoomListScreen extends StatelessWidget {
  final Map<String, dynamic> stayData;
  final String date;
  final int people;

  const StayRoomListScreen({
    super.key,
    required this.stayData,
    required this.date,
    required this.people,
  });

  @override
  Widget build(BuildContext context) {
    final stayId = stayData["id"];

    return Scaffold(
      appBar: AppBar(
        title: Text("${stayData["name"]} 객실 목록"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rooms")
            .where("stayId", isEqualTo: stayId)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Center(child: Text("등록된 객실이 없습니다."));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StayRoomDetailScreen(
                        roomData: data,
                        date: date,
                        people: people,
                      ),
                    ),
                  );
                },
                child: _roomCard(data),
              );
            },
          );
        },
      ),
    );
  }

  Widget _roomCard(Map data) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              data["images"][0],
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["name"],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  "기준 ${data["standard"]}명 · 최대 ${data["max"]}명",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),

                const SizedBox(height: 6),

                Text(
                  "${data["price"]}원",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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
