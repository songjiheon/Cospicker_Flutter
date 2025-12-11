// 📌 PaymentLoadingScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'PaymentCompleteScreen.dart';

class PaymentLoadingScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const PaymentLoadingScreen({super.key, required this.paymentData});

  @override
  State<PaymentLoadingScreen> createState() => _PaymentLoadingScreenState();
}

class _PaymentLoadingScreenState extends State<PaymentLoadingScreen> {
  @override
  void initState() {
    super.initState();

    // 🔥 2초 후 Firestore 저장 + 완료 화면 이동
    Future.delayed(const Duration(seconds: 2), () async {
      await saveReservation(widget.paymentData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentCompleteScreen(paymentData: widget.paymentData),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Color(0xFF4A6DFF)),
            SizedBox(height: 20),
            Text(
              "결제 중입니다...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// 🔥 Firestore에 예약 정보 저장 함수
// -------------------------------------------------------
Future<void> saveReservation(Map<String, dynamic> data) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance.collection("reservation").add({
    "uid": uid,
    "roomName": data["roomName"],
    "price": data["price"],
    "date": data["date"],
    "people": data["people"],
    "createdAt": Timestamp.now(),
  });
}
