import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'StayDetailScreen.dart';

class StayListScreen extends StatefulWidget {
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
  State<StayListScreen> createState() => _StayListScreenState();
}

class _StayListScreenState extends State<StayListScreen> {
  String sortType = "popular";

  List<String> selectedFilters = [];
  double minPrice = 0;
  double maxPrice = 300000;

  late String selectedDate;
  late int selectedPeople;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.date;
    selectedPeople = widget.people;
  }

  // ============================
  // 🔥 날짜/인원 변경 화면 이동
  // ============================
  void _openDatePeopleScreen() async {
    final result = await Navigator.pushNamed(context, '/stayDatePeople');

    if (result != null && result is Map) {
      setState(() {
        selectedDate = result["date"] ?? selectedDate;
        selectedPeople = result["people"] ?? selectedPeople;
      });
    }
  }

  // ============================
  // 🔥 UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            _filterButtons(),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("stays")
                    .where("location", isEqualTo: widget.location.trim())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Firestore 데이터 → List 복사
                  List<QueryDocumentSnapshot> stays = snapshot.data!.docs
                      .toList();

                  // ==========================================
                  // 🔥 Flutter 내부 필터링 (필터 / 가격)
                  // ==========================================
                  stays = stays.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // 타입 필터
                    if (selectedFilters.isNotEmpty &&
                        !selectedFilters.contains(data["type"])) {
                      return false;
                    }

                    // 가격 필터
                    num price = (data["salePrice"] is num)
                        ? data["salePrice"]
                        : num.tryParse(data["salePrice"].toString()) ?? 0;

                    if (price < minPrice || price > maxPrice) return false;

                    return true;
                  }).toList();

                  // ==========================================
                  // 🔥 정렬 수행
                  // ==========================================
                  stays.sort((a, b) {
                    final A = a.data() as Map<String, dynamic>;
                    final B = b.data() as Map<String, dynamic>;

                    switch (sortType) {
                      case "lowPrice":
                        return (A["salePrice"] as num).compareTo(
                          B["salePrice"] as num,
                        );
                      case "highPrice":
                        return (B["salePrice"] as num).compareTo(
                          A["salePrice"] as num,
                        );
                      case "review":
                        return (B["review"] as num).compareTo(
                          A["review"] as num,
                        );
                      default:
                        return (B["rating"] as num).compareTo(
                          A["rating"] as num,
                        );
                    }
                  });

                  if (stays.isEmpty) {
                    return const Center(child: Text("해당 조건의 숙소가 없습니다."));
                  }

                  // ==========================================
                  // 🔥 리스트 출력
                  // ==========================================
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stays.length,
                    itemBuilder: (context, index) {
                      final data = stays[index].data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StayDetailScreen(
                                stayData: {
                                  "id": stays[index].id,
                                  ...data,
                                  "date": selectedDate,
                                  "people": selectedPeople,
                                },
                              ),
                            ),
                          );

                          if (result != null && result is Map) {
                            setState(() {
                              selectedDate = result["date"] ?? selectedDate;
                              selectedPeople =
                                  result["people"] ?? selectedPeople;
                            });
                          }
                        },
                        child: _stayItem(data),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // 🔥 상단바
  // ============================
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

  // ============================
  // 🔥 날짜/필터/정렬 버튼
  // ============================
  Widget _filterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _chipButton(
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18),
                const SizedBox(width: 6),
                Text("날짜: $selectedDate | ${selectedPeople}명"),
              ],
            ),
            _openDatePeopleScreen,
          ),
          const SizedBox(width: 10),
          _chipButton(const Text("필터"), _openFilterDialog),
          const SizedBox(width: 10),
          _chipButton(const Text("정렬"), _openSortDialog),
        ],
      ),
    );
  }

  Widget _chipButton(Widget child, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    );
  }

  // ============================
  // 🔥 정렬 모달
  // ============================
  void _openSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortTile("인기순", "popular"),
            _sortTile("낮은가격순", "lowPrice"),
            _sortTile("높은가격순", "highPrice"),
            _sortTile("리뷰 많은순", "review"),
          ],
        );
      },
    );
  }

  Widget _sortTile(String label, String key) {
    return ListTile(
      title: Text(label),
      trailing: sortType == key
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() => sortType = key);
      },
    );
  }

  // ============================
  // 🔥 필터 모달
  // ============================
  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "숙소 유형",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 10,
                    children: [
                      _filterChip("호텔", setModal),
                      _filterChip("모텔", setModal),
                      _filterChip("펜션", setModal),
                      _filterChip("풀빌라", setModal),
                      _filterChip("리조트", setModal),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "가격 범위",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  RangeSlider(
                    values: RangeValues(minPrice, maxPrice),
                    min: 0,
                    max: 500000,
                    divisions: 10, // 🔥 500000 / 50,000 = 10칸
                    labels: RangeLabels(
                      "${minPrice.toInt()}원",
                      "${maxPrice.toInt()}원",
                    ),
                    onChanged: (value) {
                      setModal(() {
                        // 5만원 단위로 스냅
                        minPrice = (value.start / 50000).round() * 50000;
                        maxPrice = (value.end / 50000).round() * 50000;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text("필터 적용"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label, Function(void Function()) setModal) {
    return FilterChip(
      label: Text(label),
      selected: selectedFilters.contains(label),
      onSelected: (value) {
        setModal(() {
          if (value) {
            selectedFilters.add(label);
          } else {
            selectedFilters.remove(label);
          }
        });
      },
    );
  }

  // ============================
  // 🔥 숙소 아이템 UI
  // ============================
  Widget _stayItem(Map stay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              stay["images"][0],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(width: 14),
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
                    const Icon(Icons.location_on, size: 14),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFFFB800)),
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
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 13,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
