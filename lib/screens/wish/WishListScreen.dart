import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경 흰색
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _topBar(context),
                _tabBar(),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _wishFolderTab("wish_stay"), // 숙소
                      _wishFolderTab("wish_restaurant"), // 맛집
                      _wishFolderTab("wish_planner"), // 계획 플래너
                    ],
                  ),
                ),
              ],
            ),

            // 하단 + 새 폴더 버튼
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(child: _newFolderButton()),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // 상단 바
  // -----------------------------
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              "위시 리스트",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 48), // 오른쪽 여백 맞추기용
        ],
      ),
    );
  }

  // -----------------------------
  // 탭바
  // -----------------------------
  Widget _tabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.black,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      tabs: const [
        Tab(text: "숙소"),
        Tab(text: "맛집"),
        Tab(text: "계획 플래너"),
      ],
    );
  }

  // -----------------------------
  // 탭 하나(폴더 목록) - 공통
  // -----------------------------
  Widget _wishFolderTab(String collectionName) {
    final stream = FirebaseFirestore.instance
        .collection("users")
        .doc(_uid)
        .collection(collectionName)
        .orderBy("createdAt", descending: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "아직 생성된 폴더가 없습니다.\n아래의 [+ 새 폴더] 버튼을 눌러 만들어보세요.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2열
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4, // 가로가 조금 더 긴 느낌
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data["name"] ?? "";
            return _folderCard(
              name: name,
              folderId: docs[index].id,
              collectionName: collectionName,
            );
          },
        );
      },
    );
  }

  // 폴더 카드 (회색 박스 + 이름)
  Widget _folderCard({
    required String name,
    required String folderId,
    required String collectionName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/wishFolderDetail',
          arguments: {
            "uid": _uid,
            "collectionName": collectionName,
            "folderId": folderId,
            "folderName": name,
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // -----------------------------
  // 하단 + 새 폴더 버튼
  // -----------------------------
  Widget _newFolderButton() {
    return GestureDetector(
      onTap: _openNewFolderDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "+ 새 폴더",
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 새 폴더 추가 다이얼로그
  Future<void> _openNewFolderDialog() async {
    final controller = TextEditingController();
    final currentTabIndex = _tabController.index;

    // 현재 탭에 따라 컬렉션 이름 매핑
    String collectionName;
    switch (currentTabIndex) {
      case 0:
        collectionName = "wish_stay";
        break;
      case 1:
        collectionName = "wish_restaurant";
        break;
      default:
        collectionName = "wish_planner";
        break;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("새 폴더 만들기"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "폴더 이름을 입력하세요 (예: 제주도, 떡볶이, 오현의 플래너)",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(_uid)
                    .collection(collectionName)
                    .add({
                      "name": name,
                      "createdAt": FieldValue.serverTimestamp(),
                    });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("추가"),
            ),
          ],
        );
      },
    );
  }
}
