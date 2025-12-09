import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // 최근 본 항목 저장 (공통 함수)
  // ========================================
  Future<void> _saveRecentItem(String contentId, String collectionName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection(collectionName).doc(user.uid);

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
    } catch (e) {
      debugPrint("최근 본 항목 저장 실패 ($collectionName): $e");
    }
  }

  // ========================================
  // 최근 본 숙소 저장
  // ========================================
  Future<void> saveRecentStay(String contentId) async {
    await _saveRecentItem(contentId, "recentStays");
  }

  // ========================================
  // 최근 본 맛집 저장
  // ========================================
  Future<void> saveRecentRestaurant(String contentId) async {
    await _saveRecentItem(contentId, "recentRestaurants");
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
      if (placemarks.isEmpty) {
        return "Unknown";
      }
      final place = placemarks.first;
      return place.administrativeArea ?? "Unknown";
    } on PlatformException catch (e) {
      debugPrint("도시 변환 실패 (PlatformException): ${e.message}");
      return "Unknown";
    } catch (e) {
      debugPrint("도시 변환 실패: $e");
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
        debugPrint("위치 권한 없음");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("위치 가져오기 실패: $e");
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
      debugPrint("Tour API 오류: $e");
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

    await _saveStayItemsToFirestore(filtered, city);
  }

  // Firestore 저장(숙소)
  Future<void> _saveStayItemsToFirestore(
      List<dynamic> items,
      String location,
      ) async {
    final batch = FirebaseFirestore.instance.batch();
    final random = Random();

    for (var item in items) {
      final id = item["contentid"].toString();
      final docRef =
      FirebaseFirestore.instance.collection("tourItems").doc(id);

      final newItem = Map<String, dynamic>.from(item);
      newItem.addAll({
        "city": location,
        "price": (10000 + random.nextInt(40000)),
        "rating": (30 + random.nextInt(21)) / 10.0,
        "review": random.nextInt(500),
      });

      batch.set(docRef, newItem);
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
  Future<void> _saveRestaurantItemsToFirestore(
      List<dynamic> items,
      String location,
      ) async {
    final batch = FirebaseFirestore.instance.batch();
    final random = Random();

    for (var item in items) {
      final id = item["contentid"].toString();
      final docRef =
      FirebaseFirestore.instance.collection("restaurantItems").doc(id);

      final newItem = Map<String, dynamic>.from(item);
      newItem.addAll({
        "city": location,
        "avgPrice": (5000 + random.nextInt(20000)),
        "rating": (30 + random.nextInt(21)) / 10.0,
        "review": random.nextInt(500),
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
