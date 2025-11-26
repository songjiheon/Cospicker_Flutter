import 'package:cospicker/screens/chat/ChatRoomList.dart';
import 'package:cospicker/screens/community/CommunityMainScreen.dart';
import 'package:cospicker/screens/community/CommunityWriting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash/SplashScreen.dart';
import 'firebase_options.dart';
import 'screens/auth/LoginScreen.dart';
import 'screens/auth/SignupScreen.dart';
import 'screens/auth/SignupComplete.dart';

import 'screens/home/HomeScreen.dart';

import 'screens/profile/ProfileScreen.dart';
import '/screens/profile/MyinfoScreen.dart';
import '/screens/profile/info/EditName.dart';
import '/screens/profile/info/EditPhoneNumber.dart';
import '/screens/profile/info/EditBirth.dart';
import '/screens/profile/info/EditGender.dart';
import '/screens/profile/info/EditPassword.dart';
import '/screens/profile/info/Notice.dart';

import '/screens/Community/MyPost.dart';
import '/screens/Community/MyComment.dart';
import '/screens/community/CommunityMainScreen.dart';
import '/screens/community/CommunityWriting.dart';

import '/screens/chat/ChatRoom.dart';
import '/screens/chat/ChatRoomList.dart';






Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COSPICKER',
        initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignupScreen(),
        '/signupsuccess': (context) => SignupCompleteScreen(),
        '/profile' : (context) => ProfileScreen(),
        '/myInfo' :(context) => MyinfoScreen(),
        '/editName': (context) => EditNameScreen (),
        '/editGender':(context)=>EditGenderScreen(),
        '/editPhone' : (context) => EditPhoneScreen(),
        '/editBirth' : (context) => EditBirthScreen(),
        '/editPassword' : (context) => EditPasswordScreen(),
        '/community' : (context) => CommunityMainScreen(),
        '/communityWrite': (context) => CommunityWriteScreen(),
        '/notice' : (context) => NoticeScreen(),
        '/myPost' : (context) => MyPostsScreen(),
        '/myComment' : (context) => MyCommentsScreen(),
        '/chatRoomList': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
          return ChatRoomListScreen(uid: uid);
        },
        '/chatRoom': (context) {
          final roomId = ModalRoute.of(context)!.settings.arguments as String;
          return ChatRoomScreen(roomId: roomId);
        },
      },
    );
  }
}
