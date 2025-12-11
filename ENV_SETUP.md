# 환경 변수 설정 가이드

## .env 파일 생성

프로젝트 루트 디렉토리에 `.env` 파일을 생성하고 다음 내용을 입력하세요:

```env
# Tour API Service Key
# 한국관광공사 Tour API 서비스 키를 입력하세요
SERVICE_KEY=4e7c9d80475f8c84a482b22bc87a5c3376d82411b81a289fecdabaa83d75e26f

# Mobile OS (기본값: ETC)
MOBILE_OS=ETC

# Mobile App Name (기본값: Cospicker)
MOBILE_APP=Cospicker
```

## 중요 사항

1. `.env` 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다.
2. 실제 서비스 키는 보안을 위해 별도로 관리하세요.
3. `.env.example` 파일은 템플릿으로 참고용입니다.

## 확인

앱 실행 시 환경 변수가 제대로 로드되었는지 확인하려면:

```dart
import 'package:cospicker/core/utils/env_util.dart';

// 환경 변수 로드 확인
if (EnvUtil.isEnvLoaded()) {
  print('환경 변수 로드 완료');
}
```

