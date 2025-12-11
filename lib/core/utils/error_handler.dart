import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cospicker/core/utils/logger_util.dart';

/// 에러 핸들링 유틸리티 클래스
class ErrorHandler {
  /// Firebase Auth 에러 메시지 변환
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '사용자를 찾을 수 없습니다.';
      case 'wrong-password':
        return '비밀번호가 잘못되었습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일입니다.';
      case 'user-disabled':
        return '비활성화된 사용자입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '허용되지 않은 작업입니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return '인증 오류가 발생했습니다: ${e.message ?? e.code}';
    }
  }

  /// Firestore 에러 메시지 변환
  static String _getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return '권한이 거부되었습니다.';
      case 'not-found':
        return '데이터를 찾을 수 없습니다.';
      case 'unavailable':
        return '서비스를 사용할 수 없습니다.';
      case 'deadline-exceeded':
        return '요청 시간이 초과되었습니다.';
      default:
        return '데이터베이스 오류가 발생했습니다: ${e.message ?? e.code}';
    }
  }

  /// 네트워크 에러 메시지 변환
  static String _getNetworkErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return '네트워크 연결을 확인해주세요.';
    }
    if (error.toString().contains('TimeoutException')) {
      return '요청 시간이 초과되었습니다.';
    }
    return '네트워크 오류가 발생했습니다.';
  }

  /// 위치 권한 에러 메시지 변환
  static String _getLocationErrorMessage(dynamic error) {
    if (error.toString().contains('permission')) {
      return '위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
    }
    return '위치 정보를 가져올 수 없습니다.';
  }

  /// 에러를 사용자 친화적인 메시지로 변환
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error);
    } else if (error.toString().contains('network') ||
        error.toString().contains('Socket') ||
        error.toString().contains('Timeout')) {
      return _getNetworkErrorMessage(error);
    } else if (error.toString().contains('location') ||
        error.toString().contains('permission')) {
      return _getLocationErrorMessage(error);
    }
    return '알 수 없는 오류가 발생했습니다.';
  }

  /// 에러를 로깅하고 사용자에게 SnackBar 표시
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    final message = customMessage ?? getErrorMessage(error);
    
    // 에러 로깅
    AppLogger.e('Error occurred', error);
    
    // 사용자에게 메시지 표시
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: onRetry != null
              ? SnackBarAction(
                  label: '다시 시도',
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    }
  }

  /// 에러를 로깅만 하고 사용자에게는 표시하지 않음
  static void logError(dynamic error, {String? context}) {
    if (context != null) {
      AppLogger.e('Error in $context', error);
    } else {
      AppLogger.e('Error occurred', error);
    }
  }
}

