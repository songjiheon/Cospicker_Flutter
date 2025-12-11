import 'package:flutter/material.dart';
import 'package:cospicker/screens/stay/StayReviewPolicyScreen.dart';

class StayReviewScreen extends StatefulWidget {
  final String stayName;
  final double rating;
  final List<String> reviewImages;

  const StayReviewScreen({
    super.key,
    required this.stayName,
    required this.rating,
    required this.reviewImages,
  });

  @override
  State<StayReviewScreen> createState() => _StayReviewScreenState();
}

class _StayReviewScreenState extends State<StayReviewScreen> {
  bool photoOnly = false;
  String selectedRoom = "전체(19)";
  String sortOption = "최신 작성 순";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text("후기", style: TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StayReviewPolicyScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ 숙소 평점 ------------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // ⭐ 가로 중앙 배치
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "숙소 평점",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Icon(Icons.star, size: 42, color: Colors.black),
                      Text(
                        widget.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ------------------ 후기 사진 ------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    "후기 사진",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    "전체보기 (${widget.reviewImages.length}) >",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 이미지 없을 때와 있을 때 분기
            if (widget.reviewImages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      "등록된 사진이 없습니다",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, i) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.reviewImages[i],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: widget.reviewImages.length,
                ),
              ),

            const SizedBox(height: 20),

            // ------------------ 필터 ------------------
            _filterSection(),

            const Divider(height: 1, color: Color(0xFFE5E5E5)),

            // ------------------ 리뷰 카드 ------------------
            _reviewCard(),
            _reviewCard(),
            _reviewCard(),
          ],
        ),
      ),
    );
  }

  // ------------------ 필터 UI ------------------
  Widget _filterSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 객실 선택 dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Text(selectedRoom),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => photoOnly = !photoOnly),
                child: Row(
                  children: [
                    Icon(
                      photoOnly
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.black54,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    const Text("사진후기만 보기"),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(sortOption),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------ 리뷰 카드 UI ------------------
  Widget _reviewCard() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 별점 + 메뉴
          Row(
            children: const [
              Icon(Icons.star, size: 16),
              Icon(Icons.star, size: 16),
              Icon(Icons.star, size: 16),
              Icon(Icons.star_half, size: 16),
              Icon(Icons.star_border, size: 16),
              Spacer(),
              Icon(Icons.more_vert),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            "나는야행복\n---카페\n내가 다녀본 숙소 중에 제일 최악…",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 6),

          GestureDetector(
            onTap: () {},
            child: const Text(
              "더보기 ˅",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),

          const SizedBox(height: 12),

          // 리뷰 사진이 있을 때만 표시
          if (widget.reviewImages.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                widget.reviewImages.first,
                height: 120,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.photo, size: 40, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 8),
          Text(
            "2025.03.12",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const Divider(height: 24, color: Color(0xFFE5E5E5)),
        ],
      ),
    );
  }
}
