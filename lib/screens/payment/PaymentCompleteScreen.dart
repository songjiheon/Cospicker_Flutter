// 📌 PaymentCompleteScreen.dart
import 'package:flutter/material.dart';

class PaymentCompleteScreen extends StatelessWidget {
  final Map<String, dynamic>? paymentData;

  const PaymentCompleteScreen({super.key, this.paymentData});

  @override
  Widget build(BuildContext context) {
    final roomName = paymentData?["roomName"] ?? "";
    final date = paymentData?["date"] ?? "";
    final people = paymentData?["people"] ?? 1;
    final price = paymentData?["price"] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 90, color: Color(0xFF4A6DFF)),
            const SizedBox(height: 20),

            const Text(
              "결제가 완료되었습니다!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Text(roomName, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),

            Text(date, style: const TextStyle(color: Colors.grey)),
            Text("$people명", style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),
            Text(
              "$price원",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // 홈으로 돌아가기 (첫 화면까지 pop)
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "홈으로 돌아가기",
            style: TextStyle(fontSize: 17),
          ),
        ),
      ),
    );
  }
}
