import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WishFolderDetailScreen extends StatefulWidget {
  final String uid;
  final String collectionName; // wish_stay / wish_restaurant / wish_planner
  final String folderId;
  final String folderName;

  const WishFolderDetailScreen({
    super.key,
    required this.uid,
    required this.collectionName,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<WishFolderDetailScreen> createState() => _WishFolderDetailScreenState();
}

class _WishFolderDetailScreenState extends State<WishFolderDetailScreen> {
  late String folderName;

  @override
  void initState() {
    super.initState();
    folderName = widget.folderName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(folderName),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "rename") _renameFolder();
              if (value == "delete") _deleteFolder();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "rename", child: Text("폴더 이름 변경")),
              const PopupMenuItem(
                value: "delete",
                child: Text("폴더 삭제", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),

      body: _itemList(),
    );
  }

  // ============================================================
  // 📌 폴더 내부 아이템 목록
  // ============================================================
  Widget _itemList() {
    final stream = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection(widget.collectionName)
        .doc(widget.folderId)
        .collection("items")
        .orderBy("createdAt", descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("이 폴더에는 아직 항목이 없습니다."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _itemCard(doc.id, data);
          },
        );
      },
    );
  }

  // ============================================================
  // 📌 아이템 카드
  // ============================================================
  Widget _itemCard(String docId, Map<String, dynamic> data) {
    final type = data["type"] ?? "";
    final iconEmoji = type == "stay"
        ? "🏨"
        : type == "restaurant"
        ? "🍽️"
        : "📝";

    return Dismissible(
      key: Key(docId),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => _deleteItem(docId),

      child: GestureDetector(
        onTap: () => _openDetail(data),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data["image"] ?? "",
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$iconEmoji  ${data["title"] ?? ""}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data["addr"] ?? "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text("${data["rating"] ?? 0}"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📌 상세 이동
  // ============================================================
  Future<void> _openDetail(Map<String, dynamic> data) async {
    final type = data["type"];
    final contentId = data["contentid"];

    // ⭐ 숙소 상세
    if (type == "stay") {
      final doc = await FirebaseFirestore.instance
          .collection("tourItems")  // 🔥 stayItems → tourItems 로 수정
          .doc(contentId)
          .get();

      if (!doc.exists) return;

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        "/stayDetail",
        arguments: doc.data() as Map<String, dynamic>,
      );
      return;
    }

    // ⭐ 맛집 상세
    if (type == "restaurant") {
      final doc = await FirebaseFirestore.instance
          .collection("restaurantItems")
          .doc(contentId)
          .get();

      if (!doc.exists) return;

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        "/restaurantDetail",
        arguments: doc.data() as Map<String, dynamic>,
      );
      return;
    }

    if (type == "planner") {
      // 나중에 추가
    }
  }



  // ============================================================
  // 📌 아이템 삭제
  // ============================================================
  Future<void> _deleteItem(String docId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection(widget.collectionName)
        .doc(widget.folderId)
        .collection("items")
        .doc(docId)
        .delete();
  }

  // ============================================================
  // 📌 폴더 이름 변경
  // ============================================================
  Future<void> _renameFolder() async {
    final controller = TextEditingController(text: folderName);

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("폴더 이름 변경"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "새 폴더 이름 입력"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.uid)
                    .collection(widget.collectionName)
                    .doc(widget.folderId)
                    .update({"name": newName});

                setState(() => folderName = newName);

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("변경"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // 📌 폴더 삭제 (전체 items 삭제 후 폴더 삭제)
  // ============================================================
  Future<void> _deleteFolder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("폴더 삭제"),
          content: const Text("폴더 내 모든 저장된 항목도 함께 삭제됩니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "삭제",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // 1) items 전체 삭제
    final itemsRef = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection(widget.collectionName)
        .doc(widget.folderId)
        .collection("items");

    final items = await itemsRef.get();
    for (var doc in items.docs) {
      await doc.reference.delete();
    }

    // 2) 폴더 삭제
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection(widget.collectionName)
        .doc(widget.folderId)
        .delete();

    if (mounted) Navigator.pop(context);
  }
}
