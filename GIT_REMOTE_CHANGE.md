# Git 원격 저장소 변경 방법

## 현재 상태
- 원격 저장소: `https://github.com/songjiheon/Cospicker_Flutter.git`

## 변경 방법

### 1단계: 기존 원격 저장소 제거
```bash
git remote remove origin
```

### 2단계: 새로운 원격 저장소 추가
```bash
git remote add origin <팀원의_GitHub_저장소_URL>
```

예시:
```bash
git remote add origin https://github.com/팀원아이디/저장소이름.git
```

### 3단계: 확인
```bash
git remote -v
```

### 4단계: (선택사항) 첫 푸시
```bash
git push -u origin master
```

## 주의사항
- 팀원의 저장소에 접근 권한이 있어야 합니다
- 저장소 URL은 HTTPS 또는 SSH 형식 모두 가능합니다
- SSH 사용 시: `git@github.com:username/repository.git`

