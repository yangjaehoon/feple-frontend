import 'package:flutter/material.dart';

/// 전역 `inputDecorationTheme`의 **테두리만**(`border`/`enabledBorder`/`focusedBorder`
/// 등) 이 subtree에서 해제한다. `filled`·`contentPadding`·`hintStyle` 등 나머지
/// 전역 설정은 그대로 유지한다.
///
/// 직접 테두리를 그리는 컨테이너 안이나 앱바 위에 borderless [TextField]를 놓을 때
/// 사용한다. `border: InputBorder.none`만으로는 부족하다 — 전역 테마가
/// `enabledBorder`/`focusedBorder`를 정의하면 평상시/포커스 상태에서 그쪽이 우선
/// 적용돼 테두리가 남기 때문이다.
class BorderlessInputTheme extends StatelessWidget {
  final Widget child;

  const BorderlessInputTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
      child: child,
    );
  }
}
