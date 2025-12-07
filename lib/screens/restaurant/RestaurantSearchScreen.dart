import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cospicker/models/content_type.dart';

class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final TextEditingController locationController = TextEditingController();

  String selectedDate = "방문 날짜를 선택하세요";
  int selectedPeople = 1;

  List<String> recentList = [];
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadRecentSearch();
  }

  // ===============================
  // 🔥 최근 검색 Firestore에서 불러오기
  // ===============================
  Future<void> _loadRecentSearch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await db.collection("recentRestaurantSearch").doc(user.uid).get();

    if (doc.exists && doc.data()!.containsKey("keywords")) {
      setState(() {
        recentList = List<String>.from(doc["keywords"]);
      });
    }
  }

  // ===============================
  // 🔥 Firestore 저장
  // ===============================
  Future<void> _saveRecentSearch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await db.collection("recentRestaurantSearch").doc(user.uid).set({
      "keywords": recentList,
    });
  }

  // ===============================
  // 검색 실행
  // ===============================
  void _doSearch() {
    String text = locationController.text.trim();
    if (text.isEmpty) return;

    // 최근 검색 업데이트
    if (!recentList.contains(text)) {
      setState(() {
        recentList.insert(0, text);
      });
      _saveRecentSearch();
    }

    Navigator.pushNamed(
      context,
      '/restaurantList',
      arguments: {"location": text},
    );
  }

  // ===============================
  // 📅 날짜/인원 선택 화면 이동
  // ===============================
  Future<void> _openDatePeopleScreen() async {
    final result = await Navigator.pushNamed(context, '/stayDatePeople');

    if (result != null && result is Map) {
      setState(() {
        selectedDate = result['date'] ?? selectedDate;
        selectedPeople = result['people'] ?? selectedPeople;
      });
    }
  }

  // ===============================
  // 🔘 최근 검색 chip
  // ===============================
  Widget _chip(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          locationController.text = text;
        });
      },
      child: Chip(
        label: Text(text),
        backgroundColor: const Color(0xFFF2F2F2),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() {
            recentList.remove(text);
          });
          _saveRecentSearch();
        },
      ),
    );
  }

  // ===============================
  // 🔝 상단 COSPICKER + 뒤로가기
  // ===============================
  Widget _topHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          "COSPICKER",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ===============================
  // 🏷 숙소/맛집 탭
  // ===============================
  Widget _categoryTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 숙소 탭 이동
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(
                context,
                '/staySearch',
                arguments: ContentType.accommodation,
              );
            },
            child: Column(
              children: [
                Icon(Icons.home, size: 30, color: Colors.grey),
                Text(
                  "숙소",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(width: 40),

          // 현재 선택 : 맛집
          Column(
            children: const [
              Icon(Icons.storefront, size: 30, color: Colors.black),
              SizedBox(height: 4),
              Text(
                "맛집",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================
  // UI Build
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topHeader(),
                _categoryTabs(),

                const SizedBox(height: 10),

                // 검색창 UI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
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
                            hintText: "어디 맛집을 찾으세요?",
                          ),
                          onSubmitted: (_) => _doSearch(),
                        ),
                      ),

                      GestureDetector(
                        onTap: _doSearch,
                        child: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 📅 방문 날짜 선택
                GestureDetector(
                  onTap: _openDatePeopleScreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 22, color: Colors.black54),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            selectedDate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Icon(Icons.person, size: 22, color: Colors.black54),
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

                const SizedBox(height: 25),

                // 최근 검색
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "최근 맛집 검색",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "전체 삭제",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  children: recentList.map((e) => _chip(e)).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
