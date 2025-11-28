import 'package:flutter/material.dart';
import 'StayDatePeopleScreen.dart';

class StaySearchScreen extends StatefulWidget {
  const StaySearchScreen({super.key});

  @override
  State<StaySearchScreen> createState() => _StaySearchScreenState();
}

class _StaySearchScreenState extends State<StaySearchScreen> {
  TextEditingController locationController = TextEditingController();

  String selectedDateText = "날짜를 선택하세요";
  int selectedPeople = 1;

  List<String> recentList = ["경주", "부산", "서울"];

  // 🔎 검색 실행 → 숙소 리스트로 이동
  void _doSearch() {
    Navigator.pushNamed(
      context,
      '/stayList',
      arguments: {
        "location": locationController.text,
        "date": selectedDateText,
        "people": selectedPeople,
      },
    );
  }

  // 🗑 최근 검색 전체 삭제
  void _clearRecent() {
    setState(() {
      recentList.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ← 뒤로가기
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, size: 20),
              ),

              const SizedBox(height: 10),

              // 상단 COSPICKER
              const Center(
                child: Text(
                  "COSPICKER",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),

              const SizedBox(height: 26),

              // ⭐ 숙소 / 맛집 탭
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.home, size: 40, color: Colors.black),
                      const SizedBox(height: 4),
                      const Text(
                        "숙소",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(width: 40, height: 3, color: Colors.black),
                    ],
                  ),

                  const SizedBox(width: 60),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/restaurantSearch');
                    },
                    child: Column(
                      children: const [
                        Icon(
                          Icons.storefront_rounded,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "맛집",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // 🔍 여행지 검색창
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "어디로 여행가세요?",
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _doSearch,
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 📅 날짜 & 인원 컨테이너
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StayDatePeopleScreen(),
                    ),
                  );

                  // 🔥 값을 정상적으로 받아온 경우
                  if (result != null && result is Map) {
                    setState(() {
                      selectedDateText = result["date"] ?? selectedDateText;
                      selectedPeople = result["people"] ?? selectedPeople;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 22,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),

                      // 날짜 텍스트
                      Expanded(
                        child: Text(
                          selectedDateText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Icon(Icons.person, size: 22, color: Colors.black87),
                      const SizedBox(width: 6),

                      Text(
                        "$selectedPeople명",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 🔥 최근 검색 + 전체 삭제
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "최근 검색",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  GestureDetector(
                    onTap: _clearRecent,
                    child: const Text(
                      "전체 삭제",
                      style: TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 최근 검색 Chips
              Wrap(
                spacing: 10,
                children: recentList.map((item) => _chip(item)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chip 위젯
  Widget _chip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0xFFF2F2F2),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () {
        setState(() {
          recentList.remove(text);
        });
      },
    );
  }
}
