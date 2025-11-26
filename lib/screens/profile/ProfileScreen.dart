import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  //파이어베이스에서 user 정보 얻어오기
  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var data = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (data.exists) {
      final userData = data.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['name'] ?? "이름 없음";
        userEmail = userData['email'] ?? "이메일 없음";
        profileImageUrl = userData['profileImageUrl'] ?? "";
      });
    }
  }

  // 로그아웃 시 작동
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                const Text(
                  "로그아웃",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "정말 로그아웃 하시겠습니까?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "취소",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 로그아웃 버튼
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "로그아웃",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "COSPICKER",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      //아래 바
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //프로필 카드
              _profileCard(),

              const SizedBox(height: 25),

              // 상단 메뉴
              _quickMenuSection(),

              const SizedBox(height: 25),


              const Text(
                "예약 내역",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _menuTile("숙소",'/myInfo', Icons.hotel),

              const SizedBox(height: 30),


              const Text(
                "설정",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _menuTile("공지사항",'/notice', Icons.notifications),
              _menuTile("내 정보 관리",'/myInfo', Icons.settings),
              _menuTile("로그아웃",'/myInfo', Icons.logout, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }


  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // 프로필 이미지
           CircleAvatar(
            radius: 33,
             backgroundColor: Colors.transparent,
          backgroundImage: profileImageUrl.isNotEmpty ?
          NetworkImage(profileImageUrl)        // Firestore URL
             :  AssetImage("assets/profile_icon.png") as ImageProvider,
          ),
          const SizedBox(width: 16),

          // 이름/이메일
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }


  //상단 메뉴
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
          _quickMenu("최근 본 상품", Icons.visibility),
          _quickMenu("내 글", Icons.article,route: '/myPost'),
          _quickMenu("댓글", Icons.comment, route: '/myComment'),
          _quickMenu("알림", Icons.notifications),
        ],
      ),
    );
  }

  // quit 메뉴
  Widget _quickMenu(String text, IconData icon,{String? route}) {
    return InkWell(
        onTap: () {
          if (route != null) Navigator.pushNamed(context, route);
          },
    child:  Column(
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

  //  리스트 메뉴 아이템
  Widget _menuTile(String title,String route, IconData icon, {Color color = Colors.black}) {
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
        title: Text(
          title,
          style: TextStyle(fontSize: 16, color: color),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if(title=="로그아웃"){
            _showLogoutDialog();
          }else if(route.isNotEmpty)
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}

// 아래 메뉴 아이템
Widget _bottomItem(BuildContext context,String label, String asset) {
  return InkWell(
    onTap: () {
      if(label=="프로필"){
        Navigator.pushNamed(context, '/profile');
      }else if(label=="홈"){
        Navigator.pushNamed(context, '/home');
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



