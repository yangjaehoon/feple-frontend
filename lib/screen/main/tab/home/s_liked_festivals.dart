import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/order_utils.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_preview_card.dart';
import 'package:feple/screen/main/tab/home/reorder_settings_flow.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/onboarding/s_festival_pick.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

FestivalPreview _asPreview(FestivalModel f) => FestivalPreview(
      id: f.id,
      title: f.title,
      titleEn: f.titleEn,
      description: f.description,
      location: f.location,
      posterUrl: f.posterUrl,
      startDate: f.startDate,
      endDate: f.endDate,
      genres: f.genres,
      ageRestriction: f.ageRestriction,
      latitude: f.latitude,
      longitude: f.longitude,
      attendingCount: f.attendingCount,
    );

class LikedFestivalsScreen extends StatefulWidget {
  const LikedFestivalsScreen({
    super.key,
    required this.festivals,
    this.onSaveOrder,
  });

  final List<FestivalModel> festivals;
  final Future<void> Function(List<int>)? onSaveOrder;

  @override
  State<LikedFestivalsScreen> createState() => _LikedFestivalsScreenState();
}

class _LikedFestivalsScreenState extends State<LikedFestivalsScreen>
    with NavigationGuard, ReorderSettingsFlow<LikedFestivalsScreen> {
  bool _showEnded = false;
  late List<FestivalModel> _festivals;

  @override
  void initState() {
    super.initState();
    _festivals = widget.festivals;
  }

  @override
  Future<void> Function(List<int>)? get onSaveOrder => widget.onSaveOrder;

  @override
  String get reorderSheetTitle => 'liked_festivals'.tr();

  @override
  String? get reorderSheetSubtitle => 'reorder_liked_festivals_hint'.tr();

  @override
  List<ReorderItem> buildReorderItems() {
    final isEnglish = context.isEnglish;
    return _festivals
        .where((f) => !f.isEnded)
        .map((f) => ReorderItem(id: f.id, name: f.displayTitle(isEnglish), imageUrl: f.posterUrl))
        .toList();
  }

  // 저장 성공 여부와 무관하게 화면에 방금 지정한 순서를 즉시 반영 —
  // widget.festivals는 화면 진입 시점의 스냅샷이라 onSaveOrder가 상위
  // notifier를 갱신해도 이 화면 자체는 재진입 전까지 반영되지 않았음
  @override
  void applyReorder(List<int> newOrder) {
    setState(() => _festivals = reorderById(_festivals, newOrder, (f) => f.id));
  }

  List<FestivalModel> get _filtered =>
      _festivals.where((f) => f.isEnded == _showEnded).toList();

  // 종료된 페스티벌은 새로 찜할 대상이 아니므로(FestivalPickScreen도 다가오는
  // 페스티벌만 조회) "예정" 탭이 비었을 때만 CTA를 보여준다. widget.festivals는
  // 진입 시점 스냅샷이라 이 화면 자체는 새로 찜한 항목을 반영할 방법이 없다 —
  // 그냥 이 화면만 닫으면 방금 찜한 게 여전히 안 보이는 것처럼 보이므로,
  // 실제로 뭔가 찜했을 때(didLike)만 이 화면까지 함께 닫아 데이터가 항상
  // 최신인 홈으로 보낸다. 아무것도 안 고르고 나가는 경우(didLike=false)까지
  // 홈으로 튕겨내면 불필요한 이탈이라 이 화면에 그대로 남는다.
  void _openFestivalPick() {
    Navigator.push(
      context,
      SlideRoute(
        builder: (_) => FestivalPickScreen(
          onComplete: (didLike) async {
            Navigator.pop(context);
            // canPop 가드: 이 화면이 (테스트 등에서) 최상위 라우트로 떠 있는
            // 경우 popUntil 대상이 없어 팝을 시도하면 안 되므로 방어.
            if (didLike && mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          progressDotIndex: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'back'.tr(),
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textTitle, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'liked_festivals'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        actions: [
          if (widget.onSaveOrder != null && !_showEnded)
            IconButton(
              tooltip: 'settings'.tr(),
              icon: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 20),
              onPressed: openReorderSettings,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTabToggle(colors),
          Expanded(child: _buildList(filtered, colors)),
        ],
      ),
    );
  }

  Widget _buildTabToggle(AbstractThemeColors colors) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _TabButton(
            label: 'tab_upcoming_festivals'.tr(),
            selected: !_showEnded,
            colors: colors,
            onTap: () => setState(() => _showEnded = false),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'tab_ended_festivals'.tr(),
            selected: _showEnded,
            colors: colors,
            onTap: () => setState(() => _showEnded = true),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<FestivalModel> items, AbstractThemeColors colors) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border_rounded,
        title: _showEnded ? 'tab_ended_festivals'.tr() : 'tab_upcoming_festivals'.tr(),
        subtitle: 'no_liked_in_tab'.tr(),
        action: _showEnded
            ? null
            : FilledButton(
                onPressed: _openFestivalPick,
                style: FilledButton.styleFrom(backgroundColor: colors.activate),
                child: Text('home_add_festivals_cta'.tr()),
              ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final festival = items[index];
        return AnimatedListItem(
          index: index,
          child: TapScale(
            onTap: () => guardedNavigate(() => Navigator.push(
              context,
              SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
            )),
            child: FestivalPreviewCard(festival: _asPreview(festival)),
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AbstractThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.activate : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: selected ? Theme.of(context).colorScheme.onPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
