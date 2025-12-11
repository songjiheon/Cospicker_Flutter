/// 애플리케이션 전역 상수 정의
class AppConstants {
  // API 관련
  static const String tourApiBaseUrl = "https://apis.data.go.kr/B551011/KorService2";
  static const String tourApiEndpoint = "/locationBasedList2";
  
  // 기본값
  static const int defaultPeople = 2;
  static const int defaultRadius = 3000;
  static const int defaultNumOfRows = 20;
  static const int maxRecentItems = 10;
  static const double defaultRating = 3.0;
  
  // Content Type IDs
  static const int contentTypeAccommodation = 32;
  static const int contentTypeRestaurant = 39;
  
  // Mobile Info
  static const String defaultMobileOS = "ETC";
  static const String defaultMobileApp = "Cospicker";
  
  // Firestore Collections
  static const String collectionTourItems = "tourItems";
  static const String collectionRestaurantItems = "restaurantItems";
  static const String collectionUsers = "users";
  static const String collectionRecentStays = "recentStays";
  static const String collectionRecentRestaurants = "recentRestaurants";
  static const String collectionChatRooms = "chatRooms";
  
  // Private constructor to prevent instantiation
  AppConstants._();
}

