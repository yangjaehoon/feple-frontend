import 'package:feple/common/common.dart';
import 'package:feple/common/constant/photo_category.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/model/artist_photo_response.dart';

// ── 사진 수정 바텀시트 ──

class EditPhotoSheet extends StatefulWidget {
  final int artistId;
  final ArtistPhotoResponse photo;
  final AbstractThemeColors colors;
  final void Function(String title, String description) onSave;

  const EditPhotoSheet({
    super.key,
    required this.artistId,
    required this.photo,
    required this.colors,
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
          await ArtistScheduleService.fetchFestivals(widget.artistId);

      // 현재 description 기준으로 초기 선택값 결정
      final desc = widget.photo.description;
      FestivalPreview? preSelected;
      if (desc == '일상 사진') {
        preSelected = photoCategoryDaily;
      } else if (desc == 'SNS 사진') {
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
    final colors = widget.colors;
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
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'photo_title_label'.tr(),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.activate, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FestivalPreview>(
            initialValue: _selectedFestival,
            decoration: InputDecoration(
              labelText: 'festival_label'.tr(),
              labelStyle: TextStyle(color: colors.textSecondary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              const DropdownMenuItem(value: photoCategoryDaily, child: Text('일상 사진')),
              const DropdownMenuItem(value: photoCategorySns, child: Text('SNS 사진')),
              const DropdownMenuItem(value: photoCategoryOther, child: Text('기타')),
            ],
            onChanged: (f) => setState(() => _selectedFestival = f),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final newTitle = _titleCtrl.text.trim();
                if (newTitle.isEmpty) return;
                final newDesc = _selectedFestival?.id == -1
                    ? ''
                    : (_selectedFestival?.title ?? '');
                Navigator.pop(context);
                widget.onSave(newTitle, newDesc);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.activate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('save'.tr(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
