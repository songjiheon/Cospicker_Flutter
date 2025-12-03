import 'package:cospicker/screens/chat/ChatRoomList.dart';
import 'package:cospicker/screens/community/CommunityMainScreen.dart';
import 'package:cospicker/screens/community/CommunityWriting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/splash/SplashScreen.dart';
import 'firebase_options.dart';

// Auth
import 'screens/auth/LoginScreen.dart';
import 'screens/auth/SignupScreen.dart';
import 'screens/auth/SignupComplete.dart';

// Home
import 'screens/home/HomeScreen.dart';

//near
import 'screens/near/NearMapScreen.dart';

// Profile
import 'screens/profile/ProfileScreen.dart';
import 'screens/profile/MyinfoScreen.dart';
import 'screens/profile/info/EditName.dart';
import 'screens/profile/info/EditPhoneNumber.dart';
import 'screens/profile/info/EditBirth.dart';
import 'screens/profile/info/EditGender.dart';
import 'screens/profile/info/EditPassword.dart';
import 'screens/profile/info/Notice.dart';

// Community
import 'screens/community/MyPost.dart';
import 'screens/community/MyComment.dart';

// Chat
import 'screens/chat/ChatRoom.dart';
import 'screens/chat/ChatRoomList.dart';

// Stay
import 'screens/stay/StaySearchScreen.dart';
import 'screens/stay/StayListScreen.dart';
import 'screens/stay/StayDetailScreen.dart';
import 'screens/stay/StayDatePeopleScreen.dart';
import 'screens/stay/StayReviewScreen.dart';
import 'screens/stay/StayRoomListScreen.dart';
import 'screens/stay/StayReviewPolicyScreen.dart';

import 'screens/stay/RestaurantListScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'COSPICKER',
      initialRoute: '/',
      routes: {
        //------------------------------------------------------------
        // 기본 화면
        //------------------------------------------------------------
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignupScreen(),
        '/signupsuccess': (context) => SignupCompleteScreen(),

        //------------------------------------------------------------
        // 프로필
        //------------------------------------------------------------
        '/profile': (context) => ProfileScreen(),
        '/myInfo': (context) => MyinfoScreen(),
        '/editName': (context) => EditNameScreen(),
        '/editGender': (context) => EditGenderScreen(),
        '/editPhone': (context) => EditPhoneScreen(),
        '/editBirth': (context) => EditBirthScreen(),
        '/editPassword': (context) => EditPasswordScreen(),
        '/notice': (context) => NoticeScreen(),
        '/myPost': (context) => MyPostsScreen(),
        '/myComment': (context) => MyCommentsScreen(),

        //------------------------------------------------------------
        // 커뮤니티
        //------------------------------------------------------------
        '/community': (context) => CommunityMainScreen(),
        '/communityWrite': (context) => CommunityWriteScreen(),

        //------------------------------------------------------------
        // 주변
        //------------------------------------------------------------

        //------------------------------------------------------------
        // 채팅
        //------------------------------------------------------------
        '/chatRoomList': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
          return ChatRoomListScreen(uid: uid);
        },
        '/chatRoom': (context) {
          final roomId = ModalRoute.of(context)!.settings.arguments as String;
          return ChatRoomScreen(roomId: roomId);
        },

        //맛집
        '/restaurantList': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<dynamic, dynamic>;

          return RestaurantListScreen(
            location: args["location"],
          );
        },

        //------------------------------------------------------------
        // 숙소 검색 / 리스트
        //------------------------------------------------------------
        '/stayDatePeople': (context) => const StayDatePeopleScreen(),

        '/stayList': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<dynamic, dynamic>;

          return StayListScreen(
            location: args["location"],
            date: args["date"],
            people: args["people"],
          );
        },

        //------------------------------------------------------------
        // 숙소 상세
        //------------------------------------------------------------
        '/stayDetail': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<dynamic, dynamic>;

          return StayDetailScreen(stayData: Map<String, dynamic>.from(args));
        },

        //------------------------------------------------------------
        // 리뷰 전체보기
        //------------------------------------------------------------
        '/stayReview': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<dynamic, dynamic>;

          return StayReviewScreen(
            stayName: args["stayName"],
            rating: args["rating"] * 1.0,
            reviewImages: List<String>.from(args["reviewImages"] ?? []),
          );
        },

        //------------------------------------------------------------
        // 리뷰 정책 화면 ⭐
        //------------------------------------------------------------
        '/stayReviewPolicy': (context) => const StayReviewPolicyScreen(),

        //------------------------------------------------------------
        // 모든 객실 보기
        //------------------------------------------------------------
        '/stayRooms': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<dynamic, dynamic>;

          return StayRoomListScreen(
            stayData: Map<String, dynamic>.from(args["stayData"]),
            date: args["date"],
            people: args["people"],
          );
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/near') {
          final type = settings.arguments as ContentType;   // ← arguments 받음

          return MaterialPageRoute(
            builder: (context) => NearMapScreen(type: type),
          );
        }if (settings.name == '/staySearch') {
          final type = settings.arguments as ContentType;

          return MaterialPageRoute(
            builder: (context) => StaySearchScreen(type: type),
          );
        }
        return null;
      },
    );
  }
}
