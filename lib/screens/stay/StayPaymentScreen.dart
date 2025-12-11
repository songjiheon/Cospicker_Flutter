import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../payment/PaymentLoadingScreen.dart';

class StayPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const StayPaymentScreen({super.key, required this.paymentData});

  @override
  State<StayPaymentScreen> createState() => _StayPaymentScreenState();
}

class _StayPaymentScreenState extends State<StayPaymentScreen> {
  // 예약자 입력 필드
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String selectedPayMethod = "";
  bool agreeAll = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      emailController.text = user.email ?? "";
    }
  }

  // ==========================================
  // 🔥 Firestore 저장 함수 (roomImage 포함)
  // ==========================================
  Future<void> saveReservation() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = widget.paymentData;

    await FirebaseFirestore.instance.collection("reservation").add({
      "uid": uid,
      "roomName": data["roomName"],
      "price": data["price"],
      "date": data["date"],
      "people": data["people"],
      "roomImage": data["roomImage"] ?? "", // 이미지 저장 필수!
      "buyerName": nameController.text,
      "buyerPhone": phoneController.text,
      "buyerEmail": emailController.text,
      "paymentMethod": selectedPayMethod,
      "status": "upcoming",
      "createdAt": Timestamp.now(),
    });
  }

  // ==========================================
  // 환불 규정 BottomSheet
  // ==========================================
  void _showRefundPolicySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                "환불 규정 안내",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),
              const Text(
                "✔ 체크인 7일 전 : 전액 환불\n"
                    "✔ 체크인 3~6일 전 : 50% 환불\n"
                    "✔ 체크인 2일 전 ~ 당일 : 환불 불가\n\n"
                    "※ 환불 시 PG사 결제 수수료가 발생할 수 있습니다.",
                style: TextStyle(fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("확인", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.paymentData;

    final price = data["price"];
    final date = data["date"];

    // ==========================================
    // 🔥 날짜 파싱(오류 방지)
    // ==========================================
    String checkIn = date;
    String checkOut = date;

    if (date.contains("~")) {
      final parts = date.split("~");
      if (parts.length == 2) {
        checkIn = parts[0].trim();
        checkOut = parts[1].trim();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("예약", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Period ----------------
            const Text("Period",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              children: [
                _periodBox("Check In", checkIn, "15:00"),
                const SizedBox(width: 12),
                _periodBox("Check Out", checkOut, "11:00"),
              ],
            ),

            const SizedBox(height: 28),

            // ---------------- 예약자 정보 ----------------
            const Text("예약자 정보",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            _textField("이름", nameController),
            const SizedBox(height: 12),
            _textField("전화번호", phoneController,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _textField("이메일", emailController,
                keyboardType: TextInputType.emailAddress),

            const SizedBox(height: 28),

            // ---------------- 결제 정보 ----------------
            const Text("결제 정보",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            _priceRow("객실 가격(1박)", price),
            const Divider(thickness: 1, height: 28),
            _priceRow("총 결제 금액", price, isTotal: true),

            TextButton(
              onPressed: _showRefundPolicySheet,
              child: const Text(
                "환불 규정 보기",
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ---------------- 결제 수단 ----------------
            const Text("결제 수단",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _payMethodButton("KAKAOPAY"),
                _payMethodButton("TOSSPAY"),
                _payMethodButton("신용/체크 카드"),
                _payMethodButton("휴대폰 결제"),
                _payMethodButton("KBPAY"),
                _payMethodButton("NAVERPAY"),
                _payMethodButton("PAYCO"),
              ],
            ),

            const SizedBox(height: 30),

            // ---------------- 전체 동의 ----------------
            GestureDetector(
              onTap: () => setState(() => agreeAll = !agreeAll),
              child: Row(
                children: [
                  Icon(
                    agreeAll
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  const Text("전체 동의", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ---------------- 결제 버튼 ----------------
      bottomNavigationBar: Container(
        height: 70,
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: (selectedPayMethod.isNotEmpty && agreeAll)
              ? () async {

            // 입력값 검증
            if (nameController.text.isEmpty ||
                phoneController.text.isEmpty ||
                emailController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("예약자 정보를 모두 입력해주세요.")),
              );
              return;
            }

            await saveReservation();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentLoadingScreen(
                  paymentData: widget.paymentData,
                ),
              ),
            );
          }
              : null,

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "결제하기",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------- UI Widgets ----------------

  Widget _periodBox(String title, String date, String time) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              date,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _payMethodButton(String text) {
    final isSelected = selectedPayMethod == text;

    return GestureDetector(
      onTap: () => setState(() => selectedPayMethod = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String title, int price, {bool isTotal = false}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 17 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          "$price원",
          style: TextStyle(
            fontSize: isTotal ? 17 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
