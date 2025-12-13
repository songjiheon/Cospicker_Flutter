# 환경 변수 설정 가이드

## .env 파일 생성

프로젝트 루트 디렉토리에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
# Google Maps API Key
GOOGLE_MAPS_API_KEY=AIzaSyADP6VfQKeMMJP1aDPpJAPBTczfFp5cMTc

# Korean Tourism API Service Key
TOUR_API_SERVICE_KEY=4e7c9d80475f8c84a482b22bc87a5c3376d82411b81a289fecdabaa83d75e26f
```

**참고**: `.env` 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다.
보안을 위해 실제 API 키를 직접 입력하세요.

## 주의사항

- `.env` 파일이 없어도 앱은 동작합니다 (fallback 값 사용)
- 프로덕션 배포 시에는 반드시 `.env` 파일을 생성하고 실제 API 키를 설정하세요

