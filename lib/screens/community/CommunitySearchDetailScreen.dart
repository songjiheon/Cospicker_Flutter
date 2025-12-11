import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_post_screen.dart';

class CommunitySearchDetailScreen extends StatefulWidget {
  final String keyword;
  final String? type; // 자유 / 질문 / 정보 / 전체
  final bool isTagSearch; // 태그 검색 여부

  const CommunitySearchDetailScreen({
    super.key,
    required this.keyword,
    this.type,
    this.isTagSearch = false,
  });

  @override
  State<CommunitySearchDetailScreen> createState() =>
      _CommunitySearchDetailScreenState();
}

class _CommunitySearchDetailScreenState
    extends State<CommunitySearchDetailScreen> {
  // 검색 방식: 일반글 / 태그
  late String filterType;

  // 글유형 선택
  String selectedPostType = "전체";

  @override
  void initState() {
    super.initState();

    // 초기값 적용
    selectedPostType = widget.type ?? "전체";
    // 태그 검색이면 초기 필터 타입을 "태그"로 설정
    filterType = widget.isTagSearch ? "태그" : "일반글";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "COSPICKER",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),

          _searchBar(),
          const SizedBox(height: 12),

          _postTypeSelector(),     // 🔥 글유형 필터 UI
          const SizedBox(height: 10),

          _filterTabs(),           // 일반글 / 태그 검색 방식
          const SizedBox(height: 10),

          Expanded(child: _postList()),
        ],
      ),
    );
  }

  // ---------------------- 검색창 ----------------------
  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search),
          const SizedBox(width: 10),
          Text(widget.keyword,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ---------------------- 글유형 선택 ----------------------
  Widget _postTypeSelector() {
    final types = ["전체", "자유", "질문", "정보"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        children: types.map((t) {
          final bool selected = selectedPostType == t;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedPostType = t;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Color(0xFF296044) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------- 검색 방식: 일반글 / 태그 ----------------------
  Widget _filterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => filterType = "일반글"),
            child: Text(
              "일반글",
              style: TextStyle(
                fontWeight:
                filterType == "일반글" ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 30),
          GestureDetector(
            onTap: () => setState(() => filterType = "태그"),
            child: Text(
              "#${widget.keyword}",
              style: TextStyle(
                fontWeight:
                filterType == "태그" ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------- 게시글 쿼리 ----------------------
  Widget _postList() {
    final keyword = widget.keyword.trim();

    if (keyword.isEmpty) {
      return const Center(
          child: Text("검색어를 입력해주세요.", style: TextStyle(color: Colors.grey)));
    }

    Query query = FirebaseFirestore.instance.collection("Posts");

    // 🔥 글유형 필터 적용
    if (selectedPostType != "전체") {
      query = query.where("postType", isEqualTo: selectedPostType);
    }

    // 🔥 검색 방식 적용
    // arrayContains와 orderBy를 함께 사용하면 composite index 필요
    // 모든 검색에서 클라이언트 사이드 정렬 사용
    if (filterType == "일반글") {
      query = query.where("keywords", arrayContains: keyword);
    } else {
      query = query.where("tags", arrayContains: keyword);
    }

    // orderBy를 사용하지 않고 클라이언트 사이드에서 정렬
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "오류가 발생했습니다: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Firestore 인덱스가 필요할 수 있습니다.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
              child: Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.grey)));
        }

        var docs = snapshot.data!.docs.toList();

        // 클라이언트 사이드에서 createdAt 기준 내림차순 정렬
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)["createdAt"] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)["createdAt"] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // 내림차순
        });

        if (docs.isEmpty) {
          return const Center(
              child: Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return _postItem(data);
          },
        );
      },
    );
  }

  // ---------------------- 게시글 UI ----------------------
  Widget _postItem(Map<String, dynamic> data) {
    final String postId = data["postId"] ?? "";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityPostScreen(postId: postId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: data["profileUrl"] != ""
                      ? NetworkImage(data["profileUrl"])
                      : null,
                ),
                const SizedBox(width: 10),
                Text(data["userName"] ?? "익명",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  _timeAgo((data["createdAt"] as Timestamp).toDate()),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              data["title"] ?? "",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Text(
              data["content"] ?? "",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text("${data["likeCount"] ?? 0}"),
                const SizedBox(width: 14),
                const Icon(Icons.chat_bubble_outline,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text("${data["commentCount"] ?? 0}"),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------- 시간 표시 ----------------------
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}분 전";
    if (diff.inHours < 24) return "${diff.inHours}시간 전";
    return "${diff.inDays}일 전";
  }
}
