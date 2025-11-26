import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditGenderScreen extends StatefulWidget {
  const EditGenderScreen({super.key});

  @override
  State<EditGenderScreen> createState() => _EditGenderScreenState();
}

class _EditGenderScreenState extends State<EditGenderScreen> {
  String? _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  //파이어베이스에서 user 값 가져오기
  Future<void> _loadGender() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      _selectedGender = data['gender'];
    });
  }

  //파이어베이스에 값 저장
  Future<void> _saveGender() async {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("성별을 선택해주세요.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'gender': _selectedGender});

      Navigator.pop(context,_selectedGender);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 실패: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset("assets/close_icon.png", width: 26, height: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "성별을 선택해주세요",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 100),

            // 라디오 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 남성
                Row(
                  children: [
                    Radio<String>(
                      value: "남성",
                      groupValue: _selectedGender,
                      activeColor: Color(0xFF406EFF),
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const Text("남성", style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 30),
                  ],
                ),

                // 여성
                Row(
                  children: [
                    Radio<String>(
                      value: "여성",
                      groupValue: _selectedGender,
                      activeColor: Color(0xFF406EFF),
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const Text("여성", style: TextStyle(fontSize: 22)),
                  ],
                ),
              ],
            ),

            Spacer(),

            // 저장 버튼
            SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGender,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Color(0xFFF2F2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  "저장",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
