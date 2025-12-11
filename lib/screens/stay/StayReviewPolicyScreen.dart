import 'package:flutter/material.dart';

class StayReviewPolicyScreen extends StatelessWidget {
  const StayReviewPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "후기 정책 화면",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 10),

            // ---------------- 제목 ----------------
            Text(
              "1. 후기의 작성",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Text(
              "1) 온라인 예약\n"
              " - COSPICKER 회원으로 앱, 웹(일부 카테고리) 내 온라인 예약 및 사용 완료한 경우에 후기를 작성할 수 있으며, 내점한 경우 후기 작성이 불가합니다.\n"
              " - 후기는 예약한 객실(숙박 시설, 숙소 등)에 한하며, 회사의 정책에 따라 변동될 수 있습니다.\n"
              " - 후기는 국내/해외 숙박/요 음식업(레스토랑, 카페 등)과 같은 제휴된 업체를 기준으로 14일 이내에만 작성할 수 있습니다.\n"
              "\n"
              "2) 무료 당첨권 등 무료 이벤트를 통하여 상품을 제공받은 경우 후기 작성이 불가합니다.\n"
              "\n"
              "3) 후기의 저작권은 이를 작성한 회원 본인에게 있습니다. 다만 회사는 게시 · 전송 · 공유 목적으로 회원이 작성한 게시물을 이용 · 편집 · 수정하여 이용할 수 있고 회사의 다른 서비스 또는 연동 채널 · 판매 채널에 이를 게재하거나 활용할 수 있습니다.\n"
              "\n"
              "4) 회원은 후기를 작성할 때 타인의 저작물 등 지식재산권을 포함하여 여타 권리를 침해하면 안 되며, 회사는 이에 대한 어떠한 법적·도덕적 책임을 부담하지 않습니다.\n",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            SizedBox(height: 20),

            Text(
              "2. 허위 후기 작성 금지",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Text(
              "1) 회사는 허위 후기 작성을 엄격히 금지합니다. 회사는 아래와 같은 경우 허위 후기로 판단하여 후기 삭제, 회원 자격 박탈 또는 사전 제재 등 조치를 취할 수 있습니다.\n"
              " - 실제 경험하지 않은 서비스 또는 상품에 대한 후기\n"
              " - 동일 IP 혹은 동일 단말기로 반복적으로 작성된 후기\n"
              " - 기타 부당한 수단을 통하여 부정한 목적으로 작성된 후기\n"
              "\n"
              "2) 전항에 따라 후기가 불리한 or 삭제 처리된 회원은 회사에 이의를 제기할 수 있습니다.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            SizedBox(height: 20),

            Text(
              "3. 후기의 수정",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Text(
              "회원 본인이 작성한 후기는 작성일 기준으로 48시간 이내에 수정이 가능합니다.\n"
              " - 리뷰 점수 포함 수정 가능하며, 사진의 경우 삭제만 가능합니다.\n"
              " - 48시간 이후 후기 수정, 삭제 요청은 불가합니다.\n",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            SizedBox(height: 20),

            Text(
              "4. 후기의 삭제",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Text(
              "법령에 반하는 후기의 경우 작성자 식별할 수 없어 후기 삭제가 불가합니다.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            SizedBox(height: 20),

            Text(
              "5. 후기의 비공개",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Text(
              "회사는 운영 정책에 따라 등록된 후기가 기준에 맞지 않을 경우 후기 페이지를 비공개 처리할 수 있습니다.\n",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            SizedBox(height: 20),

            Text(
              "6. 블라인드 정책",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Text(
              "법령 또는 회사의 정책에 어긋나는 후기는 사전 통보 없이 블라인드 처리될 수 있습니다.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
