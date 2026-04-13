# FEPLE Frontend

페스티벌을 좋아하는 사람들의 커뮤니티 앱 **FEPLE**의 Flutter 클라이언트입니다.

## 주요 기능

- **페스티벌 탐색** - 페스티벌 목록 조회, 장르/지역 필터링, 상세 정보 확인
- **아티스트** - 아티스트 검색, 팔로우, 일정 확인, 사진 갤러리
- **커뮤니티** - 게시판 글쓰기/댓글, 좋아요
- **타임테이블** - 페스티벌 공연 시간표 조회
- **마이페이지** - 프로필 편집, 팔로우 아티스트 관리

## 기술 스택

- **Flutter** 3.x (Android / iOS / Web / macOS)
- **상태관리**: Provider, GetX
- **네트워크**: Dio, Retrofit
- **인증**: Firebase Auth, Kakao SDK
- **지도**: Google Maps
- **이미지**: CachedNetworkImage, Flutter Image Compress
- **다국어**: Easy Localization

## 프로젝트 구조

```
lib/
├── auth/           # 인증 (Firebase, Kakao)
├── common/         # 테마, 상수, 공통 위젯
├── model/          # 데이터 모델
├── network/        # API 클라이언트 (Dio)
├── provider/       # 상태 관리
└── screen/
    └── main/tab/
        ├── home/               # 홈
        ├── concert_list/       # 페스티벌 목록
        ├── search/             # 아티스트 검색 & 페스티벌 상세
        ├── community_board/    # 커뮤니티 게시판
        └── my_page/            # 마이페이지
```

## 설정

### 환경 설정

1. `web/index.html`의 Google Maps API 키를 로컬에서 직접 입력
2. `lib/auth/secrets.json`에 인증 관련 설정 추가
3. Firebase 설정 파일 (`GoogleService-Info.plist`, `google-services.json`) 배치

### 실행

```bash
flutter pub get
flutter run
```

## 백엔드

백엔드 레포지토리: [feple-backend](https://github.com/yangjaehoon/feple-backend)
