import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CommunityEditScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const CommunityEditScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  _CommunityEditScreenState createState() => _CommunityEditScreenState();
}

class _CommunityEditScreenState extends State<CommunityEditScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  String? selectedLocation;
  List<String> selectedTags = [];
  String? selectedPostType;
  String? existingImageUrl;

  List<String> postTypes = ["자유", "질문", "정보"];

  List<String> availableTags = [
    "플래너", "인기", "숙소", "맛집", "여행", "맛집추천", "꿀팁"
  ];

  @override
  void initState() {
    super.initState();
    // 기존 데이터로 초기화
    titleController.text = widget.postData['title'] ?? '';
    contentController.text = widget.postData['content'] ?? '';
    selectedPostType = widget.postData['postType'] ?? '자유';
    selectedLocation = widget.postData['location'];
    selectedTags = List<String>.from(widget.postData['tags'] ?? []);
    existingImageUrl = widget.postData['imageUrl'] ?? '';
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  // ----------------- 이미지 선택 -----------------
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        existingImageUrl = null; // 새 이미지를 선택하면 기존 이미지 URL 제거
      });
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

  // ----------------- 게시글 업데이트 -----------------
  Future<void> _updatePost() async {
    String title = titleController.text.trim();
    String content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("제목과 내용을 입력해주세요.")));
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String? imageUrl = existingImageUrl;

    // 새 이미지가 선택된 경우 업로드
    if (selectedImage != null) {
      // 기존 이미지가 있으면 삭제
      if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
        try {
          final oldImageRef = FirebaseStorage.instance.refFromURL(existingImageUrl!);
          await oldImageRef.delete();
        } catch (e) {
          // 이미지 삭제 실패해도 계속 진행
          // 기존 이미지 삭제 실패
        }
      }

      // 새 이미지 업로드
      final fileRef = FirebaseStorage.instance.ref().child(
          "postImages/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await fileRef.putFile(selectedImage!);
      imageUrl = await fileRef.getDownloadURL();
    }

    // keywords 생성 (제목 + 내용 + 태그까지 포함)
    final keywords = {
      ..._generateKeywords(title),
      ..._generateKeywords(content),
      ...selectedTags
    }.toList();

    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(widget.postId)
        .update({
      "title": title,
      "content": content,
      "postType": selectedPostType ?? "자유",
      "location": selectedLocation ?? "",
      "tags": selectedTags,
      "keywords": keywords,
      "imageUrl": imageUrl ?? "",
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("게시글이 수정되었습니다.")),
    );
  }

  // -------------------------- UI --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
        const Text("게시글 수정", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _updatePost,
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
            else if (existingImageUrl != null && existingImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(existingImageUrl!,
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

