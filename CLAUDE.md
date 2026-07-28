## Frontend (feple-frontend)

- **프레임워크**: Flutter 3.x
- **상태관리**: Provider
- **네트워크**: Dio
- **인증**: Firebase Auth, 카카오 SDK
- **지도**: Google Maps

### 자주 쓰는 명령어
```bash
flutter pub get
flutter analyze --no-pub       # 에러 확인 (--no-pub로 pub get 생략, 반복 실행 시 더 빠름)
flutter run
flutter build appbundle --release  # Play Store 제출용 AAB 빌드
```

### 주요 패턴
- 댓글 목록은 `PostDetailNotifier`에서 `List<CommentDetail>`(`lib/model/comment_detail.dart`)로 관리
- 에러 메시지에 `e.toString()` 절대 사용 금지 → `debugPrint(e)` 로깅, 사용자에게는 i18n 키만 표시
- `FutureBuilder` 에러 표시 금지: `Text('Error: ${snapshot.error}')`, `.tr(args: [snapshot.error.toString()])` 모두 해당 → `SizedBox.shrink()` 또는 고정 i18n 키
- `CommentSection`에 스레드(루트/대댓글), 좋아요, 신고, 답글 기능 포함
- `RefreshIndicator.onRefresh`: 예외가 올라오면 크래시 → `setState(() { _future = _fetch(); }); try { await _future; } catch (_) {}` 패턴 사용 (arrow function은 Future를 반환해 setState 에러 발생)
- 폼 입력: `AppTextField(errorText: msg)` → 빨간 테두리 + 하단 에러 텍스트. 필드 검증 오류에 사용; 서버 인증 오류는 별도 `Text` 위젯으로 테두리 없이 표시
- 카카오 로그인 취소: `PlatformException(code: 'CANCELED')` → 에러 메시지 표시 금지, rethrow 후 상위에서 코드 체크
- 이메일 회원가입: 가입 후 즉시 로그인 아님 → 인증 이메일 발송 + Firebase signOut → `EmailNotVerifiedException` 로그인 시 발생
- 닉네임 입력: `NicknameField(key: GlobalKey<NicknameFieldState>())` → `.currentState?.currentNickname`, `.available`, `.lastCheckedNickname`, `.showError(msg)` 접근
- 위젯에서 `DioClient` 직접 사용 금지 (LoD) — 모든 HTTP 호출은 service 경유; 서비스에 없으면 메서드 추가
- `UserService` — 사용자 프로필/팔로우/찜 조회. 게시글·댓글·통계는 `UserActivityService`(`lib/service/user_activity_service.dart`) 사용
- `PostDetailNotifier` — 포스트·댓글·스크랩을 하나의 Notifier에서 관리하는 것은 의도적 (단일 화면 facade, 분리 시 3 notifier 조율 복잡도 증가). SRP 위반 아님
- `FestivalArtistsNotifier` — Festival artists + followedIds를 함께 관리 (followedIds가 정렬에 필요해 불가분). SRP 위반 아님
- `FestivalPosterNotifier` — 좋아요·설명 펼침·인증 상태를 함께 관리 (포스터 카드 단일 UI facade). SRP 위반 아님
- enum/모델/예외 클래스 분리: 서비스 파일에 정의 금지 → `lib/model/`(데이터 타입), `lib/common/exception/`(예외 클래스)로 분리; 기존 callers 대응은 service에서 `export` 사용
- `context.read<UserProvider>().user?.id` 체인 금지 → `UserProvider.currentUserId` getter 사용
- `RadioListTile` (Flutter 3.32+): `groupValue`/`onChanged` deprecated → `RadioGroup<T>`로 감싸고 파라미터 제거
- `*.g.dart`, `*.freezed.dart`는 freezed/json_serializable 생성 코드 — 수동 수정 금지, `analysis_options.yaml`에 분석 제외 처리됨
- TDA 적용 패턴: follow 토글처럼 상태에 따라 다른 서비스 호출이 필요한 경우 → `Notifier.toggle()`이 내부에서 판단, 위젯은 `toggle()` 호출만 (예: `ArtistFollowNotifier`)
- Feature 전용 `ChangeNotifier`는 해당 위젯 폴더 내 `*_notifier.dart`로 배치 (예: `artist_page/artist_follow_notifier.dart`)
- 여러 위젯/화면이 동일 엔드포인트를 각자 호출하면 service 추출 신호 — `SearchService`, `ArtistScheduleService` 등 신규 서비스 추가 후 `injection.dart`에 등록
- 상태 문자열 리터럴(`'APPROVED'`/`'PENDING'`) 여러 파일 반복 시 → `enum CertStatus` + 모델 클래스 도입, 서비스 반환 타입도 함께 교체 (예: `CertificationModel`)
- 동일 계산 로직이 두 위젯에 중복되면 `lib/model/`에 자유 함수 + data class로 추출 (예: `computeTimetableRange()` + `TimetableRange`)
- `catch (_) { rethrow }` 는 dead code — finally 블록으로 대체 (`try { ... } finally { ... }`)
- 포맷팅 코드가 3개 이상 파일에 인라인 반복되면 데이터 소유 클래스에 getter로 이동 (`TimetableEntry.timeRange`, `DateTime.toYMD`, `NotificationModel.formattedDate` 등)
- Notifier 단위 테스트: `mocktail` 사용; `sl<>` 의존성은 setUp에서 `sl.registerSingleton<T>(mock)`, tearDown에서 `sl.unregister<T>()`; 생성자 주입 notifier는 mock 직접 전달
- `HapticFeedback` 등 플랫폼 채널 호출하는 notifier 테스트: `main()` 첫 줄에 `TestWidgetsFlutterBinding.ensureInitialized()` 필요
- `try-finally` notifier는 예외가 caller로 propagate — 테스트에서 `await notifier.method()` 직접 호출 시 실패; `await expectLater(notifier.method(), throwsException)` 사용
- 위젯 파일에서 `AppColors.skyBlue` 직접 참조 금지 → `colors.activate` 사용; `AppColors.sunnyYellow` → `colors.accentColor` 사용 (그라디언트 배열·테마 정의 파일은 예외)
- submit 버튼: `ElevatedButton` 직접 사용 금지 → `LoadingButton(label, onPressed, isLoading, backgroundColor: colors.activate)` — `lib/common/widget/w_loading_button.dart`
- 바텀시트 드래그 핸들: `const BottomSheetHandle()` — `lib/common/widget/w_bottom_sheet_handle.dart`. `Container(width:40, height:4)` 직접 구현 금지
- 에러+재시도 UI: `ErrorState(message: ..., onRetry: ...)` — `lib/common/widget/w_error_state.dart`. Icon+Text+FilledButton 인라인 구현 금지
- 파괴적 확인 다이얼로그: `showConfirmDialog(context, title:, content:, confirmLabel:)` — `lib/common/util/confirm_dialog.dart`. AlertDialog 인라인 구현 금지
- S3 압축+업로드: `ImageUploadHelper.compressAndUpload(presignEndpoint, imageData)` 사용 — `lib/common/util/image_upload_helper.dart`. 서비스에서 직접 flutter_image_compress + http.put 구현 금지
- Duration 매직 넘버 금지: `AppDimens.animFast(200ms)/animQuick(250ms)/animNormal(300ms)/animSlow(350ms)/animVerySlow(500ms)/animSuccessDelay(700ms)/animRefresh(400ms)/animXFast(150ms)` 사용
- `Tap(onTap: () {})` 이중 래핑: 내부 빈 Tap이 외부 Tap 이벤트 전파를 차단하는 의도적 패턴 (예: 드로어 내부 클릭 시 드로어 닫힘 방지). dead code 아님
- `AbstractThemeColors` 새 getter 추가 시 위젯에서 실제 참조 여부 먼저 확인 (`grep -r "colors.newGetter" lib/`). 미사용 getter는 YAGNI
- `build()` 50줄 초과 시 private 헬퍼 메서드로 분리 (`_buildXxx(colors)` 패턴) — `ListenableBuilder` 내부도 동일 적용. Stack children에 spread로 삽입되는 헬퍼는 `List<Widget> _buildXxx(colors) => [...]` 반환 타입 사용
- CQS: service 명령 메서드는 `Future<void>` 반환. Notifier에서 상태를 먼저 뒤집고 API 호출 → 실패 시 이전 값으로 복원 (낙관적 업데이트)
- enum 표시 extension: `labelKey`·`displayColor(colors)` 등 UI 표시 로직은 `lib/screen/`의 `*_style.dart`에 extension으로 분리 (model 레이어에 flutter 의존성 금지)
- 외부 앱 async gap (OAuth/ImagePicker): 외부 앱을 여는 `await` 전에 Provider를 캡처할 것 (`final p = context.read<P>();`) — 복귀 시 `mounted`가 false일 수 있어 `context.read<>()` 불가. ImagePicker 후 `setState`도 `if (mounted)` 필요
- `DioClient` 인터셉터: per-request `Authorization` 헤더가 이미 있으면 JWT로 덮어쓰지 않음 (예: `/auth/kakao`에 카카오 토큰 전달 시 보존됨)

### i18n
다국어 문자열: `assets/translations/ko.json`, `assets/translations/en.json`
(`kr.json`은 빈 파일, 사용하지 않음 — 앱 locale: `ko`, `en`)
사용자 노출 에러는 반드시 i18n 키로 표시, raw exception/IP/포트 절대 노출 금지.

### 의존성 주입 (DI)
`lib/injection.dart`의 `sl` (GetIt 인스턴스)로 서비스 등록 및 조회.
- 사용: `sl<FestivalService>()`, `sl<ArtistService>()` 등
- 싱글톤 서비스(AuthService, FcmService)는 `.instance`와 `sl` 병행 사용
- `ServiceName()` 직접 생성자 절대 금지 — 싱글톤 보장이 깨지고 테스트 교체 불가

### 네트워크/인증 구조
`DioClient.dio` — JWT 자동 첨부 + 401 시 토큰 갱신 인터셉터 내장.
세션 만료 시 `DioClient.onSessionExpired` 콜백 호출 → 로그인 화면 이동.
토큰은 `TokenStore` (flutter_secure_storage)에 저장.
