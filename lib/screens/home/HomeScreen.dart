import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget  {
  const HomeScreen({super.key});
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  //파이어베이스에서 user 정보 얻어오기
  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userName = doc['name'] ?? "사용자";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 상단 스크롤 가능 영역
      body: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 80),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COSPICKER 타이틀
              Text(
                "COSPICKER",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // 검색 바
              Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Image.asset("assets/menu_icon.png", width: 20, height: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "검색어를 입력하세요",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Image.asset("assets/search_icon.png", width: 20, height: 20),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // 상단 3개 메뉴
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _topMenu("숙소", "assets/home_icon.png"),
                  _topMenu("맛집", "assets/store_icon.png"),
                  _topMenu("커뮤니티", "assets/community_icon.png"),
                ],
              ),
              SizedBox(height: 20),

              Text("최근 본 숙소 >", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _horizontalListView(),

              SizedBox(height: 16),
              Text("$userName님 근처 숙소 >",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _horizontalListView(),

              // 근처 맛집 >
              SizedBox(height: 16),
              Text("근처 맛집 >", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _horizontalListView(),

              SizedBox(height: 20),
            ],
          ),
        ),
      )
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xFFF0F0F0),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _bottomItem(context,"홈", "assets/home_icon2.png"),
            _bottomItem(context,"위시", "assets/wish_icon.png"),
            _bottomItem(context,"주변", "assets/location_icon.png"),
            _bottomItem(context,"메시지", "assets/message_icon.png"),
            _bottomItem(context,"프로필", "assets/profile_icon.png"),
          ],
        ),
      ),
    );
  }

  // 상단 메뉴
  Widget _topMenu(String label, String asset) {
    return InkWell(
      onTap: () {
        if(label=="커뮤니티"){
          Navigator.pushNamed(context, '/community');
        }
      },
      child: Column(
        children: [
          Image.asset(asset, width: 40, height: 40),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // 가로 리스트
  Widget _horizontalListView() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  // 하단 네비 버튼
  Widget _bottomItem(BuildContext context,String label, String asset) {
    return InkWell(
      onTap: () {
        if(label=="프로필"){
          Navigator.pushNamed(context, '/profile');
        }else if(label=="홈"){
          Navigator.pushNamed(context, '/home');
        }else if(label=="메시지"){
          Navigator.pushNamed(context, '/chatRoomList');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(asset, width: 28, height: 28),
          SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
