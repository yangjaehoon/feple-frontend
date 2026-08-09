import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/photo_destination.dart';
import 'package:flutter/material.dart';

/// 사진 업로드/수정 시 페스티벌 또는 프로필·배경 카테고리를 고르는 공용 드롭다운.
/// [w_image_upload.dart]/[w_edit_photo_sheet.dart]가 festivals 로딩 방식만
/// 다르고(FutureBuilder vs 사전 로드) 나머지 구성이 동일했던 것을 공유한다.
class FestivalDestinationDropdown extends StatelessWidget {
  final List<FestivalPreview> festivals;
  final PhotoDestination? value;
  final bool isLoading;
  final ValueChanged<PhotoDestination?> onChanged;
  final FormFieldValidator<PhotoDestination>? validator;

  const FestivalDestinationDropdown({
    super.key,
    required this.festivals,
    required this.value,
    required this.isLoading,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DropdownButtonFormField<PhotoDestination>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'festival_label'.tr(),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(color: colors.activate, width: 2),
        ),
      ),
      hint: isLoading ? Text('loading'.tr()) : Text('select_festival_hint'.tr()),
      items: [
        ...festivals.map((f) => DropdownMenuItem(
              value: FestivalDestination(f),
              child: Text(f.displayTitle(context.isEnglish), overflow: TextOverflow.ellipsis),
            )),
        ...PhotoDestination.categories.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c.labelKey.tr()),
            )),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}
