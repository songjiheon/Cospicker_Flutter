import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CommunityWriteScreen extends StatefulWidget {
  @override
  _CommunityWriteScreenState createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  String? selectedPostType;
  List<String> postTypes = ["자유", "질문", "정보"]; // 예시

  File? selectedImage;
  String? selectedLocation;
  String? selectedTag;

  final ImagePicker _picker = ImagePicker();

  // 사진 선택
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("글쓰기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async  {
              // 완료 버튼 클릭 → 파이어베이스 업로드
              String title = titleController.text.trim();
              String content = contentController.text.trim();

              if (title.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("제목과 내용을 입력해주세요")),
                );
                return;
              }
              String? imageUrl;

              if (selectedImage != null) {
                final storageRef = FirebaseStorage.instance
                    .ref()
                    .child('postImages/${DateTime.now().millisecondsSinceEpoch}.jpg');
                await storageRef.putFile(selectedImage!);
                imageUrl = await storageRef.getDownloadURL();
              }
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) return;

              final userDoc = await FirebaseFirestore.instance
                  .collection('users') // 유저 정보 컬렉션
                  .doc(currentUser.uid)
                  .get();

              final userData = userDoc.data();
              final userName = userData?['name'] ?? '익명';
              final profileUrl = userData?['profileImageUrl'] ?? '';


              final docRef = FirebaseFirestore.instance.collection('Posts').doc();
              final postId = docRef.id;

              await docRef.set({
                'postId': postId,
                'uid': currentUser.uid,
                'title': title,
                'content': content,
                'likeCount': 0,
                'commentCount': 0,
                'createdAt': FieldValue.serverTimestamp(),
                'postType': selectedPostType ?? "자유",
                'imageUrl': imageUrl ?? "",
                'location': selectedLocation ?? "",
                'tag': selectedTag ?? "",
                'userName': userName,
                'profileUrl': profileUrl ?? '',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("게시글이 성공적으로 등록되었습니다!"),
                  duration: Duration(seconds: 2),
                ),
              );
            },

            child: Text(
              "완료",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF296044)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 글 유형 선택
            DropdownButtonFormField<String>(
              value: selectedPostType,
              items: postTypes
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedPostType = value;
                });
              },
              decoration: InputDecoration(
                hintText: "글 유형 선택",
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            SizedBox(height: 20),

            // 제목
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "제목을 입력하세요",
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),

            // 내용
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                hintText: "내용을 입력하세요",
                border: InputBorder.none,
              ),
              minLines: 6,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 20),

            // 사진 / 위치 / 태그
            Row(
              children: [
                IconButton(
                  icon: Image.asset("assets/photo_icon.png", width: 32, height: 32),
                  onPressed: pickImage,
                ),
                SizedBox(width: 20),
                IconButton(
                  icon: Image.asset("assets/location_icon.png", width: 32, height: 32),
                  onPressed: () {
                    // 위치 선택 기능
                  },
                ),
                SizedBox(width: 20),
                IconButton(
                  icon: Image.asset("assets/tag_icon.png", width: 32, height: 32),
                  onPressed: () {
                    // 태그 선택 기능
                  },
                ),
              ],
            ),
            SizedBox(height: 12),

            // 선택한 사진 미리보기
            if (selectedImage != null)
              Image.file(
                selectedImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Color(0xFFEFEFEF),
                child: Icon(Icons.image, size: 50, color: Colors.grey.shade400),
              ),

            SizedBox(height: 10),

            // 선택된 위치
            if (selectedLocation != null)
              Text("위치: $selectedLocation", style: TextStyle(fontSize: 14, color: Color(0xFF444)))
            else
              Text("위치: 선택 안됨", style: TextStyle(fontSize: 14, color: Color(0xFF444))),

            SizedBox(height: 5),

            // 선택된 태그
            if (selectedTag != null)
              Text("태그: $selectedTag", style: TextStyle(fontSize: 14, color: Color(0xFF444)))
            else
              Text("태그: 선택 안됨", style: TextStyle(fontSize: 14, color: Color(0xFF444))),
          ],
        ),
      ),
    );
  }
}
