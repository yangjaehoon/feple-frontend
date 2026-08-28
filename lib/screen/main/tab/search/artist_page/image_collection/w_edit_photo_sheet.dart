import 'package:feple/common/common.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/photo_destination.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:feple/model/artist_photo.dart';

import 'w_festival_destination_dropdown.dart';

// ── 사진 수정 바텀시트 ──

class EditPhotoSheet extends StatefulWidget {
  final int artistId;
  final ArtistPhoto photo;
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
  // 로딩 중 사용자가 드롭다운을 직접 조작했으면 true — 이후 fetch 완료 시
  // preSelected로 덮어쓰지 않기 위한 가드
  bool _userChangedDestination = false;
  String? _titleError;

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
          // 로딩 중 사용자가 이미 선택을 마쳤다면 그 선택을 유지
          if (!_userChangedDestination) _selectedDestination = preSelected;
          _loadingFestivals = false;
        });
      }
    } catch (e) {
      // 실패해도 드롭다운은 빈 채로 그냥 쓸 수 있게 두되(설명 필드로 대체 가능),
      // 실패인지 원래 목록이 없는지 사용자가 구분할 수 있도록 알린다
      if (mounted) {
        setState(() => _loadingFestivals = false);
        context.showErrorSnackbar(networkAwareErrorKey(e, 'err_fetch_data').tr());
      }
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
          const SizedBox(height: AppDimens.space12),
          Text(
            'photo_edit_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          _buildTitleField(colors),
          const SizedBox(height: AppDimens.space12),
          _buildFestivalDropdown(),
          const SizedBox(height: AppDimens.space16),
          _buildSaveButton(colors),
        ],
        ),
      ),
    );
  }

  Widget _buildTitleField(AbstractThemeColors colors) {
    return TextField(
      controller: _titleCtrl,
      onChanged: (_) {
        if (_titleError != null) setState(() => _titleError = null);
      },
      decoration: InputDecoration(
        labelText: 'photo_title_label'.tr(),
        errorText: _titleError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(color: colors.activate, width: 2),
        ),
      ),
    );
  }

  Widget _buildFestivalDropdown() {
    return FestivalDestinationDropdown(
      festivals: _festivals,
      value: _selectedDestination,
      isLoading: _loadingFestivals,
      onChanged: (d) => setState(() {
        _selectedDestination = d;
        _userChangedDestination = true;
      }),
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
        if (newTitle.isEmpty) {
          setState(() => _titleError = 'required_field'.tr());
          return;
        }
        // fetch 실패 등으로 선택값이 없으면 기존 description을 그대로 유지 —
        // 빈 문자열로 저장해 페스티벌 태그를 지워버리는 것을 방지
        final newDesc = _selectedDestination?.description ?? widget.photo.description;
        Navigator.pop(context);
        widget.onSave(newTitle, newDesc);
      },
      backgroundColor: colors.activate,
      height: 48,
      borderRadius: 12,
    );
  }
}
