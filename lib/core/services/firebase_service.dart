import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cospicker/core/constants/app_constants.dart';
import 'package:cospicker/core/utils/logger_util.dart';
import 'package:cospicker/core/utils/error_handler.dart';

/// Firebase 관련 공통 서비스 클래스
/// 
/// Firebase 호출 로직을 중앙화하여 코드 중복을 제거합니다.
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================
  // User 관련 메서드
  // ============================================

  /// 현재 사용자 정보 가져오기
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 사용자 UID 가져오기
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// 사용자 데이터 가져오기
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      ErrorHandler.logError(e, context: '사용자 데이터 가져오기');
      return null;
    }
  }

  /// 사용자 데이터 업데이트
  static Future<bool> updateUserData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .update(data);
      return true;
    } catch (e) {
      ErrorHandler.logError(e, context: '사용자 데이터 업데이트');
      return false;
    }
  }

  // ============================================
  // 최근 본 항목 관련 메서드
  // ============================================

  /// 최근 본 항목 저장 (숙소/맛집 공통)
  static Future<void> saveRecentItem({
    required String collection, // "recentStays" or "recentRestaurants"
    required String contentId,
    int maxItems = 10,
  }) async {
    final user = getCurrentUser();
    if (user == null) {
      AppLogger.w('사용자가 로그인하지 않았습니다.');
      return;
    }

    try {
      final docRef = _firestore.collection(collection).doc(user.uid);
      final docSnap = await docRef.get();

      List<String> list = [];
      if (docSnap.exists && docSnap.data()!.containsKey("contentIds")) {
        list = List<String>.from(docSnap["contentIds"]);
      }

      list.remove(contentId);
      list.insert(0, contentId);

      if (list.length > maxItems) {
        list = list.sublist(0, maxItems);
      }

      if (docSnap.exists) {
        await docRef.update({"contentIds": list});
      } else {
        await docRef.set({"contentIds": list});
      }
    } catch (e) {
      ErrorHandler.logError(e, context: '최근 본 항목 저장');
    }
  }

  /// 최근 본 항목 목록 가져오기
  static Future<List<String>> getRecentItemIds(String collection) async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final doc = await _firestore.collection(collection).doc(user.uid).get();

      if (!doc.exists || !doc.data()!.containsKey("contentIds")) {
        return [];
      }

      return List<String>.from(doc["contentIds"]);
    } catch (e) {
      ErrorHandler.logError(e, context: '최근 본 항목 목록 가져오기');
      return [];
    }
  }

  /// 최근 본 항목 상세 데이터 가져오기
  static Future<List<Map<String, dynamic>>> getRecentItems({
    required String recentCollection, // "recentStays" or "recentRestaurants"
    required String itemCollection, // "tourItems" or "restaurantItems"
  }) async {
    final contentIds = await getRecentItemIds(recentCollection);
    if (contentIds.isEmpty) return [];

    try {
      final futures = contentIds.map((id) async {
        final doc = await _firestore.collection(itemCollection).doc(id).get();
        if (doc.exists && doc.data() != null) {
          return doc.data() as Map<String, dynamic>;
        }
        return null;
      });

      final results = await Future.wait(futures);
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      ErrorHandler.logError(e, context: '최근 본 항목 상세 데이터 가져오기');
      return [];
    }
  }

  // ============================================
  // Tour Items 관련 메서드
  // ============================================

  /// Tour Item 가져오기
  static Future<Map<String, dynamic>?> getTourItem(String contentId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionTourItems)
          .doc(contentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      ErrorHandler.logError(e, context: 'Tour Item 가져오기');
      return null;
    }
  }

  /// Restaurant Item 가져오기
  static Future<Map<String, dynamic>?> getRestaurantItem(
      String contentId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionRestaurantItems)
          .doc(contentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      ErrorHandler.logError(e, context: 'Restaurant Item 가져오기');
      return null;
    }
  }

  // ============================================
  // Batch 작업
  // ============================================

  /// Batch 작업으로 여러 문서 저장
  static Future<void> batchSetDocuments({
    required String collection,
    required Map<String, Map<String, dynamic>> documents,
  }) async {
    try {
      final batch = _firestore.batch();

      documents.forEach((docId, data) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.set(docRef, data);
      });

      await batch.commit();
      AppLogger.d('Batch 저장 완료: ${documents.length}개 문서');
    } catch (e) {
      ErrorHandler.logError(e, context: 'Batch 저장');
    }
  }

  /// Batch 작업으로 여러 문서 업데이트
  static Future<void> batchUpdateDocuments({
    required String collection,
    required Map<String, Map<String, dynamic>> documents,
  }) async {
    try {
      final batch = _firestore.batch();

      documents.forEach((docId, data) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.update(docRef, data);
      });

      await batch.commit();
      AppLogger.d('Batch 업데이트 완료: ${documents.length}개 문서');
    } catch (e) {
      ErrorHandler.logError(e, context: 'Batch 업데이트');
    }
  }
}

