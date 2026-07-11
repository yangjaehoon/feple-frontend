import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_empty_state.dart';
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

class MySongRequestsView extends StatefulWidget {
  const MySongRequestsView({super.key});

  @override
  State<MySongRequestsView> createState() => MySongRequestsViewState();
}

class MySongRequestsViewState extends State<MySongRequestsView> {
  final _service = sl<SongRequestService>();
  List<SongRequestModel>? _requests;
  bool _isLoading = true;
  bool _hasError = false;
  int? _userId;

  void refresh() => _load();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<UserProvider>().currentUserId;
    if (userId != null && userId != _userId) {
      _userId = userId;
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId == null) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final list = await _service.fetchAllMyRequests(_userId!);
      if (mounted) setState(() { _requests = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
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
            onPressed: _isLoading ? null : _openFullList,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.padded,
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
    if (_isLoading) return _buildSkeleton();
    if (_hasError) return _buildError();

    final items = _requests ?? [];
    if (items.isEmpty) return _buildEmpty();

    final preview = items.take(_previewCount).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < preview.length; i++) ...[
                SongRequestItem(req: preview[i], verticalPadding: 12),
                if (i < preview.length - 1)
                  Divider(height: 1, color: colors.listDivider),
              ],
            ],
          ),
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

  Widget _buildEmpty() {
    return EmptyState(icon: Icons.music_off_rounded, title: 'song_request_no_history'.tr());
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
