import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_status_filter_chip.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/song_request_status_style.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongRequestListScreen extends StatefulWidget {
  const SongRequestListScreen({super.key});

  @override
  State<SongRequestListScreen> createState() => _SongRequestListScreenState();
}

class _SongRequestListScreenState extends State<SongRequestListScreen> {
  final _service = sl<SongRequestService>();
  List<SongRequestModel> _requests = [];
  bool _loading = true;
  bool _hasError = false;
  int? _userId;
  SongRequestStatus? _filter; // null = 전체

  List<SongRequestModel> get _filtered => _filter == null
      ? _requests
      : _requests.where((r) => r.status == _filter).toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<UserProvider>().currentUserId;
    if (uid != null && uid != _userId) {
      _userId = uid;
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId == null) return;
    setState(() { _loading = true; _hasError = false; });
    try {
      final list = await _service.fetchAllMyRequests(_userId!);
      if (mounted) setState(() { _requests = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  // RefreshIndicator용 — 기존 목록 유지, 스켈레톤 전환 없음
  Future<void> _refresh() async {
    if (_userId == null) return;
    try {
      final list = await _service.fetchAllMyRequests(_userId!);
      if (mounted) setState(() { _requests = list; _hasError = false; });
    } catch (_) {}
  }

  Widget _buildScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: const [
            SkeletonBox(
              width: 20,
              height: 20,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 11),
                ],
              ),
            ),
            SizedBox(width: 8),
            SkeletonBox(
              width: 50,
              height: 22,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(AbstractThemeColors colors) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          StatusFilterChip(
            label: 'filter_all'.tr(),
            selected: _filter == null,
            selectedColor: colors.activate,
            onSelected: (_) => setState(() => _filter = null),
          ),
          StatusFilterChip(
            label: 'song_status_pending'.tr(),
            selected: _filter == SongRequestStatus.pending,
            selectedColor: colors.textSecondary,
            onSelected: (_) => setState(() => _filter = SongRequestStatus.pending),
          ),
          StatusFilterChip(
            label: 'song_status_approved'.tr(),
            selected: _filter == SongRequestStatus.approved,
            selectedColor: colors.activate,
            onSelected: (_) => setState(() => _filter = SongRequestStatus.approved),
          ),
          StatusFilterChip(
            label: 'song_status_rejected'.tr(),
            selected: _filter == SongRequestStatus.rejected,
            selectedColor: AppColors.errorRed,
            onSelected: (_) => setState(() => _filter = SongRequestStatus.rejected),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    final displayed = _filtered;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: colors.activate,
      child: _loading
          ? _buildSkeleton(colors)
          : _hasError
              ? _buildScrollable(
                  ErrorState(
                    message: 'err_fetch_data'.tr(),
                    onRetry: _load,
                  ),
                )
              : displayed.isEmpty
                  ? _buildScrollable(
                      EmptyState(
                        icon: Icons.music_off_rounded,
                        title: 'song_request_no_history'.tr(),
                        subtitle: _filter == null
                            ? 'song_request_no_history_hint'.tr()
                            : null,
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: displayed.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: colors.listDivider),
                      itemBuilder: (_, index) =>
                          SongRequestItem(req: displayed[index]),
                    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: SecondaryAppBar(title: 'song_request_history'.tr()),
      body: Column(
        children: [
          _buildFilterChips(colors),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }
}

class SongRequestItem extends StatelessWidget {
  final SongRequestModel req;
  final double verticalPadding;

  const SongRequestItem({required this.req, this.verticalPadding = 14, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = req.status.displayColor(colors);
    final statusLabel = req.status.labelKey.tr();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, size: 20, color: colors.activate),
          const SizedBox(width: 12),
          Expanded(child: _buildInfoColumn(context.isEnglish, colors)),
          const SizedBox(width: 8),
          _buildStatusBadge(statusColor, statusLabel),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(bool isEnglish, AbstractThemeColors colors) {
    final artistDisplay = req.displayArtistName(isEnglish);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          req.songTitle,
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w600,
            color: colors.textTitle,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (artistDisplay != null)
          Text(artistDisplay, style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary)),
        if (req.formattedDate != null)
          Text(req.formattedDate!, style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary)),
      ],
    );
  }

  Widget _buildStatusBadge(Color statusColor, String statusLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ],
      ),
    );
  }
}
