import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cospicker/core/utils/logger_util.dart';

/// 환경 변수 유틸리티 클래스
class EnvUtil {
  /// Tour API Service Key 가져오기
  static String getServiceKey() {
    final key = dotenv.env['SERVICE_KEY'];
    if (key == null || key.isEmpty) {
      AppLogger.e('SERVICE_KEY가 .env 파일에 설정되지 않았습니다.');
      throw Exception('SERVICE_KEY is not set in .env file');
    }
    return key;
  }

  /// Mobile OS 가져오기 (기본값: ETC)
  static String getMobileOS() {
    return dotenv.env['MOBILE_OS'] ?? 'ETC';
  }

  /// Mobile App Name 가져오기 (기본값: Cospicker)
  static String getMobileApp() {
    return dotenv.env['MOBILE_APP'] ?? 'Cospicker';
  }

  /// 환경 변수 로드 확인
  static bool isEnvLoaded() {
    try {
      return dotenv.env['SERVICE_KEY'] != null;
    } catch (e) {
      return false;
    }
  }
}

