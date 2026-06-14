import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FestivalSetlistFullPage extends StatefulWidget {
  final int festivalId;

  const FestivalSetlistFullPage({super.key, required this.festivalId});

  @override
  State<FestivalSetlistFullPage> createState() => _FestivalSetlistFullPageState();
}

class _FestivalSetlistFullPageState extends State<FestivalSetlistFullPage> {
  late Future<List<FestivalSetlistEntry>> _future;
  final Set<int> _expanded = {};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<FestivalSetlistEntry>> _fetch() =>
      sl<FestivalDetailService>().fetchSetlist(widget.festivalId);

  Future<void> _openYoutubeMusic(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('youtube_open_failed'.tr())),
        );
      }
    }
  }

  Future<void> _openEditSheet(FestivalSetlistEntry entry) async {
    final result = await showAppBottomSheet<bool>(
      context,
      builder: (_) => SetlistEditSheet(
        festivalId: widget.festivalId,
        entry: entry,
      ),
    );
    if (result == true && mounted) {
      _changed = true;
      setState(() => _future = _fetch());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: colors.backgroundMain,
        appBar: _buildAppBar(colors),
        body: _buildBody(colors),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AbstractThemeColors colors) {
    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colors.textTitle),
        onPressed: () => Navigator.pop(context, _changed),
      ),
      title: Text(
        'setlist'.tr(),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textTitle),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return FutureBuilder<List<FestivalSetlistEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(colors);
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'err_fetch_data'.tr(),
            onRetry: () => setState(() => _future = _fetch()),
          );
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Text('no_setlist'.tr(), style: TextStyle(color: colors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
            onEdit: () => _openEditSheet(entries[i]),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
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
  final VoidCallback onEdit;

  const _ArtistFullTile({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
    required this.onSongTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
          _buildHeaderRow(colors),
          if (isExpanded) ...[
            Divider(height: 1, color: colors.listDivider),
            _buildSongList(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AbstractThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppDimens.cardRadius),
              bottom: isExpanded ? Radius.zero : const Radius.circular(AppDimens.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
              child: Row(
                children: [
                  _buildAvatar(colors),
                  const SizedBox(width: 12),
                  Expanded(child: _buildArtistInfo(colors)),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppDimens.animXFast,
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Icon(Icons.edit_rounded, size: 16, color: colors.activate),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistInfo(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.artistName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'total_songs'.tr(args: ['${entry.songs.length}']),
          style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
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
          errorWidget: (_, __, ___) => _avatarPlaceholder(size, colors),
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
      child: Icon(Icons.person_rounded, size: size * 0.55, color: colors.textSecondary),
    );
  }

  Widget _buildSongList(AbstractThemeColors colors) {
    if (entry.songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Text(
          'no_setlist'.tr(),
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      );
    }
    return Column(
      children: entry.songs.asMap().entries.map((e) => _buildSongRow(e.value, e.key, colors)).toList(),
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
                style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500),
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
                  errorWidget: (_, __, ___) => _thumbPlaceholder(colors),
                ),
              )
            else
              _thumbPlaceholder(colors),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                song.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textTitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded, size: 13, color: colors.textSecondary),
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
      child: Icon(Icons.music_note_rounded, size: 16, color: colors.textSecondary),
    );
  }
}

// 카드뷰와 전체보기 페이지 양쪽에서 사용하는 셋리스트 편집 바텀시트
class SetlistEditSheet extends StatefulWidget {
  final int festivalId;
  final FestivalSetlistEntry entry;

  const SetlistEditSheet({super.key, required this.festivalId, required this.entry});

  @override
  State<SetlistEditSheet> createState() => _SetlistEditSheetState();
}

class _SetlistEditSheetState extends State<SetlistEditSheet> {
  late Future<List<SongModel>> _songsFuture;
  late Set<int> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.entry.songIds;
    _songsFuture = sl<SongService>().fetchSongs(widget.entry.artistId);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await sl<FestivalDetailService>().updateSetlist(
        widget.festivalId,
        widget.entry.artistFestivalId,
        _selectedIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('setlist_saved'.tr())),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[Setlist] 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('setlist_save_failed'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const BottomSheetHandle(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.entry.artistName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textTitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'edit_setlist'.tr(),
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'select_songs_hint'.tr(),
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildSongList(colors, controller)),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(AbstractThemeColors colors, ScrollController controller) {
    return FutureBuilder<List<SongModel>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('err_fetch_data'.tr(), style: TextStyle(color: colors.textSecondary)),
          );
        }
        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return Center(
            child: Text('no_setlist'.tr(), style: TextStyle(color: colors.textSecondary)),
          );
        }
        return ListView.separated(
          controller: controller,
          itemCount: songs.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: colors.listDivider, indent: 16, endIndent: 16),
          itemBuilder: (_, i) {
            final song = songs[i];
            final checked = _selectedIds.contains(song.id);
            return CheckboxListTile(
              value: checked,
              onChanged: (_) => setState(() {
                if (checked) {
                  _selectedIds.remove(song.id);
                } else {
                  _selectedIds.add(song.id);
                }
              }),
              activeColor: colors.activate,
              checkColor: colors.surface,
              title: Text(
                song.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textTitle),
              ),
              secondary: song.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailUrl!,
                        width: 40,
                        height: 40,
                        memCacheWidth: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _thumbPlaceholder(colors),
                      ),
                    )
                  : _thumbPlaceholder(colors),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            );
          },
        );
      },
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
                onPressed: _saving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.activate),
                  foregroundColor: colors.activate,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('cancel'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoadingButton(
                label: 'save'.tr(),
                onPressed: _save,
                isLoading: _saving,
                backgroundColor: colors.activate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(AbstractThemeColors colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      ),
      child: Icon(Icons.music_note_rounded, size: 16, color: colors.textSecondary),
    );
  }
}
