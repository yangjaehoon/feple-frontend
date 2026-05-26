import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FestivalSetlist extends StatefulWidget {
  final int festivalId;

  const FestivalSetlist({super.key, required this.festivalId});

  @override
  State<FestivalSetlist> createState() => _FestivalSetlistState();
}

class _FestivalSetlistState extends State<FestivalSetlist> {
  late Future<List<FestivalSetlistEntry>> _future;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<FestivalSetlistEntry>> _fetch() =>
      sl<FestivalService>().fetchSetlist(widget.festivalId);

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
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetlistEditSheet(
        festivalId: widget.festivalId,
        entry: entry,
      ),
    );
    if (result == true && mounted) {
      setState(() => _future = _fetch());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: AppDimens.paddingVertical,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: AppDimens.cardRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          _buildContent(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Icon(Icons.queue_music_rounded, size: 15, color: colors.activate),
          const SizedBox(width: 8),
          Text(
            'setlist'.tr(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    return FutureBuilder<List<FestivalSetlistEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ErrorState(
              message: 'err_fetch_data'.tr(args: ['']),
              onRetry: () => setState(() { _future = _fetch(); }),
            ),
          );
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EmptyState(icon: Icons.queue_music_rounded, title: 'no_setlist'.tr()),
          );
        }
        return _buildList(entries, colors);
      },
    );
  }

  Widget _buildList(List<FestivalSetlistEntry> entries, AbstractThemeColors colors) {
    return Column(
      children: entries.asMap().entries.map((e) {
        final idx = e.key;
        final entry = e.value;
        final isLast = idx == entries.length - 1;
        return _ArtistSetlistTile(
          entry: entry,
          isExpanded: _expanded.contains(entry.artistId),
          isLast: isLast,
          colors: colors,
          onToggle: () => setState(() {
            if (_expanded.contains(entry.artistId)) {
              _expanded.remove(entry.artistId);
            } else {
              _expanded.add(entry.artistId);
            }
          }),
          onSongTap: _openYoutubeMusic,
          onEdit: () => _openEditSheet(entry),
        );
      }).toList(),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SkeletonBox(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(18))),
              const SizedBox(width: 12),
              const Expanded(child: SkeletonBox(height: 14)),
            ],
          ),
        );
      }),
    );
  }
}

class _ArtistSetlistTile extends StatelessWidget {
  final FestivalSetlistEntry entry;
  final bool isExpanded;
  final bool isLast;
  final AbstractThemeColors colors;
  final VoidCallback onToggle;
  final void Function(String url) onSongTap;
  final VoidCallback onEdit;

  const _ArtistSetlistTile({
    required this.entry,
    required this.isExpanded,
    required this.isLast,
    required this.colors,
    required this.onToggle,
    required this.onSongTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.vertical(
                  bottom: isLast && !isExpanded ? const Radius.circular(AppDimens.cardRadius) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                  child: Row(
                    children: [
                      _buildArtistAvatar(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.artistName,
                          style: TextStyle(
                            fontSize: AppDimens.fontSizeMd,
                            fontWeight: FontWeight.w600,
                            color: colors.textTitle,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.songs.length}',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: AppDimens.animXFast,
                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Icon(Icons.edit_rounded, size: 16, color: colors.activate),
              ),
            ),
          ],
        ),
        if (isExpanded) _buildSongList(),
        if (!isLast)
          Divider(thickness: 1, color: colors.listDivider, indent: 16, endIndent: 16, height: 1),
      ],
    );
  }

  Widget _buildArtistAvatar() {
    const size = 36.0;
    if (entry.profileImageUrl != null && entry.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: entry.profileImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _avatarPlaceholder(size),
        ),
      );
    }
    return _avatarPlaceholder(size);
  }

  Widget _avatarPlaceholder(double size) {
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

  Widget _buildSongList() {
    return Column(
      children: entry.songs.asMap().entries.map((e) {
        return _SongRow(
          index: e.key + 1,
          song: e.value,
          colors: colors,
          onTap: () => onSongTap(e.value.youtubeUrl),
        );
      }).toList(),
    );
  }
}

class _SetlistEditSheet extends StatefulWidget {
  final int festivalId;
  final FestivalSetlistEntry entry;

  const _SetlistEditSheet({required this.festivalId, required this.entry});

  @override
  State<_SetlistEditSheet> createState() => _SetlistEditSheetState();
}

class _SetlistEditSheetState extends State<_SetlistEditSheet> {
  late Future<List<SongModel>> _songsFuture;
  late Set<int> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.entry.songs.map((s) => s.id).toSet();
    _songsFuture = sl<SongService>().fetchSongs(widget.entry.artistId);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await sl<FestivalService>().updateSetlist(
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
    } catch (_) {
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
                  Text(
                    widget.entry.artistName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textTitle,
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Text('no_setlist'.tr(), style: TextStyle(color: colors.textSecondary)),
          );
        }
        final songs = snapshot.data!;
        return ListView.separated(
          controller: controller,
          itemCount: songs.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: colors.listDivider,
            indent: 16,
            endIndent: 16,
          ),
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
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _songThumbnailPlaceholder(colors),
                      ),
                    )
                  : _songThumbnailPlaceholder(colors),
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

  Widget _songThumbnailPlaceholder(AbstractThemeColors colors) {
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

class _SongRow extends StatelessWidget {
  final int index;
  final SongModel song;
  final AbstractThemeColors colors;
  final VoidCallback onTap;

  const _SongRow({
    required this.index,
    required this.song,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (song.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _thumbnailPlaceholder(),
                ),
              )
            else
              _thumbnailPlaceholder(),
            const SizedBox(width: 12),
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
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded, size: 13, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
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
