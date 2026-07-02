import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_report_sheet.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/report_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/popup_menu_item_builder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'artist_photo_notifier.dart';
import 'w_edit_photo_sheet.dart';
import 'w_photo_fullscreen_viewer.dart';

class ImgCollectionWidget extends StatefulWidget {
  const ImgCollectionWidget(
      {super.key, required this.artistId, required this.artistName});

  final int artistId;
  final String artistName;

  @override
  State<ImgCollectionWidget> createState() => ImgCollectionWidgetState();
}

class ImgCollectionWidgetState extends State<ImgCollectionWidget> {
  late final ArtistPhotoNotifier _notifier;
  final _reportService = sl<ReportService>();
  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _notifier = ArtistPhotoNotifier(artistId: widget.artistId);
    _notifier.addListener(_onNotifierChange);
    _notifier.loadPhotos();
  }

  void _onNotifierChange() {
    final key = _notifier.errorKey;
    if (key != null && mounted) {
      context.showErrorSnackbar(key.tr());
      _notifier.clearError();
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotifierChange);
    _notifier.dispose();
    super.dispose();
  }

  void refresh() => _notifier.loadPhotos();

  Future<void> _confirmAndDelete(int photoId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'photo_delete_title'.tr(),
      content: 'photo_delete_confirm'.tr(),
      confirmLabel: 'msg_delete'.tr(),
    );
    if (confirmed) _notifier.deletePhoto(photoId);
  }


  void _showEditBottomSheet(ArtistPhotoResponse photo) {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    showAppBottomSheet(
      context,
      useRootNavigator: true,
      builder: (_) => EditPhotoSheet(
        artistId: widget.artistId,
        photo: photo,
        onSave: (newTitle, newDesc) =>
            _notifier.updatePhoto(photo.photoId, newTitle, newDesc),
      ),
    ).whenComplete(() { if (mounted) _isSheetOpen = false; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final currentUserId =
        Provider.of<UserProvider>(context, listen: false).currentUserId;

    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) => _buildContent(colors, currentUserId),
    );
  }

  Widget _buildContent(AbstractThemeColors colors, int? currentUserId) {
    if (_notifier.isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: CircularProgressIndicator(color: colors.loadingIndicator),
          ),
        ),
      );
    }

    if (_notifier.photos.isEmpty) {
      return _buildEmptyState();
    }

    return SliverList.builder(
      itemCount: _notifier.photos.length,
      itemBuilder: (context, index) {
        final photo = _notifier.photos[index];
        final isUploader =
            currentUserId != null && photo.uploaderUserId == currentUserId;
        return Padding(
          padding: EdgeInsets.only(
              bottom: index == _notifier.photos.length - 1 ? 0 : 12.0),
          child: _buildPhotoCard(photo, isUploader, colors),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'photo_no_photos'.tr(),
      ),
    );
  }

  Widget _buildPhotoCard(
      ArtistPhotoResponse photo, bool isUploader, AbstractThemeColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = (constraints.maxWidth * 0.44).clamp(0.0, 195.0);
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
            boxShadow: [
              BoxShadow(
                  color: colors.cardShadow.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              _buildPhotoImageArea(photo, colors, imageSize),
              Expanded(child: _buildPhotoInfoArea(photo, isUploader, colors, imageSize)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoImageArea(ArtistPhotoResponse photo, AbstractThemeColors colors, double imageSize) {
    return Stack(
      children: [
        _buildPhoto(photo, colors, imageSize),
        _buildLikeOverlay(photo, colors),
      ],
    );
  }

  void _openFullscreen(ArtistPhotoResponse photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoFullscreenViewer(
          photo: photo,
          onLike: () => _notifier.toggleLike(photo.photoId),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildPhoto(ArtistPhotoResponse photo, AbstractThemeColors colors, double imageSize) {
    return GestureDetector(
      onTap: () => _openFullscreen(photo),
      onDoubleTap: () => _notifier.toggleLike(photo.photoId),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: CachedNetworkImage(
          imageUrl: photo.url,
          cacheKey: 'artist-photo-${photo.photoId}',
          width: imageSize,
          height: imageSize,
          memCacheWidth: (imageSize * 2).round(),
          fit: BoxFit.cover,
          fadeInDuration: AppDimens.animXFast,
          fadeOutDuration: AppDimens.animTapFeedback,
          // CircularProgressIndicator는 매 프레임 repaint — 리스트에서 스피너가
          // 여러 개 동시에 애니메이션되면 GPU 부담 증가 → SkeletonBox로 교체
          placeholder: (context, url) => SkeletonBox(
            width: imageSize,
            height: imageSize,
          ),
          errorWidget: (context, url, error) => Container(
            width: imageSize,
            height: imageSize,
            color: colors.listDivider,
            child: Icon(Icons.broken_image_rounded, color: colors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildLikeOverlay(ArtistPhotoResponse photo, AbstractThemeColors colors) {
    return Positioned(
      left: 6,
      bottom: 6,
      child: GestureDetector(
        onTap: () => _notifier.toggleLike(photo.photoId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                photo.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: photo.isLiked ? colors.likeActiveColor : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${photo.likeCount}',
                style: const TextStyle(
                    fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoInfoArea(
      ArtistPhotoResponse photo, bool isUploader, AbstractThemeColors colors, double imageSize) {
    return SizedBox(
      height: imageSize,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPhotoHeader(photo, isUploader, colors),
            _buildPhotoMeta(photo, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoHeader(ArtistPhotoResponse photo, bool isUploader, AbstractThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            photo.title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppDimens.fontSizeXl,
                color: colors.textTitle),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildPhotoMenu(photo, isUploader, colors),
      ],
    );
  }

  Widget _buildPhotoMeta(ArtistPhotoResponse photo, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (photo.isAnonymous)
              _buildBadge(Icons.visibility_off_rounded, 'post_anonymous'.tr(), colors),
            if (photo.isAnonymous && photo.description.isNotEmpty)
              const SizedBox(width: 6),
            if (photo.description.isNotEmpty)
              Flexible(child: _buildDescriptionBadge(photo, colors)),
          ],
        ),
        if (photo.uploaderNickname.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 12, color: colors.textSecondary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    photo.uploaderNickname,
                    style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoMenu(
      ArtistPhotoResponse photo, bool isUploader, AbstractThemeColors colors) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 20),
      color: colors.surface,
      elevation: 6,
      shadowColor: colors.cardShadow.withValues(alpha: 0.18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'edit') {
          _showEditBottomSheet(photo);
        } else if (value == 'delete') {
          _confirmAndDelete(photo.photoId);
        } else if (value == 'report') {
          showReportSheet(
            context,
            titleKey: 'report_photo',
            onSubmit: (reason, detail) => _reportService.submitPhotoReport(
              widget.artistId,
              photo.photoId,
              reason,
              detail: detail,
            ),
            duplicateErrorKey: 'report_photo_duplicate',
          );
        }
      },
      itemBuilder: (_) => [
        if (isUploader) ...[
          buildPopupMenuItem(
            value: 'edit',
            icon: Icons.edit_rounded,
            label: 'photo_edit_action'.tr(),
            colors: colors,
          ),
          const PopupMenuDivider(height: 1),
          buildPopupMenuItem(
            value: 'delete',
            icon: Icons.delete_rounded,
            label: 'msg_delete'.tr(),
            colors: colors,
            danger: true,
          ),
        ] else
          buildPopupMenuItem(
            value: 'report',
            icon: Icons.flag_rounded,
            label: 'report_photo'.tr(),
            colors: colors,
            danger: true,
          ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, AbstractThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: colors.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBadge(ArtistPhotoResponse photo, AbstractThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.activate.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Text(
        photo.description,
        style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: colors.activate),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
