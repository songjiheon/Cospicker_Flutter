import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/screens/near/NearMapScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:geocoding/geocoding.dart';
import 'package:cospicker/models/content_type.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  String userName = "";

  // 주변 숙소 / 주변 맛집
  List<dynamic> _nearAccommodations = [];
  List<dynamic> _nearRestaurants = [];

  bool _loadingAccommodations = true;
  bool _loadingRestaurants = true;

  // 최근 본 숙소 / 최근 본 맛집
  List<Map<String, dynamic>> _recentStays = [];
  List<Map<String, dynamic>> _recentRestaurants = [];

  bool _loadingRecentStays = true;
  bool _loadingRecentRestaurants = true;

  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  // 뒤에서 돌아올 때 최신 데이터 갱신
  @override
  void didPopNext() {
    _loadRecentStays();
    _loadRecentRestaurants();
  }

  // ================================
  //  도시명 표준화 ("서울특별시" → "서울")
  // ================================
  String normalizeCityName(String? name) {
    if (name == null) return "Unknown";

    final map = {
      "서울특별시": "서울",
      "부산광역시": "부산",
      "대구광역시": "대구",
      "인천광역시": "인천",
      "광주광역시": "광주",
      "대전광역시": "대전",
      "울산광역시": "울산",
      "세종특별자치시": "세종",
      "제주특별자치도": "제주",
    };

    return map[name] ?? name.replaceAll("특별시", "").replaceAll("광역시", "");
  }

  // ========================================
  // 최근 본 숙소 저장
  // ========================================
  Future<void> saveRecentStay(String contentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef =
    FirebaseFirestore.instance.collection("recentStays").doc(user.uid);

    final docSnap = await docRef.get();

    List<String> list = [];
    if (docSnap.exists && docSnap.data()!.containsKey("contentIds")) {
      list = List<String>.from(docSnap["contentIds"]);
    }

    list.remove(contentId);
    list.insert(0, contentId);

    if (list.length > 10) list = list.sublist(0, 10);

    if (docSnap.exists) {
      await docRef.update({"contentIds": list});
    } else {
      await docRef.set({"contentIds": list});
    }
  }

  // ========================================
  // 최근 본 맛집 저장
  // ========================================
  Future<void> saveRecentRestaurant(String contentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef =
    FirebaseFirestore.instance.collection("recentRestaurants").doc(user.uid);

    final docSnap = await docRef.get();

    List<String> list = [];
    if (docSnap.exists && docSnap.data()!.containsKey("contentIds")) {
      list = List<String>.from(docSnap["contentIds"]);
    }

    list.remove(contentId);
    list.insert(0, contentId);

    if (list.length > 10) list = list.sublist(0, 10);

    if (docSnap.exists) {
      await docRef.update({"contentIds": list});
    } else {
      await docRef.set({"contentIds": list});
    }
  }

  // ========================================
  // 초기 로딩
  // ========================================
  Future<void> _initLoad() async {
    setState(() {
      _loadingAccommodations = true;
      _loadingRestaurants = true;
      _loadingRecentStays = true;
      _loadingRecentRestaurants = true;
    });

    final position = await _determinePosition();
    if (position == null) return;

    final cityRaw =
    await _getCityFromLatLng(position.latitude, position.longitude);
    final city = normalizeCityName(cityRaw);

    await Future.wait([
      _loadNearbyAccommodations(position, city),
      _loadNearbyRestaurants(position, city),
      _loadRecentStays(),
      _loadRecentRestaurants(),
    ]);
  }

  // ========================================
  // 위경도 → 도시명
  // ========================================
  Future<String> _getCityFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;
      return place.administrativeArea ?? "Unknown";
    } catch (e) {
      print("도시 변환 실패: $e");
      return "Unknown";
    }
  }

  // ========================================
  // 최근 본 숙소 불러오기
  // ========================================
  Future<void> _loadRecentStays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("recentStays")
        .doc(user.uid)
        .get();

    if (!doc.exists || !doc.data()!.containsKey("contentIds")) {
      setState(() {
        _recentStays = [];
        _loadingRecentStays = false;
      });
      return;
    }

    final List<dynamic> contentIds = doc["contentIds"];

    final futures = contentIds.map((id) async {
      final stayDoc =
      await FirebaseFirestore.instance.collection("tourItems").doc(id).get();

      if (stayDoc.exists && stayDoc.data() != null) {
        return stayDoc.data() as Map<String, dynamic>;
      }
      return null;
    });

    final results = await Future.wait(futures);
    setState(() {
      _recentStays = results.whereType<Map<String, dynamic>>().toList();
      _loadingRecentStays = false;
    });
  }

  // ========================================
  // 최근 본 맛집 불러오기
  // ========================================
  Future<void> _loadRecentRestaurants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("recentRestaurants")
        .doc(user.uid)
        .get();

    if (!doc.exists || !doc.data()!.containsKey("contentIds")) {
      setState(() {
        _recentRestaurants = [];
        _loadingRecentRestaurants = false;
      });
      return;
    }

    final List<dynamic> contentIds = doc["contentIds"];

    final futures = contentIds.map((id) async {
      final rDoc = await FirebaseFirestore.instance
          .collection("restaurantItems")
          .doc(id)
          .get();

      if (rDoc.exists && rDoc.data() != null) {
        return rDoc.data() as Map<String, dynamic>;
      }
      return null;
    });

    final results = await Future.wait(futures);
    setState(() {
      _recentRestaurants = results.whereType<Map<String, dynamic>>().toList();
      _loadingRecentRestaurants = false;
    });
  }

  // ==========================================================
  // 위치 권한 확인 + 현재 위치 가져오기
  // ==========================================================
  Future<Position?> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("위치 권한 없음");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("위치 가져오기 실패: $e");
      return null;
    }
  }

  // ==========================================================
  // Tour API 호출 (숙소/맛집 공통)
  // ==========================================================
  Future<List<dynamic>> _fetchNearbyItems(
      double lat,
      double lng,
      int contentTypeId, // 32 = 숙소, 39 = 맛집
      ) async {
    const serviceKey =
        "4e7c9d80475f8c84a482b22bc87a5c3376d82411b81a289fecdabaa83d75e26f";

    final url = Uri.parse(
      "https://apis.data.go.kr/B551011/KorService2/locationBasedList2"
          "?serviceKey=$serviceKey"
          "&mapX=$lng"
          "&mapY=$lat"
          "&radius=3000"
          "&arrange=E"
          "&numOfRows=20"
          "&pageNo=1"
          "&contentTypeId=$contentTypeId"
          "&MobileOS=ETC"
          "&MobileApp=Cospicker"
          "&_type=json",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body);
      final items = data["response"]["body"]["items"];
      if (items == null) return [];

      final itemData = items["item"];
      if (itemData is List) return itemData;
      if (itemData is Map) return [itemData];

      return [];
    } catch (e) {
      print("Tour API 오류: $e");
      return [];
    }
  }

  // ==========================================================
  // 주변 숙소 로드 & Firestore 저장
  // ==========================================================
  Future<void> _loadNearbyAccommodations(Position pos, String city) async {
    setState(() => _loadingAccommodations = true);

    final rawList = await _fetchNearbyItems(pos.latitude, pos.longitude, 32);

    final filtered = rawList
        .where((item) =>
    item["firstimage"] != null &&
        item["firstimage"].toString().isNotEmpty)
        .toList();

    setState(() {
      _nearAccommodations = filtered;
      _loadingAccommodations = false;
    });

    await _saveTourItemsToFirestore(filtered, city);
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<Set<String>> _getExistingStayItemsIds(List<dynamic> items) async {
    final ids = items.map((e) => e["contentid"].toString()).toList();

    final qs = await FirebaseFirestore.instance
        .collection("tourItems")
        .where(FieldPath.documentId, whereIn: ids.length > 10 ? ids.take(10).toList() : ids)
        .get();

    final existing = <String>{};
    existing.addAll(qs.docs.map((e) => e.id));

    if (ids.length > 10) {
      for (var chunk in _chunkList(ids.skip(10).toList(), 10)) {
        final res = await FirebaseFirestore.instance
            .collection("tourItems")
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        existing.addAll(res.docs.map((e) => e.id));
      }
    }
    return existing;
  }

  // Firestore 저장(숙소)
  Future<void> _saveTourItemsToFirestore(List<dynamic> items, String location) async {
    final batch = FirebaseFirestore.instance.batch();
    final random = Random();

    final existingIds = await _getExistingStayItemsIds(items);

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
      final id = item["contentid"]?.toString();
      if (id == null) continue;

      if (existingIds.contains(id)) continue;

      final docRef = FirebaseFirestore.instance.collection("tourItems").doc(id);

      int price = (10 * (10 + random.nextInt(41))) * 1000;
      int salePrice = (price * 0.8 / 1000).round() * 1000;
      int review = random.nextInt(501);
      double rating = (30 + random.nextInt(21)) / 10.0;

      String mainRoomImage = roomImages[random.nextInt(roomImages.length)];

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

      // 룸 타입 랜덤 생성
      final roomTypes = ["스탠다드 룸"];
      if (random.nextBool()) roomTypes.add("디럭스 룸");
      if (random.nextBool()) roomTypes.add("스위트 룸");

      for (var roomType in roomTypes) {
        final roomRef = docRef.collection("rooms").doc();

        int roomPrice = price;
        if (roomType == "디럭스 룸") roomPrice = (price * 1.5).round();
        if (roomType == "스위트 룸") roomPrice = (price * 2).round();

        batch.set(roomRef, {
          "roomName": roomType,
          "price": roomPrice,
          "salePrice": (roomPrice * 0.8 / 1000).round() * 1000,
          "roomImage": roomImages[random.nextInt(roomImages.length)],
          "standard": 2,
          "max": 2 + random.nextInt(3),
        });
      }
    }

    await batch.commit();
  }

  // ==========================================================
  // 주변 맛집 로드 & Firestore 저장
  // ==========================================================
  Future<void> _loadNearbyRestaurants(Position pos, String city) async {
    setState(() => _loadingRestaurants = true);

    final rawList = await _fetchNearbyItems(pos.latitude, pos.longitude, 39);

    final filtered = rawList
        .where((item) =>
    item["firstimage"] != null &&
        item["firstimage"].toString().isNotEmpty)
        .toList();

    setState(() {
      _nearRestaurants = filtered;
      _loadingRestaurants = false;
    });

    await _saveRestaurantItemsToFirestore(filtered, city);
  }

  // Firestore 저장(맛집)
  Future<void> _saveRestaurantItemsToFirestore(List<dynamic> items, String location) async {
    final batch = FirebaseFirestore.instance.batch();
    final random = Random();

    final descriptions = [
      "신선한 재료와 정성 가득한 조리로 많은 이들이 찾는 인기 맛집입니다.",
      "현지인들에게 사랑받는 곳으로, 깊은 풍미와 정직한 맛이 특징입니다.",
      "깔끔한 맛과 푸짐한 양으로 누구나 만족할 만한 식사를 제공합니다.",
      "편안한 분위기에서 다양한 메뉴를 즐길 수 있는 곳입니다.",
      "특별한 조리법으로 재료 본연의 풍미를 살린 요리를 선보입니다.",
      "가성비 좋고 맛있는 음식으로 꾸준히 호평받고 있는 식당입니다.",
      "담백하고 자극적이지 않은 맛으로 남녀노소 모두에게 추천합니다.",
      "트렌디한 감성과 맛을 함께 느낄 수 있는 인기 있는 음식점입니다.",
      "정갈한 음식과 친절한 서비스로 재방문율이 높은 맛집입니다.",
      "풍부한 향과 깔끔한 뒷맛을 자랑하며 많은 여행객들이 찾는 명소입니다.",
    ];


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
        "description": descriptions[random.nextInt(descriptions.length)],
      });

      batch.set(docRef, newItem);
    }

    await batch.commit();
  }

  // ==========================================================
  // UI 시작
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "COSPICKER",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 검색창
                _searchBar(),

                const SizedBox(height: 16),

                // 상단 메뉴 (숙소 / 맛집 / 커뮤니티)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _topMenu("숙소", "assets/home_icon.png"),
                    _topMenu("맛집", "assets/store_icon.png"),
                    _topMenu("커뮤니티", "assets/community_icon.png"),
                  ],
                ),

                const SizedBox(height: 20),

                // 최근 본 숙소
                const Text(
                  "최근 본 숙소 >",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _horizontalListView(
                  _recentStays,
                  _loadingRecentStays,
                  "최근 본 숙소가 없습니다.",
                ),

                const SizedBox(height: 20),

                // 최근 본 맛집
                const Text(
                  "최근 본 맛집 >",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _horizontalListViewRestaurant(
                  _recentRestaurants,
                  _loadingRecentRestaurants,
                  "최근 본 맛집이 없습니다.",
                ),

                const SizedBox(height: 20),

                // 근처 숙소
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/near',
                    arguments: ContentType.accommodation,
                  ),
                  child: const Text(
                    "근처 숙소 >",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                _horizontalListView(
                  _nearAccommodations,
                  _loadingAccommodations,
                  "주변 숙소가 없습니다.",
                ),

                const SizedBox(height: 20),

                // 근처 맛집
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/near',
                    arguments: ContentType.restaurant,
                  ),
                  child: const Text(
                    "근처 맛집 >",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                _horizontalListViewRestaurant(
                  _nearRestaurants,
                  _loadingRestaurants,
                  "주변 맛집이 없습니다.",
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),

      // 하단 네비게이션
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F0F0),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _bottomItem(context, "홈", "assets/home_icon2.png"),
            _bottomItem(context, "위시", "assets/wish_icon.png"),
            _bottomItem(context, "주변", "assets/location_icon.png"),
            _bottomItem(context, "메시지", "assets/message_icon.png"),
            _bottomItem(context, "프로필", "assets/profile_icon.png"),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 검색창 + 검색 동작
  // ==========================================================
  Widget _searchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset("assets/menu_icon.png", width: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "지역명을 입력하세요",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _openSearchTypeSelector(),
            ),
          ),
          GestureDetector(
            onTap: _openSearchTypeSelector,
            child: Image.asset("assets/search_icon.png", width: 20),
          ),
        ],
      ),
    );
  }

  // 검색어 입력 후 → 숙소/맛집 선택 모달
  void _openSearchTypeSelector() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "검색 유형 선택",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 숙소 검색
              ListTile(
                leading: const Icon(Icons.home, size: 28),
                title: const Text("숙소 검색"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    "/stayList",
                    arguments: {
                      "location": keyword,
                      "date": "",
                      "people": 2,
                    },
                  );
                },
              ),

              // 맛집 검색
              ListTile(
                leading: const Icon(Icons.restaurant, size: 28),
                title: const Text("맛집 검색"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    "/restaurantList",
                    arguments: {
                      "location": keyword,
                    },
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // 상단 메뉴 버튼 (숙소 / 맛집 / 커뮤니티)
  // ==========================================================
  Widget _topMenu(String label, String asset) {
    return InkWell(
      onTap: () {
        if (label == "숙소") {
          Navigator.pushNamed(
            context,
            '/staySearch',
            arguments: ContentType.accommodation,
          );
        } else if (label == "맛집") {
          Navigator.pushNamed(
            context,
            '/restaurantSearch',
            arguments: ContentType.restaurant,
          );
        } else if (label == "커뮤니티") {
          Navigator.pushNamed(context, '/community');
        }
      },
      child: Column(
        children: [
          Image.asset(asset, width: 40),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ==========================================================
  // 숙소 공용 가로 리스트
  // ==========================================================
  Widget _horizontalListView(
      List<dynamic> items,
      bool loading,
      String emptyText,
      ) {
    if (loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text(emptyText)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final acc = items[i];

          return GestureDetector(
            onTap: () async {
              final doc = await FirebaseFirestore.instance
                  .collection("tourItems")
                  .doc(acc['contentid'].toString())
                  .get();

              if (!doc.exists) return;

              final fullData = doc.data() as Map<String, dynamic>;

              saveRecentStay(fullData['contentid'].toString());

              Navigator.pushNamed(
                context,
                '/stayDetail',
                arguments: {
                  ...fullData,
                  "id": acc["contentid"],
                  "date": "",
                  "people": 2,
                },
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(acc['firstimage']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // 맛집용 가로 리스트
  // ==========================================================
  Widget _horizontalListViewRestaurant(
      List<dynamic> items,
      bool loading,
      String emptyText,
      ) {
    if (loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text(emptyText)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final rest = items[i];

          return GestureDetector(
            onTap: () async {
              final doc = await FirebaseFirestore.instance
                  .collection("restaurantItems")
                  .doc(rest['contentid'].toString())
                  .get();

              if (!doc.exists) return;

              final fullData = doc.data() as Map<String, dynamic>;

              saveRecentRestaurant(fullData['contentid'].toString());

              Navigator.pushNamed(
                context,
                '/restaurantDetail',
                arguments: {
                  ...fullData,
                  "contentid": fullData["contentid"],
                },
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(rest['firstimage']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // 하단 네비게이션 아이템
  // ==========================================================
  Widget _bottomItem(BuildContext context, String label, String asset) {
    return InkWell(
      onTap: () {
        if (label == "홈") {
          Navigator.pushNamed(context, '/home');
        } else if (label == "위시") {
          Navigator.pushNamed(context, '/wishList');
        } else if (label == "주변") {
          Navigator.pushNamed(
            context,
            '/near',
            arguments: ContentType.accommodation,
          );
        } else if (label == "메시지") {
          Navigator.pushNamed(context, '/chatRoomList');
        } else if (label == "프로필") {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(asset, width: 28),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
