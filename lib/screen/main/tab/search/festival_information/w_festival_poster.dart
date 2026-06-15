import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../model/cert_state.dart';
import '../../../../../model/festival_model.dart';
import 'festival_poster_notifier.dart';
import 'festival_poster_style.dart';
import 'w_certification_bottom_sheet.dart';
import 'w_festival_action_button.dart';
import 'w_weather_bottom_sheet.dart';

class FestivalPoster extends StatefulWidget {
  const FestivalPoster({super.key, required this.poster, this.heroTag});

  final FestivalModel poster;
  final String? heroTag;

  @override
  State<FestivalPoster> createState() => _FestivalPosterState();
}

class _FestivalPosterState extends State<FestivalPoster> {
  static const double _posterThumbnailWidth = 120.0;
  static const double _posterThumbnailHeight = 160.0;

  late final FestivalPosterNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = FestivalPosterNotifier(
      festivalId: widget.poster.id,
      certService: sl<CertificationService>(),
      festivalService: sl<FestivalInteractionService>(),
      attendingCount: widget.poster.attendingCount,
    );
    _notifier.init();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _openKakaoMap() async {
    final lat = widget.poster.latitude;
    final lng = widget.poster.longitude;
    final name = Uri.encodeComponent(widget.poster.location);
    try {
      if (lat != null && lng != null) {
        final appUri = Uri.parse('kakaomap://look?p=$lat,$lng');
        final webUri = Uri.parse('https://map.kakao.com/link/map/$name,$lat,$lng');
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri);
        } else {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      } else {
        final webUri = Uri.parse('https://map.kakao.com/link/search/$name');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('map launch error: $e');
      if (mounted) context.showErrorSnackbar('map_open_failed'.tr());
    }
  }

  void _withHaptic(VoidCallback fn) {
    HapticFeedback.lightImpact();
    fn();
  }

  void _shareFestival() {
    Share.share('${widget.poster.displayTitle(context.locale.languageCode == 'en')}\n${widget.poster.location}\n${widget.poster.startDate}');
  }

  void _showWeather() {
    showAppBottomSheet(
      context,
      isScrollControlled: false,
      builder: (_) => WeatherBottomSheet(
        festivalId: widget.poster.id,
        startDate: widget.poster.startDate,
        endDate: widget.poster.endDate,
      ),
    );
  }

  VoidCallback? _certButtonTap() => switch (_notifier.certState) {
        CertState.certified => () => context.showInfoSnackbar('cert_already_approved'.tr()),
        CertState.pending   => () => context.showInfoSnackbar('cert_pending_notice'.tr()),
        CertState.none      => _submitCertification,
      };

  IconData _certButtonIcon() => _notifier.certState.icon;

  Color _certButtonColor(AbstractThemeColors colors) => _notifier.certState.color(colors);

  Color? _certButtonBgColor(AbstractThemeColors colors) => _notifier.certState.bgColor(colors);

  Future<void> _submitCertification() async {
    await showAppBottomSheet(
      context,
      builder: (ctx) => CertificationBottomSheet(
        festivalName: widget.poster.displayTitle(context.locale.languageCode == 'en'),
        festivalId: widget.poster.id,
        certService: sl<CertificationService>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final colors = context.appColors;
        final hasDescription = widget.poster.description.isNotEmpty;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ..._buildBackground(colors),
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppDimens.appBarHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoRow(colors),
                    if (hasDescription) ..._buildDescriptionSection(colors),
                    if (!hasDescription) const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildBackground(AbstractThemeColors colors) => [
        Positioned.fill(
          child: ClipRect(
            child: CachedNetworkImage(
              imageUrl: widget.poster.posterUrl,
              memCacheWidth: 100,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black26),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: -5, // Stack 하단 경계의 1px 틈 방지
          child: ColoredBox(color: colors.swiperOverlay.withValues(alpha: 0.55)),
        ),
      ];

  Widget _buildInfoRow(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPosterThumbnail(colors),
          const SizedBox(width: 16),
          Expanded(child: _buildInfoColumn(colors)),
        ],
      ),
    );
  }

  Widget _buildPosterThumbnail(AbstractThemeColors colors) {
    final child = Container(
      width: _posterThumbnailWidth,
      height: _posterThumbnailHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        child: CachedNetworkImage(
          imageUrl: widget.poster.posterUrl,
          memCacheWidth: 300,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SkeletonBox(height: double.infinity),
          errorWidget: (_, __, ___) => Container(
            color: colors.surface,
            child: Icon(Icons.broken_image_rounded, size: 32, color: colors.textSecondary.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
    if (widget.heroTag == null) return child;
    return Hero(tag: widget.heroTag!, child: child);
  }

  Widget _buildInfoColumn(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          widget.poster.displayTitle(context.locale.languageCode == 'en'),
          softWrap: true,
          style: const TextStyle(fontSize: AppDimens.fontSizeTitle, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 8),
        _buildTagRow(),
        const SizedBox(height: 8),
        _buildPosterInfoRow(
          icon: Icons.calendar_today_rounded,
          color: colors.accentColor,
          child: Text(
            widget.poster.endDate.isNotEmpty
                ? '${widget.poster.startDate} ~ ${widget.poster.endDate}'
                : widget.poster.startDate,
            style: const TextStyle(fontSize: AppDimens.fontSizeMd, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _openKakaoMap,
          child: _buildPosterInfoRow(
            icon: Icons.location_on_rounded,
            color: colors.accentColor,
            child: Text(
              widget.poster.location,
              softWrap: true,
              style: const TextStyle(
                fontSize: AppDimens.fontSizeMd,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildAttendingRow(colors),
        if (_notifier.hasInitError) ...[
          const SizedBox(height: 4),
          _buildInitErrorRow(),
        ],
        const SizedBox(height: 12),
        _buildActionButtons(colors),
      ],
    );
  }

  Widget _buildPosterInfoRow({
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildTagRow() {
    final tags = <Widget>[];

    for (final genre in widget.poster.genres) {
      final key = genreI18nKey(genre);
      if (key == null) continue;
      tags.add(_Tag(label: key.tr()));
    }

    final age = widget.poster.ageRestriction;
    if (age != null && age != 'NONE') {
      final key = ageI18nKey(age);
      if (key != null) {
        tags.add(_Tag(label: key.tr(), color: ageDisplayColor(age)));
      }
    }

    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: tags);
  }

  Widget _buildAttendingRow(AbstractThemeColors colors) {
    final count = _notifier.attendingCount;
    final isAttending = _notifier.attending;
    return Row(
      children: [
        Icon(Icons.people_outline_rounded, color: colors.accentColor, size: 14),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            count > 0
                ? 'attending_count'.tr(args: ['$count'])
                : 'attend_toggle'.tr(),
            style: const TextStyle(fontSize: AppDimens.fontSizeSm, color: Colors.white70),
          ),
        ),
        GestureDetector(
          onTap: () => _withHaptic(_notifier.toggleAttending),
          child: AnimatedContainer(
            duration: AppDimens.animFast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isAttending
                  ? colors.accentColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              border: Border.all(
                color: isAttending
                    ? colors.accentColor
                    : Colors.white.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Text(
              'attend_toggle'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                fontWeight: FontWeight.w600,
                color: isAttending ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitErrorRow() {
    return GestureDetector(
      onTap: _notifier.retryInit,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync_problem_rounded, size: 13, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            'retry'.tr(),
            style: const TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: Colors.white54,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AbstractThemeColors colors) {
    return Row(
      children: [
        FestivalActionButton(
          onTap: () => _withHaptic(_notifier.toggleLike),
          icon: _notifier.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _notifier.liked ? colors.likeActiveColor : Colors.white,
          bgColor: _notifier.liked
              ? colors.likeActiveColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.15),
          label: 'action_like'.tr(),
        ),
        const SizedBox(width: 8),
        FestivalActionButton(onTap: _shareFestival, icon: Icons.share_outlined, label: 'action_share'.tr()),
        const SizedBox(width: 8),
        FestivalActionButton(onTap: _showWeather, icon: Icons.cloud_outlined, label: 'action_weather'.tr()),
        const SizedBox(width: 8),
        FestivalActionButton(onTap: _openKakaoMap, icon: Icons.location_on_rounded, label: 'action_map'.tr()),
        const SizedBox(width: 8),
        FestivalActionButton(
          onTap: _certButtonTap(),
          icon: _certButtonIcon(),
          color: _certButtonColor(colors),
          bgColor: _certButtonBgColor(colors),
          label: 'action_cert'.tr(),
        ),
      ],
    );
  }

  List<Widget> _buildDescriptionSection(AbstractThemeColors colors) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
        ),
        GestureDetector(
          onTap: _notifier.toggleDesc,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 6),
                Text(
                  'festival_info'.tr(),
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Icon(
                  _notifier.descExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Text(
              widget.poster.description,
              style: TextStyle(fontSize: AppDimens.fontSizeMd, height: 1.6, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
          secondChild: const SizedBox(height: 10),
          crossFadeState: _notifier.descExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: AppDimens.animFast,
        ),
      ];
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

