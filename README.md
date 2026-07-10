# FEPLE Frontend

페스티벌을 좋아하는 사람들의 커뮤니티 앱 **FEPLE**의 Flutter 클라이언트입니다.

## 주요 기능

- **페스티벌 탐색** — 목록 조회, 장르·지역 필터링, 상세 정보, 좋아요, 공기질(AQI)·날씨 확인, 평점·리뷰
- **타임테이블** — 공연 시간표 조회 및 스테이지별 일정 확인
- **부스 맵** — 페스티벌 부스 위치 및 카테고리 안내
- **아티스트** — 검색, 팔로우, 공연 일정, 노래 목록(YouTube Music 연결), 사진 갤러리
- **커뮤니티 게시판** — Hot / 자유 / 동행 구하기 게시판, 아티스트·페스티벌 전용 게시판
  - 무한 스크롤 페이지네이션
  - 대댓글(스레드) 지원
  - 좋아요, 스크랩, 신고, 사용자 차단
- **검색** — 아티스트·페스티벌·게시글 통합 검색 (자동완성)
- **페스티벌 인증** — 현장 사진 제출 → 관리자 승인 → 인증 배지 획득
- **노래 요청** — 아티스트 페이지에서 곡 추가 요청, 요청 내역 조회
- **알림** — FCM 푸시 알림, 인앱 알림 목록, 알림별 수신 설정, 전체 읽음 처리
- **마이페이지** — 프로필·닉네임 편집, 팔로우 아티스트, 찜한 페스티벌, 스크랩·작성 글·좋아요한 글·댓글 조회, 인증 내역
- **설정** — 알림 설정, 차단 사용자 관리, 오픈소스 라이선스, 앱 리뷰 유도
- **온보딩** — 최초 실행 시 앱 소개
- **오프라인 대응** — 네트워크 끊김 배너, API 응답 캐시·프리페치
- **다국어** — 한국어 / 영어 지원

## 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.x (Android / iOS) |
| 상태관리 | Provider |
| 네트워크 | Dio (JWT 자동 첨부 + 401 토큰 갱신 인터셉터), Connectivity Plus |
| 인증 | Firebase Auth, Kakao SDK, Sign in with Apple |
| 지도 | Google Maps, Geolocator |
| 푸시 알림 | Firebase Messaging, Flutter Local Notifications |
| 모니터링 | Firebase Crashlytics, Firebase Performance |
| 스토리지 | flutter_secure_storage (토큰), SharedPreferences |
| 이미지 | CachedNetworkImage, Flutter Image Compress, Image Picker |
| 다국어 | Easy Localization |
| DI | GetIt |
| 코드 생성 | Freezed, JSON Serializable, Retrofit Generator |

## 프로젝트 구조

```
lib/
├── auth/                      # TokenStore, 인증 키/시크릿
├── login/                     # 로그인·회원가입·비밀번호 찾기·이메일 인증 화면
├── network/                   # DioClient, API 캐시 스토어, 성능 인터셉터
├── common/
│   ├── theme/                    # AppColors, ThemeColors
│   ├── widget/                    # 공통 위젯 (LoadingButton, ErrorState, BottomSheetHandle 등)
│   ├── util/                      # AppRoute, ConfirmDialog, ImageUploadHelper 등
│   ├── data/preference/           # 로컬 프리퍼런스 저장
│   └── exception/                 # 커스텀 예외 클래스
├── injection.dart             # GetIt DI 등록
├── model/                      # 데이터 모델 (CommentDetail, CertificationModel, FestivalReview 등)
├── provider/                   # 전역 Provider (UserProvider, FestivalPreviewProvider)
├── service/                    # API 서비스 계층
│   ├── artist_service.dart / artist_follow_service.dart / artist_schedule_service.dart / artist_photo_service.dart
│   ├── auth_service.dart / fcm_service.dart / fcm_token_service.dart
│   ├── certification_service.dart
│   ├── comment_service.dart / post_service.dart / report_service.dart / block_service.dart / scrap_service.dart
│   ├── festival_service.dart / festival_detail_service.dart / festival_interaction_service.dart / festival_cache_service.dart
│   ├── notification_service.dart / notification_preference_service.dart
│   ├── search_service.dart
│   ├── song_service.dart / song_request_service.dart
│   ├── user_service.dart / user_activity_service.dart
│   ├── app_review_service.dart / cache_prefetch_service.dart
│   └── ...
└── screen/
    ├── main/tab/
    │   ├── home/                  # 홈 (즐겨찾기 게시판, 팔로우 아티스트, 추천 페스티벌)
    │   ├── festival_list/         # 페스티벌 목록·상세·타임테이블·부스 맵
    │   ├── community_board/       # 커뮤니티 게시판·게시글 상세·댓글
    │   ├── search/                # 통합 검색
    │   └── my_page/               # 마이페이지 (프로필, 인증, 스크랩, 노래 요청 등)
    ├── notification/              # 알림 목록
    ├── settings/                  # 알림 설정, 차단 사용자 관리
    ├── opensource/                 # 오픈소스 라이선스
    └── onboarding/                 # 온보딩
```

## 설정

### 필수 파일 (git 미추적)

| 파일 | 용도 |
|------|------|
| `android/app/google-services.json` | Firebase Android 설정 |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS 설정 |
| `lib/auth/secrets.json` | Kakao REST API 키 등 |

`web/index.html` 내 Google Maps API 키도 로컬에서 직접 입력합니다.

### 실행

```bash
flutter pub get
flutter analyze         # 정적 분석
flutter run             # 개발 실행

# 배포 빌드
flutter build appbundle --release   # Play Store (AAB)
flutter build ipa --release         # App Store
```

## 백엔드

백엔드 레포지토리: [feple-backend](https://github.com/yangjaehoon/feple-backend)
