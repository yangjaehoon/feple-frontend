import 'package:flutter/widgets.dart';

/// 화면(부모)이 여러 섹션(자식)을 GlobalKey 없이 한 번에 새로고침하기 위한 조정자.
///
/// 부모는 [RefreshScope]로 하위 트리를 감싸 [RefreshCoordinator]를 제공하고, 각
/// 섹션의 State는 [RefreshableSection] mixin으로 자신을 등록한다. 부모의 당겨서-
/// 새로고침은 [refreshAll]을 await 하므로 모든 섹션의 로드가 끝날 때까지 스피너가
/// 유지된다 (예전엔 GlobalKey로 자식 State를 붙잡아 `refresh()`를 뿌리기만 하고
/// 완료를 기다리지 못했다).
class RefreshCoordinator {
  final _sections = <RefreshableSection>{};

  void register(RefreshableSection section) => _sections.add(section);

  void unregister(RefreshableSection section) => _sections.remove(section);

  /// 등록된 모든 섹션을 새로고침하고 전부 끝날 때까지 기다린다.
  /// 한 섹션의 실패가 다른 섹션 새로고침이나 RefreshIndicator(onRefresh 예외 시
  /// 크래시)를 막지 않도록 섹션별로 격리한다 — 에러 표시는 각 섹션이 담당한다.
  Future<void> refreshAll() => Future.wait(
        _sections.map((section) async {
          try {
            await section.refreshSection();
          } catch (_) {
            // 섹션이 자체 에러 상태로 처리한다.
          }
        }),
      );
}

/// [RefreshCoordinator]를 하위 트리에 전달하는 InheritedWidget.
class RefreshScope extends InheritedWidget {
  const RefreshScope({
    super.key,
    required this.coordinator,
    required super.child,
  });

  final RefreshCoordinator coordinator;

  static RefreshCoordinator? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RefreshScope>()
      ?.coordinator;

  @override
  bool updateShouldNotify(RefreshScope oldWidget) =>
      coordinator != oldWidget.coordinator;
}

/// 새로고침 가능한 화면 섹션. 자식 State가 mixin 하고 [refreshSection]을 구현하면
/// 조상 [RefreshScope]의 코디네이터에 자동 등록/해제된다. [RefreshScope]가 없으면
/// (섹션을 단독으로 테스트/렌더링할 때) 아무 일도 하지 않는다.
mixin RefreshableSection<T extends StatefulWidget> on State<T> {
  RefreshCoordinator? _refreshCoordinator;

  /// 이 섹션을 새로 불러온다. 실제 로드가 끝나는 Future를 반환해야
  /// 부모의 새로고침 스피너가 완료와 맞물린다.
  Future<void> refreshSection();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = RefreshScope.maybeOf(context);
    if (!identical(next, _refreshCoordinator)) {
      _refreshCoordinator?.unregister(this);
      _refreshCoordinator = next;
      _refreshCoordinator?.register(this);
    }
  }

  @override
  void dispose() {
    _refreshCoordinator?.unregister(this);
    super.dispose();
  }
}
