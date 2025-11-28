import 'package:flutter/material.dart';

class StayDetailScreen extends StatefulWidget {
  final Map stayData;

  const StayDetailScreen({super.key, required this.stayData});

  @override
  State<StayDetailScreen> createState() => _StayDetailScreenState();
}

class _StayDetailScreenState extends State<StayDetailScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final stay = widget.stayData;

    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // ▣ 상단 이미지 슬라이더
          SizedBox(
            height: 330,
            child: PageView.builder(
              itemCount: (stay["images"] as List).length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
              },
              itemBuilder: (context, i) {
                return Image.network(stay["images"][i], fit: BoxFit.cover);
              },
            ),
          ),

          // ▣ 상단 뒤로가기 버튼
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          // ▣ 이미지 하단 인디케이터
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 290,
            child: _buildBottomSheet(stay),
          ),
        ],
      ),

      // ▣ 하단 예약 버튼
      bottomNavigationBar: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "${stay['salePrice']}원 예약하기",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ------------------------ UI 세부 파트 ------------------------

  Widget _buildBottomSheet(Map stay) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: ListView(
        children: [
          _indicator(stay),

          const SizedBox(height: 14),

          // ▣ 숙소명
          Text(
            stay["name"],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          // ▣ 위치
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                stay["location"],
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ▣ 평점
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFB800)),
              const SizedBox(width: 3),
              Text(
                "${stay["rating"]}  (${stay["review"]} 리뷰)",
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ▣ 가격 영역
          _priceSection(stay),

          const Divider(height: 30, thickness: 1),

          // ▣ 편의시설 영역
          _amenities(),

          const Divider(height: 30, thickness: 1),

          // ▣ 상세 설명
          const Text(
            "숙소 소개",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            stay["description"] ?? "아늑한 객실과 프라이빗한 공간을 제공하는 인기 숙소입니다.",
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ▣ 이미지 인디케이터
  Widget _indicator(Map stay) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        (stay["images"] as List).length,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == i ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == i ? Colors.blueAccent : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // ▣ 가격 영역
  Widget _priceSection(Map stay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "${stay["price"]}원",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "최대할인가",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "${stay["salePrice"]}원~",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  // ▣ 편의시설
  Widget _amenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "편의시설",
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        Row(
          children: const [
            _amenityItem(Icons.wifi, "무료 와이파이"),
            SizedBox(width: 20),
            _amenityItem(Icons.local_parking, "주차 가능"),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            _amenityItem(Icons.pool, "수영장"),
            SizedBox(width: 20),
            _amenityItem(Icons.restaurant, "조식 제공"),
          ],
        ),
      ],
    );
  }
}

// 편의시설 아이템
class _amenityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _amenityItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.blueAccent),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
