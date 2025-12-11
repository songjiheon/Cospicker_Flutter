import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cospicker/core/utils/error_handler.dart';

class MyinfoScreen extends StatefulWidget {
  const MyinfoScreen({super.key});

  @override
  _MyinfoScreenState createState() => _MyinfoScreenState();
}

class _MyinfoScreenState extends State<MyinfoScreen> {
  String userName = "";
  String userEmail = "";
  String userPhone = "";
  String userBirth = "";
  String userGender = "";
  String profileImageUrl = "";
  String userFriendCode = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // ===============================
  // Firebase 사용자 정보 불러오기
  // ===============================
  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var data = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (data.exists) {
      final userData = data.data() as Map<String, dynamic>;
      setState(() {
        userFriendCode = userData['friendCode'] ?? "미생성";
        userName = userData['name'] ?? "이름 없음";
        userEmail = userData['email'] ?? "이메일 없음";
        userPhone = userData['phoneNumber'] ?? "미입력";
        userGender = userData['gender'] ?? "미입력";
        profileImageUrl = userData['profileImageUrl'] ?? "";

        if (userData['birthdate'] != null) {
          var birth = userData['birthdate'];
          if (birth is Timestamp) {
            userBirth = DateFormat('yyyy-MM-dd').format(birth.toDate());
          } else if (birth is String) {
            userBirth = birth;
          } else {
            userBirth = "생년월일 없음";
          }
        }
      });
    }
  }

  // ===============================
  // 프로필 이미지 업데이트
  // ===============================
  Future<void> _updateProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return;

      final File file = File(pickedImage.path);
      final ref = FirebaseStorage.instance.ref('profile_images/$uid');
      await ref.putFile(file);

      final String downloadUrl = await ref.getDownloadURL();

      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        profileImageUrl = downloadUrl;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleError(
          context,
          e,
          customMessage: '프로필 이미지 업로드에 실패했습니다.',
        );
      }
    }
  }

  // ===============================
  // 전체 로그아웃 기능
  // ===============================
  Future<void> _logoutAllDevices() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 모든 기기에서 로그아웃하도록 토큰 발행
    final randomToken = DateTime.now().millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({'logoutToken': randomToken});

    // 현재 기기 로그아웃
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // 전체 로그아웃 Dialog
  void _showLogoutAllDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("전체 로그아웃",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                        child: const Text(
                          "로그아웃",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "COSPICKER",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Image.asset("assets/back_icon.png", width: 22, height: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 영역
              Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: profileImageUrl.isNotEmpty
                            ? Image.network(
                          profileImageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          "assets/profile_icon.png",
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _updateProfileImage,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    userName.isNotEmpty ? userName : "닉네임",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text("회원 정보",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _infoRow(context, "이름", '/editName', userName),
              _infoRow(context, "휴대폰 번호", '/editPhone', userPhone),
              _infoRow(context, "생년월일", '/editBirth', userBirth),
              _infoRow(context, "성별", '/editGender', userGender),
              _infoRow(context, "친구코드", '', userFriendCode, showArrow: false),

              const SizedBox(height: 10),
              Container(height: 10, color: Color(0xFFF5F5F5)),

              const SizedBox(height: 20),
              const Text("계정 보안",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              _infoRow(context, "비밀번호 변경", '/editPassword', " ", showArrow: true),

              const SizedBox(height: 20),

              // ===============================
              // 전체 로그아웃 버튼 (수정된 부분)
              // ===============================
              GestureDetector(
                onTap: _showLogoutAllDialog,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "접속 기기 관리",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const Text(
                      "전체 로그아웃",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF406EFF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              const Text(
                "로그인 된 모든 기기에서 로그아웃 됩니다.",
                style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),

              const SizedBox(height: 10),
              Container(height: 10, color: Color(0xFFF5F5F5)),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // 정보 Row 위젯
  // ===============================
  Widget _infoRow(
      BuildContext context,
      String title,
      String route,
      String value, {
        bool showArrow = true,
      }) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        if (route.isNotEmpty) {
          final result = await Navigator.pushNamed(context, route);
          if (result != null && result is String && result.isNotEmpty) {
            setState(() {
              if (route == '/editName') userName = result;
              else if (route == '/editBirth') userBirth = result;
              else if (route == '/editPhone') userPhone = result;
              else if (route == '/editGender') userGender = result;
            });
          }
        }
      },
      child: SizedBox(
        height: 55,
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            Text(
              value.isNotEmpty ? value : "미입력",
              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            if (showArrow) ...[
              const SizedBox(width: 6),
              Image.asset("assets/arrow_icon.png", width: 18, height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
