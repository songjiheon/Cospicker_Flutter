import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  const RestaurantDetailScreen({super.key, required this.restaurantData});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  bool isSaved = false;
  String? savedFolderId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkIfSaved();

    // ⭐ 최근 본 맛집 저장
    _saveRecentRestaurant();
  }


  /// 현재 맛집이 저장되어 있는지 체크
  Future<void> _checkIfSaved() async {
    final contentId = widget.restaurantData["contentid"];

    final folderSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_restaurant")
        .get();

    for (var folder in folderSnap.docs) {
      final itemSnap =
      await folder.reference.collection("items").doc(contentId).get();

      if (itemSnap.exists) {
        setState(() {
          isSaved = true;
          savedFolderId = folder.id;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.restaurantData;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _imageHeader(context),
          _topInfo(data),
          _actionButtons(data),
          _tabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _homeTab(data),
                _menuTab(data),
                _reviewTab(data),
                _photoTab(data),
                _infoTab(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 헤더 이미지 + 뒤로가기 + 상단 찜 버튼
  // ---------------------------------------------------------
  Widget _imageHeader(BuildContext context) {
    return Stack(
      children: [
        Image.network(
          widget.restaurantData["firstimage"] ?? "",
          height: 230,
          width: double.infinity,
          fit: BoxFit.cover,
        ),

        // 뒤로가기
        Positioned(
          top: 40,
          left: 16,
          child: _circleButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
        ),

        // 상단 위시 하트
        Positioned(
          top: 40,
          right: 16,
          child: _circleButton(
            icon: isSaved ? Icons.favorite : Icons.favorite_border,
            onTap: isSaved ? _unSaveFromFolder : _openWishFolderSelector,
          ),
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  // ---------------------------------------------------------
  // 제목 + 별점 + 소개
  // ---------------------------------------------------------
  Widget _topInfo(Map data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data["title"] ?? "",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text("${data["rating"] ?? 0}  (${data["review"] ?? 0} 리뷰)"),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data["overview"] ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 하단 액션버튼 (저장 / 위치)
  // ---------------------------------------------------------
  Widget _actionButtons(Map data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 저장 버튼 (하단)
        GestureDetector(
          onTap: () {
            if (isSaved) {
              _unSaveFromFolder();
            } else {
              _openWishFolderSelector();
            }
          },
          child: Column(
            children: [
              Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: isSaved ? Colors.red : Colors.black,
              ),
              const SizedBox(height: 4),
              Text(
                "저장",
                style: TextStyle(
                    color: isSaved ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // 위치 버튼
        GestureDetector(
          onTap: () {
            final lat = double.tryParse(data["mapy"].toString()) ?? 0.0;
            final lng = double.tryParse(data["mapx"].toString()) ?? 0.0;

            Navigator.pushNamed(
              context,
              "/restaurantMap",
              arguments: {
                "lat": lat,
                "lng": lng,
                "title": data["title"] ?? "",
              },
            );
          },
          child: const Column(
            children: [
              Icon(Icons.location_on_outlined, size: 28),
              SizedBox(height: 4),
              Text("위치"),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 탭바
  // ---------------------------------------------------------
  Widget _tabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.black,
      tabs: const [
        Tab(text: "홈"),
        Tab(text: "메뉴"),
        Tab(text: "리뷰"),
        Tab(text: "사진"),
        Tab(text: "정보"),
      ],
    );
  }

  // ---------------------------------------------------------
  // 홈 탭
  // ---------------------------------------------------------
  Widget _homeTab(Map data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("주소"),
        Text(data["addr1"] ?? ""),

        const SizedBox(height: 20),
        _sectionTitle("전화번호"),
        Text(data["tel"] ?? "정보 없음"),

        const SizedBox(height: 20),
        _sectionTitle("메뉴", onTap: () => _tabController.animateTo(1)),
        _fakeMenuPreview(),

        const SizedBox(height: 20),
        _sectionTitle("리뷰", onTap: () => _tabController.animateTo(2)),
        _reviewPreview(),

        const SizedBox(height: 20),
        _sectionTitle("사진", onTap: () => _tabController.animateTo(3)),
        _photoPreview(data),

        const SizedBox(height: 20),
        _sectionTitle("기본 정보", onTap: () => _tabController.animateTo(4)),
        Text(data["overview"] ?? "상세 설명 없음"),
      ],
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text("더보기 >", style: TextStyle(color: Colors.grey)),
          )
      ],
    );
  }

  Widget _fakeMenuPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("• 떡볶이 - 5,000원"),
        Text("• 순대 - 5,000원"),
        Text("• 오뎅 - 4,000원"),
      ],
    );
  }

  Widget _reviewPreview() {
    return const Text("미리보기 리뷰 2개 표시 예정");
  }

  // ---------------------------------------------------------
  // 리뷰 탭
  // ---------------------------------------------------------
  Widget _reviewTab(Map data) {
    final contentId = data["contentid"];

    return Column(
      children: [
        const SizedBox(height: 10),

        // 리뷰작성버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, "/restaurantReview",
                  arguments: {"contentid": contentId, "title": data["title"]});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text("리뷰 작성하기",
                style: TextStyle(color: Colors.white)),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("restaurantItems")
                .doc(contentId)
                .collection("reviews")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty)
                return const Center(child: Text("등록된 리뷰가 없습니다."));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: snapshot.data!.docs.map((doc) {
                  final r = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("⭐ ${r["rating"]}",
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(r["text"] ?? ""),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 사진 탭
  // ---------------------------------------------------------
  Widget _photoTab(Map data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Image.network(data["firstimage"] ?? "",
            height: 200, fit: BoxFit.cover),
      ],
    );
  }

  Widget _photoPreview(Map data) {
    return Image.network(data["firstimage"] ?? "",
        height: 120, fit: BoxFit.cover);
  }

  // ---------------------------------------------------------
  // 정보 탭
  // ---------------------------------------------------------
  Widget _infoTab(Map data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(data["overview"] ?? ""),
      ],
    );
  }

  // ---------------------------------------------------------
  // 메뉴 탭 (추후 확장)
  // ---------------------------------------------------------
  Widget _menuTab(Map data) {
    return const Center(
      child: Text("메뉴 정보는 추후 업데이트됩니다."),
    );
  }

  // ---------------------------------------------------------
  // 폴더 선택 모달
  // ---------------------------------------------------------
  void _openWishFolderSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: 330,
          child: Column(
            children: [
              const SizedBox(height: 14),
              const Text("저장 폴더 선택",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection("wish_restaurant")
                      .orderBy("createdAt")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(
                          child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                          child: Text("폴더가 없습니다.\n위시리스트에서 폴더를 먼저 만들어주세요."));
                    }

                    return ListView(
                      children: docs.map((folderDoc) {
                        final folder =
                        folderDoc.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(folder["name"] ?? ""),
                          onTap: () async {
                            await _saveToFolder(folderDoc.id);
                            if (mounted) Navigator.pop(context);
                          },
                        );
                      }).toList(),
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

  // ---------------------------------------------------------
  // 저장 기능
  // ---------------------------------------------------------
  Future<void> _saveToFolder(String folderId) async {
    final data = widget.restaurantData;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_restaurant")
        .doc(folderId)
        .collection("items")
        .doc(data["contentid"])
        .set({
      "title": data["title"],
      "image": data["firstimage"],
      "addr": data["addr1"],
      "rating": data["rating"],
      "contentid": data["contentid"],
      "type": "restaurant",
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      isSaved = true;
      savedFolderId = folderId;
    });
  }
  Future<void> _saveRecentRestaurant() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final contentId = widget.restaurantData["contentid"].toString();

    final docRef = FirebaseFirestore.instance
        .collection("recentRestaurants")
        .doc(user.uid);

    final snap = await docRef.get();

    List<String> list = [];

    if (snap.exists && snap.data()!.containsKey("contentIds")) {
      list = List<String>.from(snap["contentIds"]);
    }

    // 기존 목록에서 제거 후 앞에 다시 추가
    list.remove(contentId);
    list.insert(0, contentId);

    // 최대 10개 유지
    if (list.length > 10) list = list.sublist(0, 10);

    if (snap.exists) {
      await docRef.update({"contentIds": list});
    } else {
      await docRef.set({"contentIds": list});
    }
  }

  // ---------------------------------------------------------
  // 저장 해제 기능
  // ---------------------------------------------------------
  Future<void> _unSaveFromFolder() async {
    if (savedFolderId == null) return;

    final contentId = widget.restaurantData["contentid"];

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_restaurant")
        .doc(savedFolderId)
        .collection("items")
        .doc(contentId)
        .delete();

    setState(() {
      isSaved = false;
      savedFolderId = null;
    });
  }
}
