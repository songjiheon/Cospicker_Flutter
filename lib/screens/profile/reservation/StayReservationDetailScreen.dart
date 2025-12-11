import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cospicker/screens/stay/StayRoomDetailScreen.dart';

class StayReservationScreen extends StatefulWidget {
  const StayReservationScreen({super.key});

  @override
  State<StayReservationScreen> createState() => _StayReservationScreenState();
}

class _StayReservationScreenState extends State<StayReservationScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);

    _autoUpdateCompletedReservations(); // 🔥 자동 완료 처리 실행
  }

  // ----------------------------------------------------------
  // 🔥 날짜 지나면 자동으로 completed 로 변경
  // ----------------------------------------------------------
  Future<void> _autoUpdateCompletedReservations() async {
    final today = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection("reservation")
        .where("uid", isEqualTo: uid)
        .where("status", isEqualTo: "upcoming")
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // date: "yyyy-mm-dd ~ yyyy-mm-dd"
      final date = data["date"];
      if (date == null || !date.contains("~")) continue;

      final parts = date.split("~");
      final checkOutStr = parts[1].trim();
      final checkOut = DateTime.tryParse(checkOutStr);

      if (checkOut == null) continue;

      if (today.isAfter(checkOut)) {
        await doc.reference.update({"status": "completed"});
        // 자동 완료 처리됨 (로깅 불필요)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("숙소 예약내역",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(text: "이용전"),
              Tab(text: "이용후"),
              Tab(text: "취소됨"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildList("upcoming"),
                _buildList("completed"),
                _buildList("canceled"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Firestore에서 상태별 목록 조회 ----------------
  Widget _buildList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("reservation")
          .where("uid", isEqualTo: uid)
          .where("status", isEqualTo: status)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.docs.isEmpty) {
          return _emptyView(status);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: snap.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _reservationCard(data, doc.id, status);
          }).toList(),
        );
      },
    );
  }

  // ---------------- 예약 없음 화면 ----------------
  Widget _emptyView(String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Text("해당되는 예약 내역이 없습니다.",
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 6),
            Text("숙소 찾아보기",
                style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ---------------- 예약 카드 ----------------
  Widget _reservationCard(Map<String, dynamic> data, String id, String status) {
    final date = data["date"];
    final roomName = data["roomName"];
    final people = data["people"];
    final price = data["price"];
    final roomImage = data["roomImage"] ?? "";

    String checkIn = "", checkOut = "";
    if (date != null && date.contains("~")) {
      final parts = date.split("~");
      checkIn = parts[0].trim();
      checkOut = parts[1].trim();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- 이미지 + 이름 ----------------
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: roomImage.isNotEmpty
                    ? Image.network(roomImage,
                    width: 90, height: 80, fit: BoxFit.cover)
                    : Container(
                  width: 90,
                  height: 80,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.hotel, size: 40),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(roomName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          ),

          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Text("$checkIn ~ $checkOut")
          ]),

          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.people, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Text("$people명")
          ]),

          const SizedBox(height: 10),
          Text("$price원",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),

          const SizedBox(height: 16),

          // ---------------- 버튼 영역 ----------------
          if (status == "upcoming") ...[
            _cancelButton(id),
            const SizedBox(height: 10),
            _rebookButton(data),
          ],

          if (status == "completed") _rebookButton(data),
        ],
      ),
    );
  }

  // ---------------- 예약 취소 버튼 ----------------
  Widget _cancelButton(String reservationId) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _showRefundBottomSheet(reservationId),
        child: const Text("예약 취소"),
      ),
    );
  }

  // ---------------- 다시 예약 버튼 ----------------
  Widget _rebookButton(Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StayRoomDetailScreen(
                roomData: {
                  "name": data["roomName"],
                  "price": data["price"],
                  "roomImage": data["roomImage"],
                },
                date: data["date"],
                people: data["people"],
              ),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text("다시 예약"),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔥 예약 취소 → 환불 규정 BottomSheet
  // ----------------------------------------------------------
  void _showRefundBottomSheet(String reservationId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("환불 규정",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("- 체크인 3일 전: 100% 환불"),
            const SizedBox(height: 4),
            const Text("- 체크인 2일 전: 70% 환불"),
            const SizedBox(height: 4),
            const Text("- 체크인 1일 전: 50% 환불"),
            const SizedBox(height: 4),
            const Text("- 체크인 당일: 환불 불가"),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection("reservation")
                      .doc(reservationId)
                      .update({"status": "canceled"});

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("예약이 취소되었습니다.")),
                  );
                },
                child: const Text("예약 취소 진행", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
