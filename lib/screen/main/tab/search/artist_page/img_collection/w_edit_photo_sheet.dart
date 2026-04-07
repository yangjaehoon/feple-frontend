import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/FestivalPreview.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/img_collection/dto_artist_photo_response.dart';

const _dailyOption = FestivalPreview(
    id: -2, title: '일상 사진', location: '', posterUrl: '', startDate: '');
const _snsOption = FestivalPreview(
    id: -3, title: 'SNS 사진', location: '', posterUrl: '', startDate: '');
const _otherOption = FestivalPreview(
    id: -1, title: '기타', location: '', posterUrl: '', startDate: '');

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
      final resp =
          await DioClient.dio.get('/artists/${widget.artistId}/schedule');
      final list = resp.data as List<dynamic>;
      final festivals = list.map((e) {
        final m = e as Map<String, dynamic>;
        return FestivalPreview(
          id: (m['festivalId'] as num).toInt(),
          title: (m['title'] ?? '') as String,
          location: (m['location'] ?? '') as String,
          posterUrl: (m['posterUrl'] ?? '') as String,
          startDate: m['startDate']?.toString() ?? '',
        );
      }).toList();

      // 현재 description 기준으로 초기 선택값 결정
      final desc = widget.photo.description;
      FestivalPreview? preSelected;
      if (desc == '일상 사진') {
        preSelected = _dailyOption;
      } else if (desc == 'SNS 사진') {
        preSelected = _snsOption;
      } else if (desc.isEmpty) {
        preSelected = _otherOption;
      } else {
        for (final f in festivals) {
          if (f.title == desc) {
            preSelected = f;
            break;
          }
        }
        preSelected ??= _otherOption;
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
            '사진 수정',
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
              labelText: '제목',
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
              labelText: '페스티벌',
              labelStyle: TextStyle(color: colors.textSecondary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.activate, width: 2),
              ),
            ),
            hint: _loadingFestivals
                ? const Text('불러오는 중...')
                : const Text('페스티벌을 선택하세요'),
            items: [
              ..._festivals.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.title, overflow: TextOverflow.ellipsis),
                  )),
              const DropdownMenuItem(value: _dailyOption, child: Text('일상 사진')),
              const DropdownMenuItem(value: _snsOption, child: Text('SNS 사진')),
              const DropdownMenuItem(value: _otherOption, child: Text('기타')),
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
              child: const Text('저장',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
