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

팀장 : 김선욱 - Figma UI 설계

팀원 : 권오현 - Figma UI 설계 , 전체적인 UI 개발

▪ 백엔드

팀원 : 최동렬

팀원 : 송지헌 - 서버 구축, API 연동



🛠 개발 환경
--------------

백엔드 : FireBase  
개발 환경 : Dart  
IDE : Android Studio  
빌드 시스템 : Gradle  
협업 및 배포 : GitHub  



<strong>📂 Cospicker 프로젝트 구조 (Flutter 버전)</strong>  


```plaintext
lib/
├── main.dart
├── firebase_options.dart
│
├── models/
│   └── content_type.dart
│
├── screens/
│   ├── auth/
│   │   ├── LoginScreen.dart
│   │   ├── SignupScreen.dart
│   │   └── SignupComplete.dart
│   │
│   ├── chat/
│ 성
# Tour API 서비스 키 (필수)
# 한국관광공사 Tour API에서 발급받은 서비스 키를 입력하세요
SERVICE_KEY=c1ba3895a88789bffa372adbfd93402f24d87f2806bd7381438667920a297936

# 모바일 OS (선택사항, 기본값: ETC)
MOBILE_OS=ETC

# 모바일 앱 이름 (선택사항, 기본값: Cospicker)
MOBILE_APP=Cospicker

🚀 실행 방법
-------------
```plaintext
flutter pub get  
flutter run
```
📎 저장소 구조
----------------
Repo	설명  
  
🔹 https://github.com/cdr051/AndroidProgramming  
	Kotlin 기반 초기 개발 버전  
    
🔹 https://github.com/songjiheon/Cospicker_Flutter  
	최종 제출용 Flutter 버전  

-----------------  
🔹 https://console.firebase.google.com/project/travel-planner-app-e6167/overview?hl=ko&fb_gclid=Cj0KCQiAi9rJBhCYARIsALyPDts3UZX0kWVXE1WeBnU0TI44YW5LwZOjjcxTKmWQMrB8KCK6HigV72QaAsIOEALw_wcB  
	firebase 주소  


🏁 마무리
----------------
본 프로젝트는 사용자 편의성과 확장성을 기반으로  
여행 플랫폼 서비스를 모바일 환경에서 구현한 결과물입니다.  
향후 추천 알고리즘, 지역 기반 서비스, 여행 일정 자동 생성 기능을 목표로 확장 가능합니다.  

