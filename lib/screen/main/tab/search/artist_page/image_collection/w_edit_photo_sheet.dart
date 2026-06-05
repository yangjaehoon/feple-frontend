import 'package:feple/common/common.dart';
import 'package:feple/common/constant/photo_category.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/model/artist_photo_response.dart';

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
  late final TextEditingController _titleCtrl;
  List<FestivalPreview> _festivals = [];
  FestivalPreview? _selectedFestival;
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
      final festivals =
          await sl<ArtistScheduleService>().fetchFestivals(widget.artistId);

      // 현재 description 기준으로 초기 선택값 결정
      final desc = widget.photo.description;
      FestivalPreview? preSelected;
      if (desc == photoCategoryDaily.title) {
        preSelected = photoCategoryDaily;
      } else if (desc == photoCategorySns.title) {
        preSelected = photoCategorySns;
      } else if (desc.isEmpty) {
        preSelected = photoCategoryOther;
      } else {
        for (final f in festivals) {
          if (f.title == desc) {
            preSelected = f;
            break;
          }
        }
        preSelected ??= photoCategoryOther;
      }

      if (mounted) {
        setState(() {
          _festivals = festivals;
          _selectedFestival = preSelected;
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'photo_edit_title'.tr(),
            style: TextStyle(
              fontSize: 17,
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
    );
  }

  Widget _buildTitleField(AbstractThemeColors colors) {
    return TextField(
      controller: _titleCtrl,
      decoration: InputDecoration(
        labelText: 'photo_title_label'.tr(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.activate, width: 2),
        ),
      ),
    );
  }

  Widget _buildFestivalDropdown(AbstractThemeColors colors) {
    return DropdownButtonFormField<FestivalPreview>(
      initialValue: _selectedFestival,
      decoration: InputDecoration(
        labelText: 'festival_label'.tr(),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.activate, width: 2),
        ),
      ),
      hint: _loadingFestivals
          ? Text('loading'.tr())
          : Text('select_festival_hint'.tr()),
      items: [
        ..._festivals.map((f) => DropdownMenuItem(
              value: f,
              child: Text(f.title, overflow: TextOverflow.ellipsis),
            )),
        DropdownMenuItem(value: photoCategoryDaily, child: Text('photo_category_daily'.tr())),
        DropdownMenuItem(value: photoCategorySns, child: Text('photo_category_sns'.tr())),
        DropdownMenuItem(value: photoCategoryOther, child: Text('photo_category_other'.tr())),
      ],
      onChanged: (f) => setState(() => _selectedFestival = f),
    );
  }

  Widget _buildSaveButton(AbstractThemeColors colors) {
    return LoadingButton(
      label: 'save'.tr(),
      isLoading: false,
      onPressed: () {
        final newTitle = _titleCtrl.text.trim();
        if (newTitle.isEmpty) return;
        final newDesc = _selectedFestival?.id == -1
            ? ''
            : (_selectedFestival?.title ?? '');
        Navigator.pop(context);
        widget.onSave(newTitle, newDesc);
      },
      backgroundColor: colors.activate,
      height: 48,
      borderRadius: 12,
    );
  }
}
