import 'package:flutter/material.dart';
import 'package:cospicker/screens/stay/StayPaymentScreen.dart';

class StayRoomDetailScreen extends StatelessWidget {
  final Map<String, dynamic> roomData;
  final String? date;        // nullable 로 변경 → 다시예약 때 null일 수 있음
  final int? people;         // nullable → 기본값 필요

  const StayRoomDetailScreen({
    super.key,
    required this.roomData,
    this.date,
    this.people,
  });

  @override
  Widget build(BuildContext context) {
    // ---- 기본값 설정 ----
    final safeDate = date ?? "날짜를 선택해주세요";
    final safePeople = people ?? 2;

    final List images = [roomData["roomImage"] ?? ""];

    return Scaffold(
      backgroundColor: Colors.white,

      // -------------------- 하단 예약 버튼 --------------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // 날짜 선택 안된 경우 경고
              if (date == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("예약하려면 날짜를 먼저 선택해주세요."),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StayPaymentScreen(
                    paymentData: {
                      "roomName": roomData["name"],
                      "price": roomData["price"],
                      "date": safeDate,
                      "people": safePeople,
                    },
                  ),
                ),
              );
            },
            child: const Text(
              "예약하기",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),

      // -------------------- 본문 --------------------
      body: Column(
        children: [
          // 이미지 슬라이드
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (_, i) {
                    return Image.network(
                      images[i],
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 260,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, size: 60),
                      ),
                    );
                  },
                ),

                // 뒤로가기 버튼
                Positioned(
                  top: 40,
                  left: 16,
                  child: _circleButton(
                    Icons.arrow_back_ios_new,
                        () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // =================== 스크롤 영역 ===================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 객실명
                  Text(
                    roomData["name"] ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 날짜 & 인원
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        safeDate,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.people_alt_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text("$safePeople명"),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  // 가격 정보
                  Text(
                    "${roomData["price"]}원 / 1박",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6DFF),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    "기준 ${roomData["standard"]}명 · 최대 ${roomData["max"]}명",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // 방 설명
                  const Text(
                    "객실 정보",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    roomData["description"] ?? "해당 객실에 대한 설명이 없습니다.",
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 30),

                  // 옵션
                  const Text(
                    "객실 옵션",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _optionItem(Icons.bed, "침대 타입: 더블베드"),
                  _optionItem(Icons.shower, "욕실 / 어메니티 제공"),
                  _optionItem(Icons.air, "에어컨 / 난방"),
                  _optionItem(Icons.tv, "TV / OTT 시청 가능"),
                  _optionItem(Icons.wifi, "무료 Wi-Fi 제공"),
                  _optionItem(Icons.local_parking, "주차장 이용 가능"),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- 옵션 아이템 --------------------
  Widget _optionItem(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  // -------------------- 원형 버튼 --------------------
  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}
