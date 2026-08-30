import 'package:flutter/material.dart';

/// 전역 `inputDecorationTheme`(OutlineInputBorder 등)를 이 subtree에서만 해제한다.
///
/// 직접 테두리를 그리는 컨테이너 안이나 앱바 위에 borderless [TextField]를 놓을 때
/// 사용한다. `border: InputBorder.none`만으로는 부족하다 — 전역 테마가
/// `enabledBorder`/`focusedBorder`를 정의하면 평상시/포커스 상태에서 그쪽이 우선
/// 적용돼 테두리가 남기 때문이다.
class PlainInputTheme extends StatelessWidget {
  final Widget child;

  const PlainInputTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context)
            .copyWith(inputDecorationTheme: const InputDecorationTheme()),
        child: child,
      );
}
