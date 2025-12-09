import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

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


  //파이어베이스에서 user 정보 얻어오기
  Future<void> _loadUserInfo() async {
    //파이버베이스 uid 얻기
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    //파이어베이스 data 얻기
    var data = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    //파이어베이스에서 data 얻어와서 변수에 저장
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
          }else{
            userBirth="생년원일 없음";
          }
        }
      });
    }
  }

  //파이어베이스 user 프로필 업데이트
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
      print("프로필 이미지 업로드 실패: $e");
    }
  }


  //UI
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
          onPressed: () => Navigator.pop(context), // 뒤로가기
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
                      // 프로필 이미지
                      ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child:
                        profileImageUrl.isNotEmpty
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
                      // 이미지 변경 버튼
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            _updateProfileImage();
                            print("이미지 변경 클릭");
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
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
              // 회원 정보
              const SizedBox(height: 20),
              const Text(
                "회원 정보",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _infoRow(context, "이름", '/editName', userName),
              _infoRow(context, "휴대폰 번호", '/editPhone', userPhone),
              _infoRow(context, "생년월일", '/editBirth', userBirth),
              _infoRow(context, "성별", '/editGender', userGender),
              _infoRow(context, "친구코드", '', userFriendCode, showArrow: false),


              const SizedBox(height: 10),
              Container(height: 10, color: const Color(0xFFF5F5F5)),

              // 계정 보안
              const SizedBox(height: 20),
              const Text(
                "계정 보안",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              _infoRow(context, "비밀번호 변경", '/editPassword', " ", showArrow: true),

              const SizedBox(height: 20),

              // 접속 기기 관리
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "접속 기기 관리",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    "전체 로그아웃",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF406EFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "로그인 된 모든 기기에서 로그아웃 됩니다.",
                style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),

              const SizedBox(height: 10),
              Container(height: 10, color: const Color(0xFFF5F5F5)),

              // 회원 탈퇴
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  "회원탈퇴",
                  style: TextStyle(fontSize: 15, color: Color(0xFFCC0000)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
              if (route == '/editName') {
                userName = result;
              } else if (route == '/editBirth') {
                userBirth = result;
              } else if (route == '/editPhone') {
                userPhone = result;
              } else if (route == '/editGender') {
                userGender = result;
              }
            });
          }
        }
      },
      child: SizedBox(
        height: 55,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              value.isNotEmpty ? value : "미입력", // 값이 없을 때 "미입력" 표시
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

