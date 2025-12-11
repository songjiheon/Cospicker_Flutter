import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cospicker/models/content_type.dart';

class StaySearchScreen extends StatefulWidget {
  final ContentType type;
  const StaySearchScreen({super.key, required this.type});
  @override
  State<StaySearchScreen> createState() => _StaySearchScreenState();
}

class _StaySearchScreenState extends State<StaySearchScreen> {
  final TextEditingController locationController = TextEditingController();
  late ContentType currentType;

  String selectedDate = "날짜를 선택하세요";
  int selectedPeople = 1;

  List<String> recentList = [];
  final FirebaseFirestore db = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    currentType = widget.type;
    _loadRecentSearch();
  }

  // ===============================
  // 🔥 최근 검색 Firestore에서 불러오기
  // ===============================
  Future<void> _loadRecentSearch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await db.collection("recentSearch").doc(user.uid).get();

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
    await db.collection("recentSearch").doc(user.uid).set({
      "keywords": recentList,
    });
  }

  //  const String serviceKey = "AIzaSyADP6VfQKeMMJP1aDPpJAPBTczfFp5cMTc";
  Future<Map<String, double>?> getLatLngByGoogle(String address) async {
    final apiKey = "AIzaSyADP6VfQKeMMJP1aDPpJAPBTczfFp5cMTc";
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData["results"].isNotEmpty) {
        final location = jsonData["results"][0]["geometry"]["location"];

        return {"lat": location["lat"], "lng": location["lng"]};
      }
    }
    return null;
  }

  Future<void> saveRestaurantItemsToFirestore(
    List<dynamic> items,
    String location,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    final random = Random();

    for (var item in items) {
      final docRef = FirebaseFirestore.instance
          .collection("restaurantItems")
          .doc(item["contentid"]);

      int price = (5000 + random.nextInt(20000)); // 일반 음식 평균 가격대
      double rating = (30 + random.nextInt(21)) / 10.0;
      int review = random.nextInt(2000);

      final newItem = Map<String, dynamic>.from(item);
      newItem.addAll({
        "city": location,
        "avgPrice": price,
        "rating": rating,
        "review": review,
        "description": "",
      });

      batch.set(docRef, newItem);
    }

    await batch.commit();
  }

  Future<void> saveTourItemsToFirestore(
    List<dynamic> items,
    String location,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    final random = Random();

    final roomImages = [
      "https://cdn.pixabay.com/photo/2020/10/18/09/16/bedroom-5664221_1280.jpg",
      "https://cdn.pixabay.com/photo/2018/06/14/21/15/bedroom-3475656_1280.jpg",
      "https://cdn.pixabay.com/photo/2020/02/01/06/12/living-room-4809587_640.jpg",
      "https://cdn.pixabay.com/photo/2021/12/18/06/13/hotel-6878058_640.jpg",
      "https://cdn.pixabay.com/photo/2016/06/10/01/05/hotel-room-1447201_640.jpg",
      "https://cdn.pixabay.com/photo/2015/01/16/11/19/hotel-601327_640.jpg",
      "https://cdn.pixabay.com/photo/2020/01/23/02/42/bedroom-4786791_640.jpg",
      "https://cdn.pixabay.com/photo/2014/09/25/18/05/bedroom-460762_640.jpg",
      "https://cdn.pixabay.com/photo/2020/05/14/16/51/bed-5170531_640.jpg",
      "https://cdn.pixabay.com/photo/2020/06/24/17/47/room-5337097_640.jpg",
    ];
    final descriptions = [
      "편안한 휴식을 위한 최적의 공간을 제공합니다.",
      "여행객에게 사랑받는 가성비 최고의 숙소입니다.",
      "깨끗한 객실과 친절한 서비스로 만족도를 높였습니다.",
      "여유로운 분위기에서 힐링할 수 있는 공간입니다.",
      "모던한 인테리어와 넓은 객실이 특징입니다.",
      "가족, 커플 여행객 모두에게 추천하는 숙소입니다.",
      "넓고 쾌적한 침구로 편안한 밤을 보장합니다.",
      "실내외 시설이 잘 갖춰져 있어 만족도가 높은 숙소입니다.",
    ];

    for (var item in items) {
      final docRef = FirebaseFirestore.instance
          .collection("tourItems")
          .doc(item["contentid"]);

      final docSnap = await docRef.get();
      final roomsSnap = await docRef.collection("rooms").limit(1).get();

      if (docSnap.exists && roomsSnap.docs.isNotEmpty) {
        //print("이미 존재 및 rooms 있음: ${item["contentid"]} → 건너뜀");
        continue;
      }

      int price = (10 * (10 + random.nextInt(41))) * 1000;
      int salePrice = (price * 0.8 / 1000).round() * 1000;
      int review = random.nextInt(501);
      double rating = (30 + random.nextInt(21)) / 10.0;

      String mainRoomImage = roomImages[random.nextInt(roomImages.length)];

      // Map<String,dynamic>으로 안전하게 변환
      final newItem = Map<String, dynamic>.from(item);
      newItem.addAll({
        "city": location.trim(),
        "price": price,
        "salePrice": salePrice,
        "rating": rating,
        "review": review,
        "roomImage": mainRoomImage,
        "description": descriptions[random.nextInt(descriptions.length)],
      });

      batch.set(docRef, newItem);

      final roomTypes = ["스탠다드 룸"];
      if (random.nextBool()) roomTypes.add("디럭스 룸");
      if (random.nextBool()) roomTypes.add("스위트 룸");

      for (var roomType in roomTypes) {
        final roomRef = docRef.collection("rooms").doc();
        int roomPrice = price; // 기본 스탠다드 가격
        if (roomType == "디럭스 룸") roomPrice = (price * 1.5).round();
        if (roomType == "스위트 룸") roomPrice = (price * 2).round();

        int max = 2 + random.nextInt(3);

        batch.set(roomRef, {
          "roomName": roomType,
          "price": roomPrice,
          "salePrice": (roomPrice * 0.8 / 1000).round() * 1000,
          "roomImage": roomType == "스탠다드 룸"
              ? mainRoomImage
              : roomImages[random.nextInt(roomImages.length)],
          "standard": 2,
          "max": max,
        });
      }
    }

    await batch.commit();
    print("🔥 Firestore 저장 완료 (${items.length}개)");
  }

  Future<List<dynamic>> fetchTourApiLocationBased({
    required double lat,
    required double lng,
    required int contentTypeId, //(숙소 32 /맛집 39)
    int radius = 5000,
    String arrange = "E",
    int minItems = 3, //  최소 개수 설정
    int numOfRows = 10, // 한 페이지 최대 개수
  }) async {
    const String serviceKey =
        "4e7c9d80475f8c84a482b22bc87a5c3376d82411b81a289fecdabaa83d75e26f";
    const String mobileOS = "ETC";
    const String mobileApp = "Cospicker";

    int pageNo = 1;
    List<dynamic> accumulated = [];

    // 🔹 이미지 체크 함수
    bool hasImage(Map data) {
      return data["firstimage"] != null &&
          (data["firstimage"] as String).isNotEmpty;
    }

    while (accumulated.length < minItems) {
      final url = Uri.parse(
        "https://apis.data.go.kr/B551011/KorService2/locationBasedList2"
        "?serviceKey=$serviceKey"
        "&mapX=$lng"
        "&mapY=$lat"
        "&radius=$radius"
        "&arrange=$arrange"
        "&numOfRows=$numOfRows"
        "&pageNo=$pageNo"
        "&contentTypeId=$contentTypeId"
        "&MobileOS=$mobileOS"
        "&MobileApp=$mobileApp"
        "&_type=json",
      );

      print("📡 TourAPI 요청 (Page $pageNo, ContentType: $contentTypeId): $url");

      try {
        final response = await http.get(
          url,
          headers: {'Accept': 'application/json'},
        );
        if (response.statusCode != 200) {
          print(
            "Error: HTTP Status ${response.statusCode}, Body: ${response.body}",
          );
          break;
        }

        final jsonData = json.decode(response.body);
        final items = jsonData["response"]["body"]["items"];
        if (items == null) break;

        final itemData = items["item"];
        List<dynamic> filtered = [];

        if (itemData is List) {
          filtered = itemData.where((e) => hasImage(e)).toList();
        } else if (itemData is Map) {
          if (hasImage(itemData)) filtered = [itemData];
        }

        if (filtered.isEmpty) break; // 더 이상 유효한 항목 없으면 종료

        accumulated.addAll(filtered);
        pageNo++; // 다음 페이지
      } catch (e) {
        print("네트워크/파싱 오류 발생: $e");
        break;
      }
    }

    print("✅ 최종 누적 항목 수: ${accumulated.length}");
    return accumulated.take(minItems).toList(); // 최소 개수 보장
  }

  // ===============================
  // 검색 실행
  // ===============================
  // 지오코딩 지리 -> 위도 경도로 변환
  // https://maps.googleapis.com/maps/api/geocode/json?address=주소&key=API_KEY
  void _doSearch() async {
    String text = locationController.text.trim();
    if (text.isEmpty) return;

    final result = await getLatLngByGoogle(text);
    print("위치 결과: $result");
    ;
    // 최근 검색 저장
    if (!recentList.contains(text)) {
      setState(() {
        recentList.insert(0, text);
      });
      _saveRecentSearch(); // Firestore 저장
    }
    if (result == null) {
      print("❌ 주소 → 좌표 변환 실패");
      return;
    }

    double lat = result["lat"]!;
    double lng = result["lng"]!;

    print("LAT = $lat");
    print("LNG = $lng");

    int contentTypeId = currentType == ContentType.accommodation ? 32 : 39;

    final tourItems = await fetchTourApiLocationBased(
      lat: lat,
      lng: lng,
      contentTypeId: contentTypeId,
    );

    if (contentTypeId == 32) {
      await saveTourItemsToFirestore(tourItems, text); // 숙소
    } else {
      await saveRestaurantItemsToFirestore(tourItems, text); // 맛집
    }

    if (currentType == ContentType.accommodation) {
      Navigator.pushNamed(
        context,
        '/stayList',
        arguments: {
          "location": text,
          "date": selectedDate,
          "people": selectedPeople,
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        '/restaurantList',
        arguments: {"location": text},
      );
    }
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
          // 숙소
          GestureDetector(
            onTap: () {
              setState(() {
                currentType = ContentType.accommodation;
              });
            },
            child: Column(
              children: [
                Icon(
                  Icons.home,
                  size: 30,
                  color: currentType == ContentType.accommodation
                      ? Colors.black
                      : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  "숙소",
                  style: TextStyle(
                    color: currentType == ContentType.accommodation
                        ? Colors.black
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                    decoration: currentType == ContentType.accommodation
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 40),

          // 🍽 맛집 → 별도 화면 이동
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, "/restaurantSearch");
            },
            child: Column(
              children: [
                Icon(
                  Icons.storefront,
                  size: 30,
                  color: Colors.grey,
                ),
                SizedBox(height: 4),
                Text(
                  "맛집",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  //  UI
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

                // 🔍 검색창
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
                            hintText: "어디로 여행가세요?",
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

                // 📅 날짜 + 인원 선택
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
                        const Icon(
                          Icons.calendar_today,
                          size: 22,
                          color: Colors.black54,
                        ),
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
                        const Icon(
                          Icons.person,
                          size: 22,
                          color: Colors.black54,
                        ),
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

                // 최근 검색 + 전체삭제
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "최근 검색",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => recentList.clear());
                        _saveRecentSearch();
                      },
                      child: const Text(
                        "전체 삭제",
                        style: TextStyle(color: Colors.grey),
                      ),
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
