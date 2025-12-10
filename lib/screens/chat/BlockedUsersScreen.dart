import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUsersScreen extends StatefulWidget {
  final String uid;
  const BlockedUsersScreen({super.key, required this.uid});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<String> blockedList = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .get();

    blockedList = List<String>.from(doc["blocked"] ?? []);
    setState(() {});
  }

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final doc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data() ??
        {"name": "알 수 없음", "profileImageUrl": "", "status": ""};
  }

  Future<void> _unblockUser(String targetUid) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .update({
      "blocked": FieldValue.arrayRemove([targetUid])
    });

    setState(() {
      blockedList.remove(targetUid);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("차단을 해제했습니다.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("차단한 사용자"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: blockedList.isEmpty
          ? Center(child: Text("차단한 사용자가 없습니다."))
          : ListView.builder(
        itemCount: blockedList.length,
        itemBuilder: (context, index) {
          final blockedUid = blockedList[index];

          return FutureBuilder<Map<String, dynamic>>(
            future: _getUserInfo(blockedUid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListTile(title: Text("불러오는 중..."));
              }

              final user = snapshot.data!;
              final img = user["profileImageUrl"] ?? "";

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  img != "" ? NetworkImage(img) : null,
                  child: img == "" ? Icon(Icons.person) : null,
                ),
                title: Text(user["name"]),
                subtitle: Text(user["status"] ?? ""),
                trailing: TextButton(
                  child: Text(
                    "해제",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => _unblockUser(blockedUid),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
