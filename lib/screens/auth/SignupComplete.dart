import 'package:flutter/material.dart';
import '../home/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({super.key});

   @override
  _SignupCompleteScreenState createState() => _SignupCompleteScreenState();
}
class _SignupCompleteScreenState extends State<SignupCompleteScreen> {

  String generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();

    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> generateUniqueFriendCode() async {
    String code = "";
    bool exists = true;

    while (exists) {
      // 6자리 랜덤 코드 생성
      code = generateRandomCode(6);

      // Firestore에서 같은 코드가 있는지 확인
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get();

      exists = query.docs.isNotEmpty;
    }

    return code;
  }
  Future<void> saveFriendCode() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final code = await generateUniqueFriendCode();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'friendCode': code});

    print("친구코드 생성됨: $code");
  }
  @override
  void initState() {
    super.initState();

    // 화면 열리면 자동 실행
    saveFriendCode();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Stack(
          children: [
            // 닫기 버튼
            Positioned(
              top: 10,
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.close, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 중앙 체크 + 가입 완료 텍스트
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/check_icon.png',
                    width: 70,
                    height: 70,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '가입 완료',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // 하단 홈으로 돌아가기 버튼
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('홈으로 돌아가기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
