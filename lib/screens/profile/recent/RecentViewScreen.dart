import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecentViewedScreen extends StatefulWidget {
  const RecentViewedScreen({super.key});

  @override
  State<RecentViewedScreen> createState() => _RecentViewedScreenState();
}

class _RecentViewedScreenState extends State<RecentViewedScreen> {
  List<Map<String, dynamic>> recentItems = [];
  List<String> stayIds = [];
  List<String> restaurantIds = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRecent();
  }

  // ==========================================================
  // 최근 본 숙소 + 맛집 로딩
  // ==========================================================
  Future<void> _loadAllRecent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    List<Map<String, dynamic>> temp = [];

    // ============== 숙소 ID ==============
    final staysDoc = await FirebaseFirestore.instance
        .collection("recentStays")
        .doc(uid)
        .get();

    stayIds = staysDoc.exists && staysDoc.data()!.containsKey("contentIds")
        ? List<String>.from(staysDoc["contentIds"])
        : [];

    for (var id in stayIds) {
      final doc = await FirebaseFirestore.instance
          .collection("tourItems")
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        temp.add({
          ...doc.data()!,
          "type": "stay",
          "id": id,
        });
      }
    }

    // ============== 맛집 ID ==============
    final restaurantsDoc = await FirebaseFirestore.instance
        .collection("recentRestaurants")
        .doc(uid)
        .get();

    restaurantIds =
    restaurantsDoc.exists && restaurantsDoc.data()!.containsKey("contentIds")
        ? List<String>.from(restaurantsDoc["contentIds"])
        : [];

    for (var id in restaurantIds) {
      final doc = await FirebaseFirestore.instance
          .collection("restaurantItems")
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        temp.add({
          ...doc.data()!,
          "type": "restaurant",
          "id": id,
        });
      }
    }

    setState(() {
      recentItems = temp;
      loading = false;
    });
  }

  // ==========================================================
  // 🔥 개별 삭제 기능
  // ==========================================================
  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    if (item["type"] == "stay") {
      stayIds.remove(item["id"]);
      await FirebaseFirestore.instance
          .collection("recentStays")
          .doc(uid)
          .update({"contentIds": stayIds});
    } else {
      restaurantIds.remove(item["id"]);
      await FirebaseFirestore.instance
          .collection("recentRestaurants")
          .doc(uid)
          .update({"contentIds": restaurantIds});
    }

    setState(() {
      recentItems.remove(item);
    });
  }

  // ==========================================================
  // 🔥 전체 삭제 기능
  // ==========================================================
  Future<void> _deleteAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await FirebaseFirestore.instance
        .collection("recentStays")
        .doc(uid)
        .set({"contentIds": []});

    await FirebaseFirestore.instance
        .collection("recentRestaurants")
        .doc(uid)
        .set({"contentIds": []});

    setState(() {
      recentItems.clear();
    });
  }

  // ==========================================================
  // UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "최근 본 상품",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (recentItems.isNotEmpty)
            TextButton(
              onPressed: _deleteAll,
              child: const Text(
                "전체삭제",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            )
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : recentItems.isEmpty
          ? const Center(
        child: Text(
          "최근 본 상품이 없습니다.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recentItems.length,
        itemBuilder: (context, index) {
          final item = recentItems[index];

          return Dismissible(
            key: Key(item["id"].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteItem(item),

            child: GestureDetector(
              onTap: () {
                if (item["type"] == "stay") {
                  Navigator.pushNamed(
                    context,
                    '/stayDetail',
                    arguments: item,
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    '/restaurantDetail',
                    arguments: item,
                  );
                }
              },

              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item["firstimage"] ?? "",
                        width: 115,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["type"] == "stay" ? "숙소" : "맛집",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            item["title"] ?? "이름 없음",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),
                          Text(
                            item["addr1"] ?? "",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
