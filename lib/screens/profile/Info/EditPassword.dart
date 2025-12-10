import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final auth = FirebaseAuth.instance;

  final nowPwController = TextEditingController();
  final newPwController = TextEditingController();
  final newPwCheckController = TextEditingController();

  @override
  void dispose() {
    nowPwController.dispose();
    newPwController.dispose();
    newPwCheckController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    final nowPw = nowPwController.text.trim();
    final newPw = newPwController.text.trim();
    final newPwCheck = newPwCheckController.text.trim();

    if (newPw != newPwCheck) {
      showToast("새 비밀번호가 일치하지 않습니다.");
      return;
    }
    if (newPw.length < 6) {
      showToast("비밀번호는 최소 6자리 이상이어야 합니다.");
      return;
    }

    final user = auth.currentUser;
    if (user == null) {
      showToast("로그인이 필요합니다.");
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: nowPw,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPw);

      showSuccessDialog("비밀번호가 변경되었습니다.");
    } catch (e) {
      showToast("변경 실패: ${e.toString()}");
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("완료"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("확인"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar 추가해서 닫기 버튼도 위로 이동
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "비밀번호 변경",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Image.asset("assets/close_icon.png", width: 26, height: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "비밀번호를 변경해주세요",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 30),

            // Scroll 영역
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildLabel("현재 비밀번호"),
                    buildTextBox(
                      controller: nowPwController,
                      hint: "현재 비밀번호",
                    ),
                    SizedBox(height: 25),

                    buildLabel("새 비밀번호"),
                    buildTextBox(
                      controller: newPwController,
                      hint: "새 비밀번호",
                    ),
                    SizedBox(height: 25),

                    buildLabel("새 비밀번호 확인"),
                    buildTextBox(
                      controller: newPwCheckController,
                      hint: "새 비밀번호 확인",
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F2F2),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "저장",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget buildTextBox({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Color(0xFFF2F2F2),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
          ),
        ),
      ),
    );
  }
}
