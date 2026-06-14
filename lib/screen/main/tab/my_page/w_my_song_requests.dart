import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/screen/main/tab/my_page/s_song_request_list.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _previewCount = 3;

class SongRequestHistoryWidget extends StatefulWidget {
  const SongRequestHistoryWidget({super.key});

  @override
  State<SongRequestHistoryWidget> createState() => _SongRequestHistoryWidgetState();
}

class _SongRequestHistoryWidgetState extends State<SongRequestHistoryWidget> {
  final _service = sl<SongRequestService>();
  List<SongRequestModel>? _requests;
  bool _loading = true;
  bool _hasError = false;
  int? _userId;

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
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final list = await _service.fetchAllMyRequests(_userId!);
      if (mounted) setState(() { _requests = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _openFullList() async {
    await Navigator.push(
      context,
      SlideRoute(builder: (_) => const SongRequestListScreen()),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'song_request_history'.tr(),
          trailing: TextButton(
            onPressed: _loading ? null : _openFullList,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'see_all'.tr(),
                  style: TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w600, color: colors.activate),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: colors.activate),
              ],
            ),
          ),
        ),
        _buildContent(colors),
      ],
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_loading) return _buildSkeleton();
    if (_hasError) return _buildError();

    final items = _requests ?? [];
    if (items.isEmpty) return _buildEmpty(colors);

    final preview = items.take(_previewCount).toList();
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: preview.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: colors.listDivider),
          itemBuilder: (_, index) => SongRequestItem(req: preview[index], verticalPadding: 12),
        ),
        if (items.length > _previewCount)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: InkWell(
              onTap: _openFullList,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+ ${items.length - _previewCount}',
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'see_all'.tr(),
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_rounded, size: 32,
                color: colors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              'song_request_no_history'.tr(),
              style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          _previewCount,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                      SizedBox(height: 4),
                      SkeletonBox(width: 80, height: 11),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                SkeletonBox(
                  width: 50,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ErrorState(message: 'err_fetch_data'.tr(), onRetry: _load),
    );
  }
}
