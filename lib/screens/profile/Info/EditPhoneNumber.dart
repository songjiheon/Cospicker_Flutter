import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EditPhoneScreen extends StatefulWidget {
  const EditPhoneScreen({super.key});

  @override
  State<EditPhoneScreen> createState() => _EditPhoneScreenState();
}

class _EditPhoneScreenState extends State<EditPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _authController = TextEditingController();

  bool _showNotice = false;
  String? _verificationId;
  bool _isCodeSent = false;

  Timer? _timer;
  int _seconds = 180; // 3분 타이머

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 180;
      _showNotice = false;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds <= 0) {
        timer.cancel();
        setState(() {
          _showNotice = true;
        });
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  String get _formattedTime {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // 인증번호 전송
  void _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("자동 인증 완료")));
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("인증 실패: ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isCodeSent = true;
        });
        _startTimer(); // 타이머 시작
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("인증번호가 전송되었습니다.")));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // 인증번호 확인
  void _verifyCode() async {
    final code = _authController.text.trim();
    if (_verificationId == null || code.isEmpty) return;

    try {
      // 인증 코드 검증 (자동 로그인 하지 않음)
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      print("현재 user.uid: ${user.uid}");

      // 기존 UID의 Firestore에 phoneNumber만 추가
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'phoneNumber': _phoneController.text.trim()},
         );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("휴대폰 등록 완료")));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("인증 실패: $e")));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 번호 칸과 인증칸 같은 길이 지정
    final fieldWidth = double.infinity;
    final fieldHeight = 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '휴대폰 번호 입력',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/close_icon.png', width: 26, height: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "휴대폰 번호를\n입력해주세요",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: fieldHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "숫자만 입력",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: fieldHeight,
                  child: TextButton(
                    onPressed: _sendCode,
                    child: const Text(
                      "전송",
                      style: TextStyle(color: Color(0xFF406EFF)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "인증 번호",
              style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: fieldHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _authController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: "인증 번호 6자리",
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedTime,
                  style: const TextStyle(color: Color(0xFFFF3B30)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isCodeSent ? _sendCode : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "재전송",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_showNotice)
              const Text(
                "입력 시간이 초과되었어요. 인증 번호를 재전송해주세요.",
                style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: fieldHeight,
              child: ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "완료",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
