import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'NoticeDetail.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "공지사항",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      //파이어베이스에서 Notices값 가져와서 UI표시
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Notices")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator()
            );
          }

          final notices = snapshot.data!.docs;

          if (notices.isEmpty) {
            return const Center(
              child: Text(
                "등록된 공지사항이 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final data = notices[index].data() as Map<String, dynamic>;

              final title = data["title"] ?? "제목 없음";
              final content = data["content"] ?? "내용 없음";
              final date = (data["createdAt"] as Timestamp).toDate();
              final formatted = DateFormat("yyyy-MM-dd").format(date);

              return ListTile(
                title: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Text(
                  formatted,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoticeDetailScreen(
                        title: title,
                        content: content,
                        date: formatted,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
