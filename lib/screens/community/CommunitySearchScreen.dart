import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CommunitySearchDetailScreen.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedPostType = "전체";
  List<String> recentKeywords = [];

  final List<String> postTypes = ["전체", "자유", "질문", "정보"];
  final List<String> categories = ["플래너", "인기", "숙소", "맛집"];

  @override
  void initState() {
    super.initState();
    _loadRecentKeywords();
  }

  Future<void> _loadRecentKeywords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      recentKeywords = prefs.getStringList("recent_keywords") ?? [];
    });
  }

  Future<void> _saveKeyword(String keyword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("recent_keywords") ?? [];

    list.remove(keyword);
    list.insert(0, keyword);
    if (list.length > 10) list = list.sublist(0, 10);

    prefs.setStringList("recent_keywords", list);
    setState(() => recentKeywords = list);
  }

  void _startSearch(String keyword) {
    if (keyword.trim().isEmpty) return;

    _saveKeyword(keyword.trim());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunitySearchDetailScreen(
          keyword: keyword.trim(),
          type: selectedPostType == "전체" ? null : selectedPostType,
        ),
      ),
    );
  }

  Future<void> _clearRecent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("recent_keywords");
    setState(() => recentKeywords = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
        ),
        title: const Text("COSPICKER",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 검색창
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "검색어를 입력하세요",
                        border: InputBorder.none,
                      ),
                      onSubmitted: _startSearch,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 글 유형 선택
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedPostType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: postTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedPostType = value!);
                      },
                    ),
                  ),
                  const Text("태그"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 카테고리 버튼
            Wrap(
              spacing: 15,
              children: categories.map((label) {
                return GestureDetector(
                  onTap: () => _startSearch(label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(label),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 최근 검색
            Row(
              children: [
                const Text("최근 검색",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: _clearRecent,
                  child:
                  const Text("전체 삭제", style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              children: recentKeywords.map((keyword) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _startSearch(keyword),
                        child: Text(keyword),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          setState(() => recentKeywords.remove(keyword));
                          SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                          prefs.setStringList(
                              "recent_keywords", recentKeywords);
                        },
                        child: const Icon(Icons.close, size: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
