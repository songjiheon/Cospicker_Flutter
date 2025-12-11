import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantListScreen extends StatefulWidget {
  final String location;

  const RestaurantListScreen({super.key, required this.location});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  // -------------------------
  // 날짜 선택
  // -------------------------
  String selectedDateText = "오늘";
  DateTime? selectedDate;

  Future<void> _pickDate() async {
    final today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today.subtract(const Duration(days: 0)),
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedDateText =
        "${picked.month.toString().padLeft(2, '0')}.${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // -------------------------
  // 정렬 + 필터 상태 변수
  // -------------------------
  String sortType = "rating"; // 기본: 평점순

  List<String> selectedCategories = [];
  String? selectedPriceRange;
  bool showOpenNow = false;

  final List<String> categories = [
    "한식", "중식", "일식", "양식", "카페", "분식"
  ];

  final user = FirebaseAuth.instance.currentUser;
  String get uid => user!.uid;

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            const SizedBox(height: 10),
            _chipButtonsRow(), // 날짜 / 필터 / 정렬
            const SizedBox(height: 10),
            Expanded(child: _restaurantStream()),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // 상단 검색바
  // -------------------------
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          const SizedBox(width: 10),
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
                    widget.location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.close),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // 오늘 / 필터 / 정렬 버튼
  // -------------------------
  Widget _chipButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chipButton(selectedDateText, Icons.calendar_today, _pickDate),
          const SizedBox(width: 10),
          _chipButton("필터", Icons.filter_list, _openFilterSheet),
          const SizedBox(width: 10),
          _chipButton("정렬", Icons.sort, _openSortSheet),
        ],
      ),
    );
  }

  // 공통 Chip 버튼
  Widget _chipButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(text),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // 정렬 BottomSheet
  // -------------------------
  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("평점순"),
              onTap: () {
                setState(() => sortType = "rating");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("리뷰 많은순"),
              onTap: () {
                setState(() => sortType = "review");
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // -------------------------
  // 필터 BottomSheet
  // -------------------------
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(builder: (context, setModal) {
          return Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 60,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const Text("음식 종류",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: categories.map((cat) {
                    final selected = selectedCategories.contains(cat);
                    return ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black),
                      onSelected: (val) {
                        setModal(() {
                          if (val) {
                            selectedCategories.add(cat);
                          } else {
                            selectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 25),
                const Text("가격대",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Column(
                  children: [
                    _priceOption(setModal, "1만원 이하"),
                    _priceOption(setModal, "1–2만원"),
                    _priceOption(setModal, "2–3만원"),
                    _priceOption(setModal, "3만원 이상"),
                  ],
                ),

                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("영업 중만 보기",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Switch(
                      value: showOpenNow,
                      onChanged: (v) => setModal(() => showOpenNow = v),
                    )
                  ],
                ),

                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategories.clear();
                            selectedPriceRange = null;
                            showOpenNow = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("초기화"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        child: const Text("적용"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _priceOption(Function setModal, String value) {
    return RadioListTile(
      dense: true,
      title: Text(value),
      value: value,
      groupValue: selectedPriceRange,
      onChanged: (v) {
        setModal(() => selectedPriceRange = v);
      },
    );
  }

  // -------------------------
  // Firestore Stream + 필터 + 정렬
  // -------------------------
  Widget _restaurantStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("restaurantItems")
          .where("city", isEqualTo: widget.location.trim())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> items = snapshot.data!.docs.toList();

        // -------------------------
        // ⭐ 필터 적용
        // -------------------------
        items = items.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (selectedCategories.isNotEmpty &&
              !selectedCategories.contains(data["category"])) {
            return false;
          }

          final price = data["avgPrice"] ?? 0;

          if (selectedPriceRange != null) {
            if (selectedPriceRange == "1만원 이하" && price > 10000)
              return false;
            if (selectedPriceRange == "1–2만원" &&
                !(price >= 10000 && price <= 20000)) return false;
            if (selectedPriceRange == "2–3만원" &&
                !(price >= 20000 && price <= 30000)) return false;
            if (selectedPriceRange == "3만원 이상" && price < 30000)
              return false;
          }

          return true;
        }).toList();

        // -------------------------
        // ⭐ 정렬 적용
        // -------------------------
        items.sort((a, b) {
          final A = a.data() as Map<String, dynamic>;
          final B = b.data() as Map<String, dynamic>;

          switch (sortType) {
            case "rating":
              return (B["rating"] as num).compareTo(A["rating"] as num);
            case "review":
              return (B["review"] as num).compareTo(A["review"] as num);
          }
          return 0;
        });

        if (items.isEmpty) {
          return const Center(
              child: Text("조건에 맞는 맛집이 없습니다.", style: TextStyle(fontSize: 15)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final data = doc.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/restaurantDetail",
                  arguments: {"contentid": doc.id, ...data},
                );
              },
              child: FutureBuilder<bool>(
                future: _checkSaved(doc.id),
                builder: (context, snapshot) {
                  final saved = snapshot.data ?? false;

                  return Stack(
                    children: [
                      _restaurantItem(data),

                      // -------------------------
                      // 찜 버튼
                      // -------------------------
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              _openWishFolderSelector(data, doc.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              saved
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 22,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _checkSaved(String contentId) async {
    final folderSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_restaurant")
        .get();

    for (var folder in folderSnap.docs) {
      final itemSnap =
      await folder.reference.collection("items").doc(contentId).get();

      if (itemSnap.exists) return true;
    }
    return false;
  }

  // -------------------------
  // 맛집 카드 UI
  // -------------------------
  Widget _restaurantItem(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              item["firstimage"] ?? "",
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(width: 120, height: 120, color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["title"] ?? "",
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(item["city"] ?? "",
                    style:
                    const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 16, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text("${item["rating"] ?? 0} (${item["review"] ?? 0})",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // 폴더 선택 BottomSheet
  // -------------------------
  void _openWishFolderSelector(Map data, String id) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (context) {
        return SizedBox(
          height: 380,
          child: Column(
            children: [
              const SizedBox(height: 14),
              const Text("폴더 선택",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection("wish_restaurant")
                      .orderBy("createdAt")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "맛집 폴더가 없습니다.\n위시 리스트에서 폴더를 생성하세요.",
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final folder = doc.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(folder["name"]),
                          onTap: () async {
                            await _saveToFolder(
                              folderId: doc.id,
                              restaurantId: id,
                              restaurantData: data,
                            );
                            Navigator.pop(context);
                            setState(() {});
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
      },
    );
  }

  // -------------------------
  // 찜 저장
  // -------------------------
  Future<void> _saveToFolder({
    required String folderId,
    required String restaurantId,
    required Map restaurantData,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_restaurant")
        .doc(folderId)
        .collection("items")
        .doc(restaurantId);

    await ref.set({
      "title": restaurantData["title"],
      "image": restaurantData["firstimage"],
      "rating": restaurantData["rating"],
      "addr": restaurantData["addr1"] ?? "",
      "city": restaurantData["city"] ?? "",
      "contentid": restaurantId,
      "type": "restaurant",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
