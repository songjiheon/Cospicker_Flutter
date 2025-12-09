import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CommunityWriteScreen extends StatefulWidget {
  @override
  _CommunityWriteScreenState createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  String? selectedLocation;
  List<String> selectedTags = [];

  String? selectedPostType;
  List<String> postTypes = ["자유", "질문", "정보"];

  List<String> availableTags = [
    "플래너", "인기", "숙소", "맛집", "여행", "맛집추천", "꿀팁"
  ];

  // ----------------- 이미지 선택 -----------------
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => selectedImage = File(image.path));
    }
  }

  // ----------------- 태그 선택 BottomSheet -----------------
  void _openTagSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("태그 선택",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 10,
                  children: availableTags.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      selectedColor: Colors.green.shade200,
                      onSelected: (v) {
                        setModalState(() {
                          if (v) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("완료"),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ----------------- 위치 선택 BottomSheet -----------------
  void _openLocationSelector() {
    final locations = ["서울", "경기", "강원", "부산", "대전", "제주"];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: locations.map((loc) {
            return ListTile(
              title: Text(loc),
              onTap: () {
                setState(() => selectedLocation = loc);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  // ----------------- keywords 자동 생성 -----------------
  List<String> _generateKeywords(String text) {
    List<String> keywords = [];
    List<String> words = text.split(RegExp(r"\s+"));

    for (var w in words) {
      if (w.trim().isNotEmpty) keywords.add(w.trim());
    }
    return keywords;
  }

  // ----------------- 게시글 업로드 -----------------
  Future<void> _uploadPost() async {
    String title = titleController.text.trim();
    String content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("제목과 내용을 입력해주세요.")));
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data() ?? {};
    final userName = userData['name'] ?? '익명';
    final profileUrl = userData['profileImageUrl'] ?? '';

    // 이미지 업로드
    String? imageUrl;
    if (selectedImage != null) {
      final fileRef = FirebaseStorage.instance.ref().child(
          "postImages/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await fileRef.putFile(selectedImage!);
      imageUrl = await fileRef.getDownloadURL();
    }

    final postRef = FirebaseFirestore.instance.collection("Posts").doc();
    final postId = postRef.id;

    // keywords 생성 (제목 + 내용 + 태그까지 포함)
    final keywords = {
      ..._generateKeywords(title),
      ..._generateKeywords(content),
      ...selectedTags
    }.toList();

    await postRef.set({
      "postId": postId,
      "uid": currentUser.uid,
      "title": title,
      "content": content,
      "createdAt": Timestamp.now(),
      "likeCount": 0,
      "commentCount": 0,
      "profileUrl": profileUrl,
      "userName": userName,
      "imageUrl": imageUrl ?? "",
      "postType": selectedPostType ?? "자유",
      "location": selectedLocation ?? "",
      "tags": selectedTags,
      "keywords": keywords, // 🔥 검색 최적화 핵심
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("게시글이 등록되었습니다.")),
    );
  }

  // -------------------------- UI --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
        const Text("글쓰기", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _uploadPost,
            child: const Text(
              "완료",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF296044)),
            ),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 글 유형 선택
            DropdownButtonFormField<String>(
              value: selectedPostType,
              items: postTypes
                  .map((type) =>
                  DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPostType = v),
              decoration: InputDecoration(
                hintText: "글 유형 선택",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),

            const SizedBox(height: 20),

            // 제목
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "제목을 입력하세요",
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 17),
            ),

            const SizedBox(height: 10),

            // 내용
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: "내용을 입력하세요",
                border: InputBorder.none,
              ),
              minLines: 6,
              maxLines: null,
            ),

            const SizedBox(height: 20),

            // 아이콘 버튼 (사진, 위치, 태그)
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.photo, size: 30),
                    onPressed: pickImage),
                const SizedBox(width: 10),
                IconButton(
                    icon: const Icon(Icons.location_on, size: 30),
                    onPressed: _openLocationSelector),
                const SizedBox(width: 10),
                IconButton(
                    icon: const Icon(Icons.tag, size: 30),
                    onPressed: _openTagSelector),
              ],
            ),

            const SizedBox(height: 10),

            // 이미지 미리보기
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(selectedImage!,
                    width: double.infinity, height: 200, fit: BoxFit.cover),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.image,
                    size: 50, color: Colors.black26),
              ),

            const SizedBox(height: 10),

            // 위치 표시
            Text(
              "위치: ${selectedLocation ?? "선택 안됨"}",
              style: const TextStyle(color: Colors.black87),
            ),

            const SizedBox(height: 4),

            // 태그 표시
            Wrap(
              spacing: 8,
              children: selectedTags
                  .map((tag) => Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() => selectedTags.remove(tag));
                },
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
