import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/song_request_service.dart';
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
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.listDivider),
      itemBuilder: (_, __) => Padding(
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

  Widget _buildAppBar(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.backgroundMain,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textTitle),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                'song_request_history'.tr(),
                style: TextStyle(
                  color: colors.textTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return RefreshIndicator(
      onRefresh: _load,
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
              : _requests.isEmpty
                  ? _buildScrollable(
                      EmptyState(
                        icon: Icons.music_off_rounded,
                        title: 'song_request_no_history'.tr(),
                        subtitle: 'song_request_no_history_hint'.tr(),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _requests.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.listDivider),
                      itemBuilder: (_, i) =>
                          _SongRequestItem(req: _requests[i], colors: colors),
                    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          _buildAppBar(colors),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }
}

class _SongRequestItem extends StatelessWidget {
  final SongRequestModel req;
  final AbstractThemeColors colors;

  const _SongRequestItem({required this.req, required this.colors});

  @override
  Widget build(BuildContext context) {
    final statusColor = req.isPending
        ? colors.textSecondary
        : req.isApproved
            ? colors.activate
            : Theme.of(context).colorScheme.error;
    final statusLabel = req.isPending
        ? 'song_status_pending'.tr()
        : req.isApproved
            ? 'song_status_approved'.tr()
            : 'song_status_rejected'.tr();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, size: 20, color: colors.activate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.songTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textTitle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (req.artistName != null)
                  Text(
                    req.artistName!,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                if (req.createdAt != null)
                  Text(
                    _formatDate(req.createdAt!),
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
