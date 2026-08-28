import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:flutter/material.dart';

/// 드래그 정렬 바텀시트의 공통 뼈대: 핸들 + 헤더 + 구분선 + 리스트(Flexible) +
/// 구분선 + 확인 버튼. 헤더/리스트 내용과 확인 동작만 화면별로 주입받는다.
class DraggableSheetScaffold extends StatelessWidget {
  final Widget header;
  final Widget list;
  final VoidCallback onConfirm;

  const DraggableSheetScaffold({
    super.key,
    required this.header,
    required this.list,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDimens.space12),
            const BottomSheetHandle(),
            const SizedBox(height: AppDimens.space16),
            header,
            const SizedBox(height: AppDimens.space8),
            Divider(color: colors.listDivider, height: 1),
            list,
            Divider(color: colors.listDivider, height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
              child: LoadingButton(
                label: 'confirm'.tr(),
                isLoading: false,
                backgroundColor: colors.activate,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
