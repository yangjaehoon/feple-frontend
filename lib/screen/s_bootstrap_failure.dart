import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// 앱 초기화가 실패했을 때만 뜨는 최소 안내 화면. 예전에는 이 경우 네이티브
/// 런치 화면에 그대로 갇혔다.
///
/// 테마·Provider·번역 무엇에도 기대지 않는다 — 초기화가 실패했다는 건 그것들이
/// 준비되지 않았을 수 있다는 뜻이다. 그래서 문구도 `.tr()` 대신 플랫폼 로케일만
/// 보고 고른다(`EasyLocalization` 자체가 실패했으면 `.tr()`은 원본 키를 낸다).
/// 이 파일이 프로젝트 i18n 규칙에서 벗어나는 유일한 곳이다.
///
/// **재시도 버튼은 일부러 두지 않았다.** `main.dart`의 부트스트랩은 한 번만
/// 실행할 수 있다 — `setupDependencies()`는 GetIt에 같은 타입을 다시 등록하면
/// 던지고, `AppPreferences._prefs`는 `late final`이라 두 번째 대입에서 던진다.
/// 즉 눌러도 항상 실패하는 버튼이 되므로, 앱을 완전히 종료 후 재실행하라고
/// 안내하는 편이 정직하다.
class BootstrapFailureApp extends StatefulWidget {
  const BootstrapFailureApp({super.key});

  @override
  State<BootstrapFailureApp> createState() => _BootstrapFailureAppState();
}

class _BootstrapFailureAppState extends State<BootstrapFailureApp> {
  @override
  void initState() {
    super.initState();
    // 정상 경로에서는 스플래시 해제가 자동 로그인 뒤에 일어나지만 여기까지
    // 왔다면 그 코드는 실행되지 않는다 — 직접 지우지 않으면 스플래시가 남는다.
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = PlatformDispatcher.instance.locale.languageCode == 'ko';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFF9E9E9E)),
                const SizedBox(height: 16),
                Text(
                  isKorean
                      ? '앱을 시작하지 못했습니다.\n앱을 완전히 종료한 뒤 다시 실행해 주세요.'
                      : "Couldn't start the app.\n"
                          'Please close it completely and open it again.',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 15, color: Color(0xFF424242)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
