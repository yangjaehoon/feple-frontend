import 'dart:ui';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/provider/like_notifier.dart';
import 'package:feple/service/certification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../../../model/festival_model.dart';

class FestivalPoster extends StatefulWidget {
  const FestivalPoster({super.key, required this.poster});

  final FestivalModel poster;

  @override
  State<FestivalPoster> createState() => _FestivalPosterState();
}

class _FestivalPosterState extends State<FestivalPoster> {
  bool _liked = false;
  bool _descExpanded = true;
  bool _certSubmitting = false;
  final _certService = CertificationService();

  String get _descPrefKey => 'festival_desc_expanded_${widget.poster.id}';

  @override
  void initState() {
    super.initState();
    _loadLikeState();
    _loadDescState();
  }

  Future<void> _loadDescState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_descPrefKey);
    if (saved != null && mounted) {
      setState(() => _descExpanded = saved);
    }
  }

  Future<void> _saveDescState(bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_descPrefKey, expanded);
  }

  Future<void> _loadLikeState() async {
    try {
      final resp =
          await DioClient.dio.get('/festivals/${widget.poster.id}/liked');
      if (mounted) setState(() => _liked = resp.data as bool);
    } catch (e) {
      debugPrint('loadLikeState error: $e');
    }
  }

  Future<void> _openKakaoMap() async {
    final lat = widget.poster.latitude;
    final lng = widget.poster.longitude;
    final name = Uri.encodeComponent(widget.poster.location);

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
  }

  Future<void> _submitCertification() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CertificationBottomSheet(
        festivalName: widget.poster.title,
        festivalId: widget.poster.id,
        certService: _certService,
      ),
    );
  }

  Future<void> _toggleLike() async {
    try {
      final resp =
          await DioClient.dio.post('/festivals/${widget.poster.id}/like');
      if (mounted) {
        setState(() => _liked = resp.data as bool);
        context.read<LikeNotifier>().notifyLikeChanged();
      }
    } catch (e) {
      debugPrint('toggleLike error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const double appBarHeight = AppDimens.appBarHeight;
    final hasDescription = widget.poster.description.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 레이어 1: 배경 이미지 (Stack 크기에 딱 맞게)
        Positioned.fill(
          child: ClipRect(
            child: CachedNetworkImage(
              imageUrl: widget.poster.posterUrl,
              memCacheWidth: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // 레이어 2: 블러 필터 (Stack 크기에 딱 맞게)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox.expand(),
          ),
        ),
        // 레이어 3: 하늘색 오버레이 (블러 하단 경계를 덮기 위해 10px 더 연장)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: -5,
          child: ColoredBox(
            color: colors.swiperOverlay.withValues(alpha: 0.55),
          ),
        ),
        // 콘텐츠
        SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(top: appBarHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 포스터 + 타이틀 정보 영역
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 포스터 이미지
                      Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.cardShadow.withValues(alpha: 0.3),
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
                      // 타이틀 + 날짜 + 장소 + 버튼
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
                                        fontSize: 14, color: Colors.white70),
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
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // 액션 버튼들
                            Row(
                              children: [
                                _ActionButton(
                                  onTap: _toggleLike,
                                  icon: _liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: _liked ? Colors.pink[200]! : Colors.white,
                                  bgColor: _liked
                                      ? Colors.pink.withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.15),
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
                                  onTap: _certSubmitting ? null : _submitCertification,
                                  icon: _certSubmitting
                                      ? Icons.hourglass_top_rounded
                                      : Icons.verified_rounded,
                                  color: _certSubmitting ? Colors.white54 : Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 설명 영역 (접기/펼치기)
                if (hasDescription) ...[
                  // 구분선
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  // 설명 헤더 + 접기 버튼
                  GestureDetector(
                    onTap: () {
                      setState(() => _descExpanded = !_descExpanded);
                      _saveDescState(_descExpanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'festival_info'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _descExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 설명 텍스트
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                      child: Text(
                        widget.poster.description,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    secondChild: const SizedBox(height: 10),
                    crossFadeState: _descExpanded
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

class _CertificationBottomSheet extends StatefulWidget {
  final String festivalName;
  final int festivalId;
  final CertificationService certService;

  const _CertificationBottomSheet({
    required this.festivalName,
    required this.festivalId,
    required this.certService,
  });

  @override
  State<_CertificationBottomSheet> createState() =>
      _CertificationBottomSheetState();
}

class _CertificationBottomSheetState extends State<_CertificationBottomSheet> {
  XFile? _pickedFile;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked != null) setState(() => _pickedFile = picked);
  }

  Future<void> _submit() async {
    if (_pickedFile == null) return;
    setState(() => _submitting = true);
    try {
      final imageData = await _pickedFile!.readAsBytes();
      await widget.certService.submit(
        festivalId: widget.festivalId,
        imageData: imageData,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'cert_submit_success'.tr());
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      Fluttertoast.showToast(
        msg: msg.contains('이미') || msg.contains('already')
            ? 'cert_already_submitted'.tr()
            : 'cert_submit_failed'.tr(args: [msg]),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 타이틀
          Row(
            children: [
              Icon(Icons.verified_rounded, color: colors.activate, size: 22),
              const SizedBox(width: 8),
              Text(
                'cert_title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 안내 문구
          Text(
            'cert_description'.tr(args: [widget.festivalName]),
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // 사진 첨부 영역
          GestureDetector(
            onTap: _submitting ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: colors.backgroundMain,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _pickedFile != null
                      ? colors.activate
                      : colors.textSecondary.withValues(alpha: 0.2),
                  width: _pickedFile != null ? 2 : 1,
                ),
              ),
              child: _pickedFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FutureBuilder<Uint8List>(
                        future: _pickedFile!.readAsBytes(),
                        builder: (ctx, snap) {
                          if (snap.hasData) {
                            return Image.memory(snap.data!, fit: BoxFit.cover);
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 36, color: colors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'cert_photo_hint'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // 제출 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_pickedFile == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.activate,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.activate.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Text(
                      'cert_submit'.tr(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
