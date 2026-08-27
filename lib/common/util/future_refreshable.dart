import 'package:feple/common/util/forced_refresh.dart';
import 'package:flutter/widgets.dart';

/// [late Future<D> 필드 + initState 조회 + refresh()] 반복 패턴을 캡슐화.
///
/// refresh()의 setState 콜백은 반드시 block body를 쓴다 — arrow body(`() => future = next`)는
/// 대입식의 값(Future)을 그대로 반환해 Flutter의 런타임 assert
/// ("setState() callback argument returned a Future")를 유발할 수 있다.
/// GlobalKey로 부모가 refresh()를 호출해 완료 시점을 기다리는 화면들이 있어
/// (Future.wait로 여러 섹션을 묶어 새로고침) 예외를 내부에서 흡수한다.
mixin FutureRefreshable<D, T extends StatefulWidget> on State<T> {
  late Future<D> future;

  Future<D> fetchData();

  @override
  void initState() {
    super.initState();
    future = fetchData();
  }

  Future<void> refresh() async {
    // 사용자가 명시적으로 새로고침한 것이므로 SWR 캐시를 건너뛰고 실제 요청
    final next = withForcedRefresh(fetchData);
    setState(() {
      future = next;
    });
    try {
      await next;
    } catch (_) {}
  }
}
