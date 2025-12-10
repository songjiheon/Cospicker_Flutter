import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "안녕하세요, ${userName.isNotEmpty ? userName : '게스트'}님 👋",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "오늘도 좋은 여행 되세요",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.purple.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 검색창
                _searchBar(),

                const SizedBox(height: 24),

                // 상단 메뉴 (숙소 / 맛집 / 커뮤니티)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _topMenu("숙소", "assets/home_icon.png", Icons.hotel_outlined),
                      _topMenu("맛집", "assets/store_icon.png", Icons.restaurant_outlined),
                      _topMenu("커뮤니티", "assets/community_icon.png", Icons.chat_bubble_outline),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 최근 본 숙소
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "최근 본 숙소",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("전체보기", style: TextStyle(color: Colors.blue)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _horizontalListView(
                  _recentStays,
                  _loadingRecentStays,
                  "최근 본 숙소가 없습니다.",
                ),

                const SizedBox(height: 32),

                // 최근 본 맛집
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "최근 본 맛집",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("전체보기", style: TextStyle(color: Colors.blue)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _horizontalListViewRestaurant(
                  _recentRestaurants,
                  _loadingRecentRestaurants,
                  "최근 본 맛집이 없습니다.",
                ),

                const SizedBox(height: 32),

                // 근처 숙소
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "근처 숙소",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/near',
                        arguments: ContentType.accommodation,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("전체보기", style: TextStyle(color: Colors.blue)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _horizontalListView(
                  _nearAccommodations,
                  _loadingAccommodations,
                  "주변 숙소가 없습니다.",
                ),

                const SizedBox(height: 32),

                // 근처 맛집
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "근처 맛집",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/near',
                        arguments: ContentType.restaurant,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("전체보기", style: TextStyle(color: Colors.blue)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _bottomItem(context, "홈", "assets/home_icon2.png", Icons.home_outlined),
            _bottomItem(context, "위시", "assets/wish_icon.png", Icons.favorite_border),
            _bottomItem(context, "주변", "assets/location_icon.png", Icons.location_on_outlined),
            _bottomItem(context, "메시지", "assets/message_icon.png", Icons.chat_bubble_outline),
            _bottomItem(context, "프로필", "assets/profile_icon.png", Icons.person_outline),
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
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openSearchTypeSelector,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade600, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    enabled: false,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "어디로 여행가세요?",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _openSearchTypeSelector(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
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
  Widget _topMenu(String label, String asset, IconData icon) {
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: label == "숙소"
                      ? [Colors.blue.shade400, Colors.blue.shade600]
                      : label == "맛집"
                          ? [Colors.orange.shade400, Colors.orange.shade600]
                          : [Colors.purple.shade400, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
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

              await saveRecentStay(fullData['contentid'].toString());

              if (!context.mounted) return;
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

              await saveRecentRestaurant(fullData['contentid'].toString());

              if (!context.mounted) return;
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
  Widget _bottomItem(BuildContext context, String label, String asset, IconData icon) {
    final isCurrent = ModalRoute.of(context)?.settings.name == '/home' && label == "홈";
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
          Icon(
            icon,
            size: 26,
            color: isCurrent ? Colors.blue.shade600 : Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isCurrent ? Colors.blue.shade600 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
