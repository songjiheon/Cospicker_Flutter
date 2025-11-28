import 'package:flutter/material.dart';
import 'StayDatePeopleScreen.dart';
import 'StayReviewScreen.dart';
import 'StayRoomListScreen.dart'; // ⭐ 객실 보기 화면 추가

class StayDetailScreen extends StatefulWidget {
  final Map<String, dynamic> stayData;

  const StayDetailScreen({super.key, required this.stayData});

  @override
  State<StayDetailScreen> createState() => _StayDetailScreenState();
}

class _StayDetailScreenState extends State<StayDetailScreen> {
  String dateRange = "12.3 - 12.5";
  int people = 2;

  void _popWithResult() {
    Navigator.pop(context, {"date": dateRange, "people": people});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _popWithResult();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        // -------------------- 하단 버튼 --------------------
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

              // ⭐ 모든 객실 보기 화면 이동!
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StayRoomListScreen(
                      stayData: widget.stayData,
                      date: dateRange,
                      people: people,
                    ),
                  ),
                );
              },

              child: const Text(
                "모든 객실 보기",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        body: Column(
          children: [
            _imageHeader(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleSection(),
                    _reviewSection(context),
                    _datePeopleSection(context),
                    _facilitySection(),

                    const SizedBox(height: 10),

                    _mapSection(),
                    const SizedBox(height: 20),

                    _detailInfoSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------- 이미지 -------------------------------
  Widget _imageHeader() {
    final images = widget.stayData["images"] ?? [];

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            itemBuilder: (_, i) {
              return Image.network(
                images[i],
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 280,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 60),
                  ),
                ),
              );
            },
          ),

          Positioned(
            top: 40,
            left: 16,
            child: _circleButton(Icons.arrow_back_ios_new, _popWithResult),
          ),

          Positioned(
            top: 40,
            right: 16,
            child: _circleButton(Icons.favorite_border, () {}),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
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
        child: Icon(icon, color: Colors.black87, size: 18),
      ),
    );
  }

  // ------------------------------- 제목 -------------------------------
  Widget _titleSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.stayData["name"] ?? "",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Text(widget.stayData["location"] ?? ""),
            ],
          ),

          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.phone, size: 16),
              SizedBox(width: 4),
              Text("02-1234-5678"),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------- 리뷰 -------------------------------
  Widget _reviewSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                "${widget.stayData['rating']} (${widget.stayData['review']})",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StayReviewScreen(
                        stayName: widget.stayData["name"],
                        rating: widget.stayData["rating"] * 1.0,
                        reviewImages: List<String>.from(
                          widget.stayData["reviewImages"] ?? [],
                        ),
                      ),
                    ),
                  );
                },
                child: const Text(
                  "전체보기 >",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: const [
              Expanded(child: _ReviewBox()),
              SizedBox(width: 12),
              Expanded(child: _ReviewBox()),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------- 날짜/인원 -------------------------------
  Widget _datePeopleSection(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StayDatePeopleScreen()),
        );

        if (result != null) {
          setState(() {
            dateRange = result["date"] ?? dateRange;
            people = result["people"] ?? people;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF1F1F1),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 18),
              const SizedBox(width: 10),
              Text(dateRange),
              const Spacer(),
              const Icon(Icons.people_alt_outlined),
              const SizedBox(width: 6),
              Text("$people명"),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------- 편의시설 -------------------------------
  Widget _facilitySection() {
    final items = [
      {"icon": Icons.local_parking, "text": "주차장"},
      {"icon": Icons.fitness_center, "text": "헬스장"},
      {"icon": Icons.wifi, "text": "인터넷"},
      {"icon": Icons.pool, "text": "수영장"},
      {"icon": Icons.smoke_free, "text": "금연"},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "편의시설 및 서비스",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((e) {
              return Column(
                children: [
                  Icon(e["icon"] as IconData, size: 32),
                  const SizedBox(height: 6),
                  Text(e["text"] as String),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ------------------------------- 지도 -------------------------------
  Widget _mapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "위치",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.map, size: 70, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------- 상세 설명 -------------------------------
  Widget _detailInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "숙소 상세 설명",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Text(
            widget.stayData["description"] ?? "상세 정보가 없습니다.",
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ReviewBox extends StatelessWidget {
  const _ReviewBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text("숙소가 깔끔하고 조용해서 좋았어요!", style: TextStyle(fontSize: 13)),
    );
  }
}
