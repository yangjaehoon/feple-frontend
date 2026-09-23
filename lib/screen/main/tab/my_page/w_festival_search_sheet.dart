import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/debouncer.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/model/festival_model.dart';
import 'package:flutter/material.dart';

/// 이미 불러온 페스티벌 목록에서 하나를 고르는 검색 바텀시트.
/// 인증 사진 제출·페스티벌 일기 작성에서 공용으로 쓴다.
/// 선택하면 `Navigator.pop`으로 [FestivalModel]을 돌려준다.
class FestivalSearchSheet extends StatefulWidget {
  final List<FestivalModel> festivals;

  const FestivalSearchSheet({super.key, required this.festivals});

  @override
  State<FestivalSearchSheet> createState() => _FestivalSearchSheetState();
}

class _FestivalSearchSheetState extends State<FestivalSearchSheet> {
  late List<FestivalModel> _filtered;
  final _searchCtrl = TextEditingController();
  final _debounce = Debouncer(AppDimens.debounceLocalFilter);

  @override
  void initState() {
    super.initState();
    _filtered = widget.festivals;
  }

  @override
  void dispose() {
    _debounce.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce.run(() {
      if (!mounted) return;
      final keyword = query.toLowerCase();
      setState(() {
        _filtered = widget.festivals
            .where(
              (f) =>
                  f.title.toLowerCase().contains(keyword) ||
                  f.titleEn.toLowerCase().contains(keyword),
            )
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Material(
          color: colors.backgroundMain,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.shapeSheet),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: AppDimens.space12),
              const BottomSheetHandle(),
              _buildSearchField(),
              Expanded(child: _buildFestivalList(ctx, scrollCtrl)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'festival_search_hint'.tr(),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFestivalList(BuildContext ctx, ScrollController scrollCtrl) {
    if (_filtered.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'search_no_result'.tr(),
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      itemCount: _filtered.length,
      itemBuilder: (_, index) {
        final festival = _filtered[index];
        return ListTile(
          title: Text(
            festival.displayTitle(context.isEnglish),
            style: const TextStyle(fontSize: AppDimens.fontSizeMd),
          ),
          onTap: () => Navigator.pop(ctx, festival),
        );
      },
    );
  }
}
