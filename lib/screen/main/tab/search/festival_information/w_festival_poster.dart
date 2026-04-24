import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import '../../../../../model/festival_model.dart';
import 'festival_poster_notifier.dart';
import 'w_certification_bottom_sheet.dart';

class FestivalPoster extends StatefulWidget {
  const FestivalPoster({super.key, required this.poster});

  final FestivalModel poster;

  @override
  State<FestivalPoster> createState() => _FestivalPosterState();
}

class _FestivalPosterState extends State<FestivalPoster> {
  late final FestivalPosterNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = FestivalPosterNotifier(
      festivalId: widget.poster.id,
      certService: sl<CertificationService>(),
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

    if (lat != null && lng != null) {
      final appUri = Uri.parse('kakaomap://look?p=$lat,$lng');
      final webUri =
          Uri.parse('https://map.kakao.com/link/map/$name,$lat,$lng');
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } else {
      final webUri = Uri.parse('https://map.kakao.com/link/search/$name');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitCertification() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CertificationBottomSheet(
        festivalName: widget.poster.title,
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
        const double appBarHeight = AppDimens.appBarHeight;
        final hasDescription = widget.poster.description.isNotEmpty;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRect(
                child: CachedNetworkImage(
                  imageUrl: widget.poster.posterUrl,
                  memCacheWidth: 100,
                  fit: BoxFit.cover,
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
              bottom: -5,
              child: ColoredBox(
                color: colors.swiperOverlay.withValues(alpha: 0.55),
              ),
            ),
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(top: appBarHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      colors.cardShadow.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: widget.poster.posterUrl,
                                memCacheWidth: 300,
                                fit: BoxFit.fill,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  widget.poster.title,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded,
                                        color: colors.accentColor, size: 15),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.poster.endDate.isNotEmpty
                                            ? '${widget.poster.startDate} ~ ${widget.poster.endDate}'
                                            : widget.poster.startDate,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _openKakaoMap,
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          color: colors.accentColor, size: 15),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.poster.location,
                                          softWrap: true,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _ActionButton(
                                      onTap: _notifier.toggleLike,
                                      icon: _notifier.liked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: _notifier.liked
                                          ? Colors.pink[200]!
                                          : Colors.white,
                                      bgColor: _notifier.liked
                                          ? Colors.pink.withValues(alpha: 0.35)
                                          : Colors.white
                                              .withValues(alpha: 0.15),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.calendar_month_outlined,
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      onTap: _openKakaoMap,
                                      icon: Icons.location_on_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      onTap: _notifier.isCertified
                                          ? () => Fluttertoast.showToast(
                                              msg: context
                                                  .tr('cert_already_approved'))
                                          : _notifier.isPending
                                              ? () => Fluttertoast.showToast(
                                                  msg: context
                                                      .tr('cert_pending_notice'))
                                              : _submitCertification,
                                      icon: _notifier.isPending
                                          ? Icons.hourglass_top_rounded
                                          : Icons.verified_rounded,
                                      color: _notifier.isCertified
                                          ? Colors.lightBlueAccent
                                          : _notifier.isPending
                                              ? Colors.amber
                                              : Colors.white,
                                      bgColor: _notifier.isCertified
                                          ? Colors.blue.withValues(alpha: 0.35)
                                          : _notifier.isPending
                                              ? Colors.amber
                                                  .withValues(alpha: 0.25)
                                              : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasDescription) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      GestureDetector(
                        onTap: _notifier.toggleDesc,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 10, 16, 4),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'festival_info'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _notifier.descExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color:
                                    Colors.white.withValues(alpha: 0.5),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: Text(
                            widget.poster.description,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.6,
                              color:
                                  Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        secondChild: const SizedBox(height: 10),
                        crossFadeState: _notifier.descExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
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
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color? color;
  final Color? bgColor;

  const _ActionButton({
    this.onTap,
    required this.icon,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 20),
      ),
    );
  }
}
