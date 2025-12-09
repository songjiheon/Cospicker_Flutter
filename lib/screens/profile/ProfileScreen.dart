import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cospicker/screens/profile/reservation/StayReservationScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  String userName = "";
  String userEmail = "";
  String profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserInfo();
  }

  // --------------------- 유저 정보 로드 ---------------------
  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var data =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (data.exists) {
      final userData = data.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['name'] ?? "이름 없음";
        userEmail = userData['email'] ?? "이메일 없음";
        profileImageUrl = userData['profileImageUrl'] ?? "";
      });
    }
  }

  // --------------------- 전체 로그아웃 기능 ---------------------
  Future<void> _logoutAllDevices() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final randomToken = DateTime.now().millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({'logoutToken': randomToken});

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // --------------------- 전체 로그아웃 Dialog ---------------------
  void _showLogoutAllDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("전체 로그아웃",
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                const Text(
                  "정말 모든 기기에서 로그아웃 하시겠습니까?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("취소"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _logoutAllDevices();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text("로그아웃",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------- 일반 로그아웃 Dialog ---------------------
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("로그아웃",
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                const Text(
                  "정말 로그아웃 하시겠습니까?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("취소"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text("로그아웃",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------- UI -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("COSPICKER",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBar: _bottomNavBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileCard(),
              const SizedBox(height: 25),
              _quickMenuSection(),
              const SizedBox(height: 25),

              const Text("예약 내역",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _menuTile(
                "숙소",
                Icons.hotel,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StayReservationScreen()),
                  );
                },
              ),

              const SizedBox(height: 30),

              const Text("설정",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _menuTile("공지사항", Icons.notifications, onTap: () {
                Navigator.pushNamed(context, '/notice');
              }),

              _menuTile("내 정보 관리", Icons.settings, onTap: () {
                Navigator.pushNamed(context, '/myInfo');
              }),

              // 기존 로그아웃
              _menuTile("로그아웃", Icons.logout,
                  color: Colors.red, onTap: _showLogoutDialog),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------- 프로필 카드 ---------------------
  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 33,
            backgroundImage: profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : const AssetImage("assets/profile_icon.png") as ImageProvider,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(userEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  // --------------------- 상단 아이콘 메뉴 ---------------------
  Widget _quickMenuSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickMenu("최근 본 상품", Icons.visibility, route: '/recentViewed'),
          _quickMenu("내 글", Icons.article, route: '/myPost'),
          _quickMenu("댓글", Icons.comment, route: '/myComment'),
          _quickMenu("알림", Icons.notifications, route: '/notifications'),
        ],
      ),
    );
  }

  Widget _quickMenu(String text, IconData icon, {String? route}) {
    return InkWell(
      onTap: () {
        if (route != null) Navigator.pushNamed(context, route);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // --------------------- 메뉴 타일 ---------------------
  Widget _menuTile(String title, IconData icon,
      {Color color = Colors.black, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(fontSize: 16, color: color)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // --------------------- 하단 네비 ---------------------
  Widget _bottomNavBar(BuildContext context) {
    return Container(
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
    );
  }
}

// --------------------- 하단 버튼 ---------------------
Widget _bottomItem(BuildContext context, String label, String asset) {
  return InkWell(
    onTap: () {
      switch (label) {
        case "홈":
          Navigator.pushNamed(context, '/home');
          break;
        case "위시":
          Navigator.pushNamed(context, '/wishList');
          break;
        case "주변":
          Navigator.pushNamed(context, '/near');
          break;
        case "메시지":
          Navigator.pushNamed(context, '/chatRoomList');
          break;
        case "프로필":
          Navigator.pushNamed(context, '/profile');
          break;
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
