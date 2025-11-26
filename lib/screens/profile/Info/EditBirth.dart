import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBirthScreen extends StatefulWidget {
  const EditBirthScreen({super.key});

  @override
  State<EditBirthScreen> createState() => _EditBirthScreenState();
}

class _EditBirthScreenState extends State<EditBirthScreen> {
  int selectedYear = 2000;
  int selectedMonth = 1;
  int selectedDay = 1;

  List<int> years = List.generate(100, (index) => 1925 + index);
  List<int> months = List.generate(12, (index) => index + 1);
  List<int> days = List.generate(31, (index) => index + 1);

  bool _isLoading = false;

  //파이어베이스 user에 값 업데이트 TimeStamp
  Future<void> _saveBirth() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 상태가 아닙니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime birthDate = DateTime(selectedYear, selectedMonth, selectedDay);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'birthdate': Timestamp.fromDate(birthDate),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일 저장 완료')),
      );

      final birthStr =
          "${selectedYear.toString()}-${selectedMonth.toString().padLeft(2, '0')}-${selectedDay.toString().padLeft(2, '0')}";

      Navigator.pop(context, birthStr);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "생년월일 입력",
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
          children: [
            const SizedBox(height: 20),
            const Text(
              "생년월일을 입력해주세요",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                // 연도
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPicker(context, years, selectedYear,
                            (val) => setState(() => selectedYear = val)),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$selectedYear년",
                        style: const TextStyle(
                            color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 월
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPicker(context, months, selectedMonth,
                            (val) => setState(() => selectedMonth = val)),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$selectedMonth월",
                        style: const TextStyle(
                            color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 일
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPicker(context, days, selectedDay,
                            (val) => setState(() => selectedDay = val)),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$selectedDay일",
                        style: const TextStyle(
                            color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBirth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  "저장",
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

  void _showPicker(BuildContext context, List<int> items, int selected,
      ValueChanged<int> onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 250,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController:
                FixedExtentScrollController(initialItem: items.indexOf(selected)),
                onSelectedItemChanged: (index) => onSelected(items[index]),
                children: items
                    .map((e) => Center(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
                ))
                    .toList(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("완료"),
            )
          ],
        ),
      ),
    );
  }
}
