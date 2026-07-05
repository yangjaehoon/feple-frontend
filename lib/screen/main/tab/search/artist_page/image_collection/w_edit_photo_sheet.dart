import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/photo_destination.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:feple/model/artist_photo.dart';

// ── 사진 수정 바텀시트 ──

class EditPhotoSheet extends StatefulWidget {
  final int artistId;
  final ArtistPhotoResponse photo;
  final void Function(String title, String description) onSave;

  const EditPhotoSheet({
    super.key,
    required this.artistId,
    required this.photo,
    required this.onSave,
  });

  @override
  State<EditPhotoSheet> createState() => _EditPhotoSheetState();
}

class _EditPhotoSheetState extends State<EditPhotoSheet> {
  final _scheduleService = sl<ArtistScheduleService>();
  late final TextEditingController _titleCtrl;
  List<FestivalPreview> _festivals = [];
  PhotoDestination? _selectedDestination;
  bool _loadingFestivals = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.photo.title);
    _loadFestivals();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFestivals() async {
    try {
      final festivals = await _scheduleService.fetchFestivals(widget.artistId);

      // 현재 description 기준으로 초기 선택값 결정
      final preSelected =
          PhotoDestination.fromDescription(widget.photo.description, festivals);

      if (mounted) {
        setState(() {
          _festivals = festivals;
          _selectedDestination = preSelected;
          _loadingFestivals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFestivals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: BottomSheetHandle()),
          const SizedBox(height: 12),
          Text(
            'photo_edit_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 16),
          _buildTitleField(colors),
          const SizedBox(height: 12),
          _buildFestivalDropdown(colors),
          const SizedBox(height: 16),
          _buildSaveButton(colors),
        ],
        ),
      ),
    );
  }

  Widget _buildTitleField(AbstractThemeColors colors) {
    return TextField(
      controller: _titleCtrl,
      decoration: InputDecoration(
        labelText: 'photo_title_label'.tr(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(color: colors.activate, width: 2),
        ),
      ),
    );
  }

  Widget _buildFestivalDropdown(AbstractThemeColors colors) {
    return DropdownButtonFormField<PhotoDestination>(
      initialValue: _selectedDestination,
      decoration: InputDecoration(
        labelText: 'festival_label'.tr(),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(color: colors.activate, width: 2),
        ),
      ),
      hint: _loadingFestivals
          ? Text('loading'.tr())
          : Text('select_festival_hint'.tr()),
      items: [
        ..._festivals.map((f) => DropdownMenuItem(
              value: FestivalDestination(f),
              child: Text(f.displayTitle(context.isEnglish), overflow: TextOverflow.ellipsis),
            )),
        ...PhotoDestination.categories.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c.labelKey.tr()),
            )),
      ],
      onChanged: (d) => setState(() => _selectedDestination = d),
    );
  }

  Widget _buildSaveButton(AbstractThemeColors colors) {
    return LoadingButton(
      label: 'save'.tr(),
      // 시트를 즉시 닫고 실제 저장은 onSave 콜백에서 비동기로 처리하는 구조라
      // (아래 참고) 이 버튼 자체가 로딩 상태를 가질 일이 없음 — 항상 false가 맞음
      isLoading: false,
      onPressed: () {
        final newTitle = _titleCtrl.text.trim();
        if (newTitle.isEmpty) return;
        final newDesc = _selectedDestination?.description ?? '';
        Navigator.pop(context);
        widget.onSave(newTitle, newDesc);
      },
      backgroundColor: colors.activate,
      height: 48,
      borderRadius: 12,
    );
  }
}
