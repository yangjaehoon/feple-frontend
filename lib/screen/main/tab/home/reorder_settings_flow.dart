import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:flutter/widgets.dart';

/// "설정 시트 열기 → 재정렬/저장 → 화면에 즉시 반영" 흐름 공용화.
/// 화면별 State가 buildReorderItems()/applyReorder()/reorderSheetTitle만
/// 구현하면 되고, 중복 오픈 방지 가드와 시트 표시는 이 mixin이 담당한다.
mixin ReorderSettingsFlow<T extends StatefulWidget> on State<T> {
  bool _isSheetOpen = false;

  String get reorderSheetTitle;
  String? get reorderSheetSubtitle => null;
  Future<void> Function(List<int>)? get onSaveOrder;

  List<ReorderItem> buildReorderItems();

  /// 시트에서 확정한 새 순서를 화면 상태에 즉시 반영.
  /// onSaveOrder가 상위 notifier를 갱신해도 이 화면 자체는 재진입 전까지
  /// 반영되지 않으므로, setState로 직접 반영해야 한다.
  void applyReorder(List<int> newOrder);

  Future<void> openReorderSettings() async {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    final newOrder = await showAppBottomSheet<List<int>>(
      context,
      builder: (_) => ReorderSheet(
        title: reorderSheetTitle,
        subtitle: reorderSheetSubtitle,
        items: buildReorderItems(),
        onSave: onSaveOrder ?? (_) {},
      ),
    );
    if (mounted) _isSheetOpen = false;
    if (newOrder != null && mounted) applyReorder(newOrder);
  }
}
