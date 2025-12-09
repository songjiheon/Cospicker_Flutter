import 'package:cospicker/screens/chat/ChatRoomList.dart';
import 'package:cospicker/screens/community/CommunityMainScreen.dart';
import 'package:cospicker/screens/community/CommunityWriting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cospicker/models/content_type.dart';   // ⭐ 공통 enum

import 'screens/splash/SplashScreen.dart';
import 'firebase_options.dart';

// Auth
import 'screens/auth/LoginScreen.dart';
import 'screens/auth/SignupScreen.dart';
import 'screens/auth/SignupComplete.dart';

// Home
import 'screens/home/HomeScreen.dart';

// near
import 'screens/near/NearMapScreen.dart';   // ✔ enum 정의 제거했으면 이 import는 정상

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

// WishList
import 'screens/wish/WishListScreen.dart';
import 'screens/wish/WishFolderDetailScreen.dart';

// Stay
import 'screens/stay/StaySearchScreen.dart';
import 'screens/stay/StayListScreen.dart';
import 'screens/stay/StayDetailScreen.dart';
import 'screens/stay/StayDatePeopleScreen.dart';
import 'screens/stay/StayReviewScreen.dart';
import 'screens/stay/StayRoomListScreen.dart';
import 'screens/stay/StayReviewPolicyScreen.dart';

// Restaurant
import 'screens/restaurant/RestaurantListScreen.dart';
import 'screens/restaurant/RestaurantDetailScreen.dart';
import 'screens/restaurant/RestaurantReviewScreen.dart';
import 'screens/restaurant/RestaurantSearchScreen.dart';
import 'screens/restaurant/RestaurantMapScreen.dart';

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
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignupScreen(),
        '/signupsuccess': (context) => SignupCompleteScreen(),

        // Profile
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

        // Community
        '/community': (context) => CommunityMainScreen(),
        '/communityWrite': (context) => CommunityWriteScreen(),

        // Wishlist
        '/wishList': (context) => WishListScreen(),
        '/wishFolderDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return WishFolderDetailScreen(
            uid: args["uid"],
            collectionName: args["collectionName"],
            folderId: args["folderId"],
            folderName: args["folderName"],
          );
        },

        // Chat
        '/chatRoomList': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
          return ChatRoomListScreen(uid: uid);
        },
        '/chatRoom': (context) {
          final roomId = ModalRoute.of(context)!.settings.arguments as String;
          return ChatRoomScreen(roomId: roomId);
        },

        // Restaurant
        '/restaurantSearch': (context) => const RestaurantSearchScreen(),
        '/restaurantList': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return RestaurantListScreen(location: args["location"]);
        },
        '/restaurantDetail': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RestaurantDetailScreen(restaurantData: args);
        },
        '/restaurantMap': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RestaurantMapScreen(
            lat: args["lat"],
            lng: args["lng"],
            title: args["title"],
          );
        },

        '/restaurantReview': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RestaurantReviewScreen(
            contentid: args["contentid"],
            title: args["title"],
          );
        },

        // Stay
        '/stayDatePeople': (context) => const StayDatePeopleScreen(),
        '/stayList': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StayListScreen(
            location: args["location"],
            date: args["date"],
            people: args["people"],
          );
        },
        '/stayDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StayDetailScreen(stayData: Map<String, dynamic>.from(args));
        },
        '/stayReview': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StayReviewScreen(
            stayName: args["stayName"],
            rating: args["rating"] * 1.0,
            reviewImages: List<String>.from(args["reviewImages"] ?? []),
          );
        },
        '/stayReviewPolicy': (context) => const StayReviewPolicyScreen(),
        '/stayRooms': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StayRoomListScreen(
            stayData: Map<String, dynamic>.from(args["stayData"]),
            date: args["date"],
            people: args["people"],
          );
        },
      },

      // ⭐ onGenerateRoute
        onGenerateRoute: (settings) {
          if (settings.name == '/near') {
            final arg = settings.arguments;
            final type = (arg is ContentType)
                ? arg
                : ContentType.accommodation;

            return MaterialPageRoute(
              builder: (_) => NearMapScreen(type: type),
            );
          }

          if (settings.name == '/staySearch') {
            final arg = settings.arguments;
            final type = (arg is ContentType)
                ? arg
                : ContentType.accommodation;

            return MaterialPageRoute(
              builder: (_) => StaySearchScreen(type: type),
            );
          }

          return null;
        }

    );
  }
}
