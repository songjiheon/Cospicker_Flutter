import 'package:flutter/material.dart';

class StayListScreen extends StatelessWidget {
  final String location;
  final String date;
  final int people;

  const StayListScreen({
    super.key,
    required this.location,
    required this.date,
    required this.people,
  });

  @override
  Widget build(BuildContext context) {
    // 더미 데이터 → Firestore로 교체 가능
    final stays = [
      {
        "name": "가평 릴리브풀빌라",
        "location": "가평군 상면",
        "rating": 4.7,
        "review": 122,
        "price": 157100,
        "salePrice": 82000,
        "images": [
          "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=900",
        ],
      },
      {
        "name": "가평 오션뷰 펜션",
        "location": "가평군 청평면",
        "rating": 4.3,
        "review": 88,
        "price": 210000,
        "salePrice": 135000,
        "images": [
          "https://images.unsplash.com/photo-1560448071-9fa9c2a4d6d0?w=900",
        ],
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),

            _filterChips(),

            const SizedBox(height: 10),

            // ⭐⭐⭐ 리스트 + 상세 화면 이동 ⭐⭐⭐
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: stays.length,
                itemBuilder: (context, index) {
                  final stay = stays[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/stayDetail',
                        arguments: stay, // 🔥 stayData로 전달
                      );
                    },
                    child: _stayItem(stay),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- UI 파트 ------------------------

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.close, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.home, size: 28),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        children: [_chip("날짜 및 인원"), _chip("필터"), _chip("정렬")],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _stayItem(Map stay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              stay["images"][0],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 14),

          // 오른쪽 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge("이번주특가"),

                const SizedBox(height: 6),

                Text(
                  stay["name"],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stay["location"],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.star, size: 15, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text(
                      "${stay["rating"]} (${stay["review"]})",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      "${stay["price"]}원",
                      style: const TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "최대할인가",
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),

                Text(
                  "${stay["salePrice"]}원~",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6DFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
