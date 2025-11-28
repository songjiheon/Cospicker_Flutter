import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class StayDatePeopleScreen extends StatefulWidget {
  const StayDatePeopleScreen({super.key});

  @override
  State<StayDatePeopleScreen> createState() => _StayDatePeopleScreenState();
}

class _StayDatePeopleScreenState extends State<StayDatePeopleScreen> {
  // 날짜 상태
  DateTime? checkIn;
  DateTime? checkOut;
  DateTime focusedDay = DateTime.now();

  // 인원 상태
  int adults = 2;
  int children = 1;

  // 초기화 함수
  void resetAll() {
    setState(() {
      checkIn = null;
      checkOut = null;
      adults = 2;
      children = 1;
    });
  }

  // 적용하기 → 이전 화면으로 값 전달
  void applySelection() {
    if (checkIn == null || checkOut == null) return;

    // 날짜 표시 형식
    String formattedDate =
        "${checkIn!.month}.${checkIn!.day} - ${checkOut!.month}.${checkOut!.day}";

    // 총 인원
    int totalPeople = adults + children;

    Navigator.pop(context, {"date": formattedDate, "people": totalPeople});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 닫기 버튼 + 제목
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 28),
                  ),
                  const Text(
                    "날짜 및 인원 선택",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 28), // 오른쪽 균형
                ],
              ),

              const SizedBox(height: 25),

              // 날짜 표시 바
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      (checkIn == null || checkOut == null)
                          ? "날짜를 선택하세요"
                          : "${checkIn!.month}.${checkIn!.day} - ${checkOut!.month}.${checkOut!.day}",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 캘린더 선택
              TableCalendar(
                focusedDay: focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),

                selectedDayPredicate: (day) =>
                    (checkIn != null &&
                    checkOut != null &&
                    day.isAfter(checkIn!.subtract(const Duration(days: 1))) &&
                    day.isBefore(checkOut!.add(const Duration(days: 1)))),

                rangeStartDay: checkIn,
                rangeEndDay: checkOut,

                onRangeSelected: (start, end, focused) {
                  setState(() {
                    checkIn = start;
                    checkOut = end;
                    focusedDay = focused;
                  });
                },

                onDaySelected: (selectedDay, focused) {
                  setState(() {
                    // checkIn 선택
                    if (checkIn == null ||
                        (checkIn != null && checkOut != null)) {
                      checkIn = selectedDay;
                      checkOut = null;
                    } else {
                      // checkOut 선택
                      if (selectedDay.isBefore(checkIn!)) {
                        checkOut = checkIn;
                        checkIn = selectedDay;
                      } else {
                        checkOut = selectedDay;
                      }
                    }
                    focusedDay = focused;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 선택 완료 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6EA8FE),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("선택 완료", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 35),

              // 인원 선택 제목
              Text(
                "인원 ${adults + children}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // 인원 선택 박스
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  children: [
                    // 인원 조절
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("인원 변경", style: TextStyle(fontSize: 16)),

                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (adults + children > 1) {
                                    adults = (adults + children == 1)
                                        ? adults
                                        : adults - 1;
                                  }
                                });
                              },
                            ),
                            Text(
                              "${adults + children}",
                              style: const TextStyle(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  adults++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 초기화 버튼
                    GestureDetector(
                      onTap: resetAll,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Icon(Icons.refresh, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "초기화",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 적용 버튼
              ElevatedButton(
                onPressed: applySelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6EA8FE),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("적용", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
