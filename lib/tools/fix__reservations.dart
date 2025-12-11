import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> fixExistingReservations() async {
  final ref = FirebaseFirestore.instance.collection("reservation");

  final snapshot = await ref.get();

  for (final doc in snapshot.docs) {
    final data = doc.data();

    // status 필드 없으면 upcoming 자동 설정
    if (!data.containsKey("status")) {
      await doc.reference.update({"status": "upcoming"});
      print("status 추가: ${doc.id}");
    }

    // roomName이 null 이면 기본값 지정
    if (data["roomName"] == null || data["roomName"] == "") {
      await doc.reference.update({"roomName": "숙소 이름 미지정"});
      print("roomName 수정: ${doc.id}");
    }
  }

  print("🔥 모든 예약 문서 보정 완료!");
}
