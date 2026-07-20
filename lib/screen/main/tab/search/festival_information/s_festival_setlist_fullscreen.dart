import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/url_validator.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FestivalSetlistFullscreenScreen extends StatefulWidget {
  final int festivalId;

  const FestivalSetlistFullscreenScreen({super.key, required this.festivalId});

  @override
  State<FestivalSetlistFullscreenScreen> createState() =>
      _FestivalSetlistFullscreenScreenState();
}

class _FestivalSetlistFullscreenScreenState
    extends State<FestivalSetlistFullscreenScreen> {
  late Future<List<FestivalSetlistEntry>> _future;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<FestivalSetlistEntry>> _fetch() =>
      sl<FestivalDetailService>().fetchSetlist(widget.festivalId);

  Future<void> _openYoutubeMusic(String url) async {
    if (!isValidYoutubeUrl(url)) {
      context.showErrorSnackbar('youtube_open_failed'.tr());
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) context.showErrorSnackbar('youtube_open_failed'.tr());
    }
  }

  Future<void> _openRequestSheet(FestivalSetlistEntry entry) async {
    await showAppBottomSheet<void>(
      context,
      builder: (_) =>
          SetlistRequestSheet(festivalId: widget.festivalId, entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: _buildAppBar(colors),
      body: _buildBody(colors),
    );
  }

  PreferredSizeWidget _buildAppBar(AbstractThemeColors colors) {
    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      leading: IconButton(
        tooltip: 'back'.tr(),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: colors.textTitle,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'setlist'.tr(),
        style: TextStyle(
          fontSize: AppDimens.fontSizeXl,
          fontWeight: FontWeight.w700,
          color: colors.textTitle,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return AsyncContentBuilder<List<FestivalSetlistEntry>>(
      future: _future,
      loadingBuilder: (_) => _buildSkeleton(colors),
      onRetry: () => setState(() {
        _future = _fetch();
      }),
      emptyBuilder: (_) => Center(
        child: Text(
          'no_setlist'.tr(),
          style: TextStyle(color: colors.textSecondary),
        ),
      ),
      useListViewForEmptyState: false,
      builder: (_, entries) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ArtistFullTile(
          entry: entries[i],
          isExpanded: _expanded.contains(entries[i].artistId),
          onToggle: () => setState(() {
            final id = entries[i].artistId;
            if (_expanded.contains(id)) {
              _expanded.remove(id);
            } else {
              _expanded.add(id);
            }
          }),
          onSongTap: _openYoutubeMusic,
          onRequest: () => _openRequestSheet(entries[i]),
        ),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        child: Row(
          children: [
            const SkeletonBox(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SkeletonBox(height: 14)),
          ],
        ),
      ),
    );
  }
}

class _ArtistFullTile extends StatelessWidget {
  final FestivalSetlistEntry entry;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(String url) onSongTap;
  final VoidCallback onRequest;

  const _ArtistFullTile({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
    required this.onSongTap,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEnglish = context.isEnglish;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderRow(isEnglish, colors),
          if (isExpanded) ...[
            Divider(height: 1, color: colors.listDivider),
            _buildSongList(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow(bool isEnglish, AbstractThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppDimens.cardRadius),
              bottom: isExpanded
                  ? Radius.zero
                  : const Radius.circular(AppDimens.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
              child: Row(
                children: [
                  _buildAvatar(colors),
                  const SizedBox(width: 12),
                  Expanded(child: _buildArtistInfo(isEnglish, colors)),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppDimens.animXFast,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onRequest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Icon(
              Icons.edit_note_rounded,
              size: 18,
              color: colors.activate,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistInfo(bool isEnglish, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.displayName(isEnglish),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w600,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'total_songs'.tr(args: ['${entry.songs.length}']),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXxs,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(AbstractThemeColors colors) {
    const size = 40.0;
    if (entry.profileImageUrl != null && entry.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: entry.profileImageUrl!,
          width: size,
          height: size,
          memCacheWidth: 80,
          fit: BoxFit.cover,
          fadeInDuration: AppDimens.animXFast,
          fadeOutDuration: AppDimens.animTapFeedback,
          placeholder: (_, _) => _avatarPlaceholder(size, colors),
          errorWidget: (_, _, _) => _avatarPlaceholder(size, colors),
        ),
      );
    }
    return _avatarPlaceholder(size, colors);
  }

  Widget _avatarPlaceholder(double size, AbstractThemeColors colors) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildSongList(AbstractThemeColors colors) {
    if (entry.songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Text(
          'no_setlist'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXs,
            color: colors.textSecondary,
          ),
        ),
      );
    }
    return Column(
      children: entry.songs
          .asMap()
          .entries
          .map((e) => _buildSongRow(e.value, e.key, colors))
          .toList(),
    );
  }

  Widget _buildSongRow(SongModel song, int index, AbstractThemeColors colors) {
    return InkWell(
      onTap: () => onSongTap(song.youtubeUrl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (song.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl!,
                  width: 38,
                  height: 38,
                  memCacheWidth: 76,
                  fit: BoxFit.cover,
                  fadeInDuration: AppDimens.animXFast,
                  fadeOutDuration: AppDimens.animTapFeedback,
                  errorWidget: (_, _, _) => _thumbPlaceholder(colors),
                ),
              )
            else
              _thumbPlaceholder(colors),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                song.title,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  color: colors.textTitle,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.open_in_new_rounded,
              size: 13,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(AbstractThemeColors colors) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 16,
        color: colors.textSecondary,
      ),
    );
  }
}

class SetlistRequestSheet extends StatefulWidget {
  final int festivalId;
  final FestivalSetlistEntry entry;

  const SetlistRequestSheet({
    super.key,
    required this.festivalId,
    required this.entry,
  });

  @override
  State<SetlistRequestSheet> createState() => _SetlistRequestSheetState();
}

class _SetlistRequestSheetState extends State<SetlistRequestSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await sl<FestivalDetailService>().submitSetlistRequest(
        festivalId: widget.festivalId,
        artistFestivalId: widget.entry.artistFestivalId,
        artistName: widget.entry.artistName,
        message: message,
      );
      if (mounted) {
        context.showSuccessSnackbar('setlist_request_sent'.tr());
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[Setlist] 요청 전송 실패: $e');
      if (mounted) context.showErrorSnackbar('setlist_request_failed'.tr());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.shapeSheet),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const BottomSheetHandle(),
          _buildHeader(colors),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _buildTextField(colors),
          ),
          _buildFooter(colors),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Flexible(
            child: Text(
              widget.entry.displayName(context.isEnglish),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXl,
                fontWeight: FontWeight.w700,
                color: colors.textTitle,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'setlist_request'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(AbstractThemeColors colors) {
    return TextField(
      controller: _controller,
      maxLines: 6,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: 'setlist_request_hint'.tr(),
        hintStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: AppDimens.fontSizeSm,
          height: 1.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(color: colors.listDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(color: colors.listDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(color: colors.activate, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      style: TextStyle(
        fontSize: AppDimens.fontSizeSm,
        color: colors.textTitle,
        height: 1.5,
      ),
    );
  }

  Widget _buildFooter(AbstractThemeColors colors) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.activate),
                  foregroundColor: colors.activate,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  ),
                ),
                child: Text('cancel'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoadingButton(
                label: 'setlist_request_submit'.tr(),
                onPressed: _submit,
                isLoading: _submitting,
                backgroundColor: colors.activate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
