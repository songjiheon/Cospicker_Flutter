import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'StayDatePeopleScreen.dart';
import 'StayReviewScreen.dart';
import 'StayRoomListScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StayDetailScreen extends StatefulWidget {
  final Map<String, dynamic> stayData;

  const StayDetailScreen({super.key, required this.stayData});

  @override
  State<StayDetailScreen> createState() => _StayDetailScreenState();
}

class _StayDetailScreenState extends State<StayDetailScreen> {
  String dateRange = "12.3 - 12.5";
  int people = 2;

  bool isWished = false; // ❤️ 찜 여부

  @override
  void initState() {
    super.initState();
    _checkIsWished();
  }

  // ------------------ 찜 여부 확인 ------------------
  Future<void> _checkIsWished() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_stay_all") // ⭐ 전체 저장되는 통합 폴더
        .doc(widget.stayData["contentid"].toString())
        .get();

    setState(() {
      isWished = snap.exists;
    });
  }

  // ------------------ 찜 저장 ------------------
  Future<void> _saveStayGlobal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_stay_all")
        .doc(widget.stayData["contentid"])
        .set({
      "title": widget.stayData["title"],
      "image": widget.stayData["firstimage"] ?? "",
      "addr": widget.stayData["addr1"] ?? "",
      "rating": widget.stayData["rating"] ?? 0,
      "contentid": widget.stayData["contentid"],
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      isWished = true;
    });
  }

  // ------------------ 찜 삭제 ------------------
  Future<void> _removeStayGlobal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_stay_all")
        .doc(widget.stayData["contentid"])
        .delete();

    setState(() {
      isWished = false;
    });
  }

  // ------------------ roomImage 안전 파싱 ------------------
  List<String> _parseImageList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return [raw];
    }
    return [];
  }

  // ------------------ reviewImages 파싱 ------------------
  List<String> _parseReviewImages(dynamic raw) {
    if (raw is List) return List<String>.from(raw);
    return [];
  }

  // 뒤로가기 전달
  void _popWithResult() {
    Navigator.pop(context, {"date": dateRange, "people": people});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _popWithResult();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: _bottomButton(),
        body: Column(
          children: [
            _imageHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleSection(),
                    _reviewSection(context),
                    _datePeopleSection(context),
                    _facilitySection(),
                    SizedBox(height: 10),
                    _mapSection(),
                    SizedBox(height: 20),
                    _detailInfoSection(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------- 하단 버튼 -------------------------------
  Widget _bottomButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4A6DFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StayRoomListScreen(
                  stayData: widget.stayData,
                  date: dateRange,
                  people: people,
                ),
              ),
            );
          },
          child: Text(
            "모든 객실 보기",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ------------------------------- 이미지 헤더 -------------------------------
  Widget _imageHeader() {
    final images = _parseImageList(widget.stayData["roomImage"]);

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          (images.isEmpty)
              ? Container(
            color: Colors.grey.shade300,
            child: Center(child: Icon(Icons.broken_image, size: 70)),
          )
              : PageView.builder(
            itemCount: images.length,
            itemBuilder: (_, i) {
              return Image.network(
                images[i],
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              );
            },
          ),

          // 뒤로가기
          Positioned(
            top: 40,
            left: 16,
            child: _circleButton(Icons.arrow_back_ios_new, _popWithResult),
          ),

          // 찜 버튼 ❤️
          Positioned(
            top: 40,
            right: 16,
            child: _circleButton(
              isWished ? Icons.favorite : Icons.favorite_border,
                  () async {
                if (isWished) {
                  // 찜 취소
                  bool confirm = await _showRemoveDialog();
                  if (confirm) {
                    await _removeStayGlobal();
                  }
                } else {
                  // 찜 추가 → 폴더 선택
                  _openStayWishFolder();
                }
              },
              activeColor: isWished ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap,
      {Color activeColor = Colors.black87}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: activeColor, size: 20),
      ),
    );
  }

  // ------------------------------------------------------
  // 찜 취소 Dialog
  // ------------------------------------------------------
  Future<bool> _showRemoveDialog() async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("찜 취소"),
        content: Text("이 숙소를 찜에서 제거할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("아니요"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("네"),
          ),
        ],
      ),
    ) ??
        false;
  }

  // ------------------------------------------------------
  // 위시 폴더 선택 BottomSheet
  // ------------------------------------------------------
  void _openStayWishFolder() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SizedBox(
          height: 330,
          child: Column(
            children: [
              SizedBox(height: 14),
              Text("숙소 폴더 선택",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection("wish_stay")
                      .orderBy("createdAt")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "숙소 위시 폴더가 없습니다.\n위시 리스트 화면에서 폴더를 생성해주세요.",
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, index) {
                        final folderData =
                        docs[index].data() as Map<String, dynamic>;
                        final folderId = docs[index].id;

                        return ListTile(
                          title: Text(folderData["name"] ?? "이름 없음"),
                          onTap: () async {
                            await _saveStayGlobal(); // 전체 목록에 저장
                            await _saveStayToFolder(folderId); // 선택한 폴더에도 저장
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------- 선택한 폴더에 저장 -------------------------
  Future<void> _saveStayToFolder(String folderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wish_stay")
        .doc(folderId)
        .collection("items")
        .doc(widget.stayData["contentid"])
        .set({
      "title": widget.stayData["title"],
      "image": widget.stayData["firstimage"] ?? "",
      "addr": widget.stayData["addr1"] ?? "",
      "rating": widget.stayData["rating"] ?? 0,
      "contentid": widget.stayData["contentid"],
      "type": "stay",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------- 제목 -------------------------------
  Widget _titleSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.stayData["title"] ?? "",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 16),
              SizedBox(width: 4),
              Text(widget.stayData["addr1"] ?? ""),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.phone, size: 16),
              SizedBox(width: 4),
              Text(widget.stayData["tel"] ?? ""),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------- 리뷰 요약 -------------------------------
  Widget _reviewSection(BuildContext context) {
    final reviewImages = _parseReviewImages(widget.stayData["reviewImages"]);

    return Container(
      padding: EdgeInsets.all(16),
      color: Color(0xFFF7F7F7),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 4),
              Text("${widget.stayData['rating']} (${widget.stayData['review']})",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StayReviewScreen(
                        stayName: widget.stayData["title"] ?? "",
                        rating:
                        (widget.stayData["rating"] ?? 0) * 1.0,
                        reviewImages: reviewImages,
                      ),
                    ),
                  );
                },
                child: Text("전체보기 >",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ReviewBox()),
              SizedBox(width: 12),
              Expanded(child: _ReviewBox()),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------- 날짜/인원 -------------------------------
  Widget _datePeopleSection(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StayDatePeopleScreen()),
        );

        if (result != null) {
          setState(() {
            dateRange = result["date"] ?? dateRange;
            people = result["people"] ?? people;
          });
        }
      },
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Color(0xFFF1F1F1),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month, size: 18),
              SizedBox(width: 10),
              Text(dateRange),
              Spacer(),
              Icon(Icons.people_alt_outlined),
              SizedBox(width: 6),
              Text("$people명"),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------- 편의시설 -------------------------------
  Widget _facilitySection() {
    final items = [
      {"icon": Icons.local_parking, "text": "주차장"},
      {"icon": Icons.fitness_center, "text": "헬스장"},
      {"icon": Icons.wifi, "text": "인터넷"},
      {"icon": Icons.pool, "text": "수영장"},
      {"icon": Icons.smoke_free, "text": "금연"},
    ];

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("편의시설 및 서비스",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((e) {
              return Column(
                children: [
                  Icon(e["icon"] as IconData, size: 32),
                  SizedBox(height: 6),
                  Text(e["text"] as String),
                ],
              );
            }).toList(),
          ),

        ],
      ),
    );
  }

  // ------------------------------- 지도 -------------------------------
  Widget _mapSection() {
    final lat = double.tryParse(widget.stayData["mapy"].toString()) ?? 0;
    final lng = double.tryParse(widget.stayData["mapx"].toString()) ?? 0;

    final LatLng pos = LatLng(lat, lng);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("위치",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: GoogleMap(
              initialCameraPosition:
              CameraPosition(target: pos, zoom: 16),
              markers: {
                Marker(
                  markerId: MarkerId(widget.stayData["contentid"]),
                  position: pos,
                ),
              },
              zoomControlsEnabled: false,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------- 상세 설명 -------------------------------
  Widget _detailInfoSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("숙소 상세 설명",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text(widget.stayData["description"] ?? "상세 정보가 없습니다.",
              style: TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

// ------------------- 리뷰 UI 박스 -------------------
class _ReviewBox extends StatelessWidget {
  const _ReviewBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text("숙소가 깔끔하고 조용해서 좋았어요!",
          style: TextStyle(fontSize: 13)),
    );
  }
}
