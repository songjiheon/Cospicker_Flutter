📱 Cospicker
---------
여행 숙소, 맛집, 일정, 커뮤니티 기능을 한곳에 모은
통합 여행 플랫폼 애플리케이션

🌍 프로젝트 소개
------
Cospicker는 사용자들이 여행 정보를 쉽게 검색하고,
다른 사용자들과 경험을 공유할 수 있도록 설계된 앱입니다.

숙소 · 맛집 검색

커뮤니티 기반 정보 공유

여행 플래너처럼 활용 가능

Firebase 기반 사용자 인증 및 데이터 관리



초기 버전은 Android Native (Kotlin) 로 개발되었으며,
확장성과 유지보수 효율성 향상을 위해
Flutter 기반으로 리빌딩(Migration) 되었습니다.

💡 현재 제출 및 배포 버전은 Flutter + Firebase 기반 최신 버전입니다.

👥 멤버 구성 및 역할 
--------------
▪ 프론트엔드

팀장 : 김선욱

팀원 : 권오현

▪ 백엔드

팀원 : 최동렬

팀원 : 송지헌



🛠 개발 환경
--------------

백엔드 : FireBase  
개발 환경 : Dart  
IDE : Android Studio  
빌드 시스템 : Gradle  
협업 및 배포 : GitHub  


📂 Cospicker 프로젝트 구조 (Flutter 버전)
--------------------
lib  
│
├── main.dart                         // 앱 진입점  
├── app.dart                          // 전체 앱 설정 (Theme, Route 설정)  
│
├── config                            // 전역 설정 및 공통 상수  
│   ├── app_colors.dart               // 색상 테마  
│   ├── app_fonts.dart                // 폰트 스타일  
│   └── app_routes.dart               // 라우팅/네비게이션 설정  
│
├── models                            // 데이터 모델  
│   ├── user_model.dart               // 사용자 데이터  
│   ├── post_model.dart               // 커뮤니티 게시글  
│   ├── comment_model.dart            // 댓글  
│   ├── stay_model.dart               // 숙소 데이터  
│   └── notification_model.dart       // 알림 모델  
│
├── services                          // Firebase 및 Api 모듈  
│   ├── auth_service.dart             // Firebase Auth / 로그인, 회원가입  
│   ├── firestore_service.dart        // Firestore CRUD 처리  
│   ├── storage_service.dart          // Firebase Storage (이미지 업로드)  
│   └── notification_service.dart     // 알림 관련 기능  
│
├── providers                         // 상태관리 (Provider/Riverpod 사용 시)  
│   ├── user_provider.dart
│   ├── community_provider.dart  
│   ├── stay_provider.dart  
│   └── notification_provider.dart  
│
├── widgets                           // 재사용 가능한 UI 컴포넌트  
│   ├── custom_button.dart            // 공통 버튼  
│   ├── custom_textfield.dart         // 텍스트 입력 박스  
│   ├── post_card.dart                // 게시글 UI 컴포넌트  
│   ├── stay_card.dart                // 숙소 카드 UI  
│   └── loading_indicator.dart        // 로딩 위젯  
│
└── screens
    ├── auth                          // 로그인/회원가입 화면  
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   └── profile_register_screen.dart
    │
    ├── home                          // 홈 + 하단 네비게이션  
    │   ├── home_screen.dart
    │   └── bottom_nav.dart
    │
    ├── community                     // 커뮤니티 기능  
    │   ├── community_screen.dart  
    │   ├── post_write_screen.dart  
    │   ├── post_detail_screen.dart  
    │   └── community_search_screen.dart  
    │
    ├── chat                          // 1:1 채팅 (구현 여부에 따라)  
    │   ├── chat_list_screen.dart  
    │   └── chat_room_screen.dart  
    │
    ├── stay                          // 숙소 검색/추천 기능  
    │   ├── stay_search_screen.dart  
    │   ├── stay_list_screen.dart  
    │   └── stay_detail_screen.dart  
    │
    ├── myinfo                        // 마이페이지  
    │   ├── myinfo_screen.dart  
    │   ├── my_posts_screen.dart  
    │   ├── my_comments_screen.dart  
    │   └── settings_screen.dart  
    │
    └── splash
        └── splash_screen.dart        // 앱 첫 로딩 화면  

-----------------------

🚀 실행 방법
-------------
flutter pub get
flutter run

📎 저장소 구조
----------------
Repo	설명  
  
🔹 https://github.com/cdr051/AndroidProgramming  
	Kotlin 기반 초기 개발 버전  
    
🔹 https://github.com/songjiheon/Cospicker_Flutter  
	최종 제출용 Flutter 버전  



🏁 마무리
----------------
본 프로젝트는 사용자 편의성과 확장성을 기반으로  
여행 플랫폼 서비스를 모바일 환경에서 구현한 결과물입니다.  
향후 추천 알고리즘, 지역 기반 서비스, 여행 일정 자동 생성 기능을 목표로 확장 가능합니다.  

