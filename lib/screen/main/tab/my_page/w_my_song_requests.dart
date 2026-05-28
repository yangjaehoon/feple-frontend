import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (_requests != null && _requests!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(colors),
        _buildContent(colors),
      ],
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: colors.sectionBarColor,
              borderRadius: BorderRadius.circular(AppDimens.barRadius),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'song_request_history'.tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textTitle),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_loading) return _buildSkeleton();
    if (_hasError) return _buildError(colors);
    final items = _requests!;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.listDivider),
      itemBuilder: (_, i) => _buildItem(items[i], colors),
    );
  }

  Widget _buildItem(SongRequestModel req, AbstractThemeColors colors) {
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textTitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (req.artistName != null)
                  Text(
                    req.artistName!,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
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

  Widget _buildError(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text('err_fetch_data'.tr(args: ['']), style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _load,
            child: Text(
              'retry'.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.activate),
            ),
          ),
        ],
      ),
    );
  }
}
