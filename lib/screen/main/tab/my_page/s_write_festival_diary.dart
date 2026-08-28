import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/app_input_border.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_diary_model.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/service/festival_diary_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:feple/common/util/responsive_size.dart';

class WriteFestivalDiaryScreen extends StatefulWidget {
  final FestivalDiaryModel? existing;

  const WriteFestivalDiaryScreen({super.key, this.existing});

  @override
  State<WriteFestivalDiaryScreen> createState() => _WriteFestivalDiaryScreenState();
}

class _WriteFestivalDiaryScreenState extends State<WriteFestivalDiaryScreen> {
  static const _maxPhotos = 5;

  final _diaryService = sl<FestivalDiaryService>();
  final _contentController = TextEditingController();
  final List<Uint8List> _selectedImages = [];

  bool get _isEditMode => widget.existing != null;

  FestivalModel? _selectedFestival;
  List<FestivalModel> _festivals = [];
  bool _loadingFestivals = false;
  DiaryVisibility _visibility = DiaryVisibility.private_;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _contentController.text = widget.existing!.content;
      _visibility = widget.existing!.visibility;
    } else {
      _loadFestivals();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadFestivals() async {
    setState(() => _loadingFestivals = true);
    try {
      final festivals = await sl<FestivalService>().fetchAll();
      if (mounted) setState(() { _festivals = festivals; _loadingFestivals = false; });
    } catch (e) {
      debugPrint('[WriteDiary] 페스티벌 목록 로드 실패: $e');
      if (mounted) setState(() => _loadingFestivals = false);
    }
  }

  Future<void> _showFestivalSearchSheet() async {
    final result = await showAppBottomSheet<FestivalModel>(
      context,
      builder: (_) => _DiaryFestivalSearchSheet(festivals: _festivals),
    );
    if (mounted && result != null) setState(() => _selectedFestival = result);
  }

  Future<void> _pickImages() async {
    final remaining = _maxPhotos - _selectedImages.length;
    if (remaining <= 0) {
      context.showErrorSnackbar('diary_max_photos'.tr(args: ['$_maxPhotos']));
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(maxWidth: 1080, imageQuality: 85, limit: remaining);
      if (picked.isEmpty) return;
      final toAdd = picked.take(remaining).toList();
      final bytesList = await Future.wait(toAdd.map((x) => x.readAsBytes()));
      if (!mounted) return;
      setState(() => _selectedImages.addAll(bytesList));
      if (picked.length > remaining) {
        context.showErrorSnackbar('diary_max_photos'.tr(args: ['$_maxPhotos']));
      }
    } on PlatformException catch (e) {
      debugPrint('[WriteDiary] image pick error: $e');
      if (mounted) context.showErrorSnackbar('photo_pick_failed'.tr());
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      context.showInfoSnackbar('diary_content_required_msg'.tr());
      return;
    }
    if (!_isEditMode && _selectedFestival == null) {
      context.showInfoSnackbar('select_festival_required_msg'.tr());
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isEditMode) {
        await _diaryService.update(widget.existing!.id, content, _visibility);
      } else {
        await _diaryService.create(
          festivalId: _selectedFestival!.id,
          content: content,
          visibility: _visibility,
          images: _selectedImages,
        );
      }
      if (!mounted) return;
      context.showSuccessSnackbar((_isEditMode ? 'diary_edit_success' : 'diary_write_success').tr());
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[WriteDiary] submit error: $e');
      if (!mounted) return;
      context.showErrorSnackbar(networkAwareErrorKey(e, 'diary_submit_failed').tr());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildVisibilityToggle(AbstractThemeColors colors) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _visibility == DiaryVisibility.public_,
      onChanged: (v) => setState(
        () => _visibility = v ? DiaryVisibility.public_ : DiaryVisibility.private_,
      ),
      activeThumbColor: colors.activate,
      title: Text(
        'diary_visibility_public'.tr(),
        style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textTitle),
      ),
      subtitle: Text(
        'diary_visibility_hint'.tr(),
        style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildFestivalSelector(AbstractThemeColors colors) {
    if (_isEditMode) {
      return Text(
        widget.existing!.displayFestivalTitle(context.isEnglish),
        style: TextStyle(fontSize: AppDimens.fontSizeLg, fontWeight: FontWeight.w700, color: colors.textTitle),
      );
    }
    if (_loadingFestivals) {
      return const SkeletonBox(height: 50, borderRadius: BorderRadius.all(Radius.circular(AppDimens.cardRadiusTiny)));
    }
    return InkWell(
      onTap: _showFestivalSearchSheet,
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'tab_concert'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: _selectedFestival == null,
        child: Text(
          _selectedFestival?.displayTitle(context.isEnglish) ?? '',
          style: const TextStyle(fontSize: AppDimens.fontSizeMd),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(
    AbstractThemeColors colors, {
    required Widget preview,
    VoidCallback? onRemove,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(AppDimens.radiusSmall), child: preview),
          if (onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 3)],
                  ),
                  child: Icon(Icons.close_rounded, size: 15, color: colors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile(AbstractThemeColors colors, double size) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: colors.listDivider),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        child: Icon(Icons.add_photo_alternate_outlined, color: colors.textSecondary, size: 32),
      ),
    );
  }

  Widget _buildImagePicker(AbstractThemeColors colors) {
    final size = ResponsiveSize(context).w(72);
    if (_isEditMode) {
      if (widget.existing!.photoUrls.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: size,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.existing!.photoUrls.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space12),
          itemBuilder: (_, i) => _buildImageThumbnail(
            colors,
            size: size,
            preview: AppNetworkImage(imageUrl: widget.existing!.photoUrls[i], width: size, height: size),
          ),
        ),
      );
    }
    final tiles = <Widget>[
      for (var i = 0; i < _selectedImages.length; i++)
        _buildImageThumbnail(
          colors,
          size: size,
          preview: Image.memory(_selectedImages[i], fit: BoxFit.cover, width: size, height: size),
          onRemove: () => setState(() => _selectedImages.removeAt(i)),
        ),
      if (_selectedImages.length < _maxPhotos) _buildAddImageTile(colors, size),
    ];
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space12),
        itemBuilder: (_, i) => tiles[i],
      ),
    );
  }

  Widget _buildSubmitAction() {
    return SizedBox(
      width: 64,
      child: TextButton(
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.appColors.appBarIconColor),
                ),
              )
            : Text(
                'done'.tr(),
                style: TextStyle(color: context.appColors.appBarIconColor, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (_isSubmitting) return;
    final ctx = context;
    final confirmed = await showConfirmDialog(
      ctx,
      title: 'discard_changes'.tr(),
      content: 'discard_changes_msg'.tr(),
      confirmLabel: 'discard'.tr(),
    );
    if (confirmed && ctx.mounted) Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: Scaffold(
        backgroundColor: colors.backgroundMain,
        body: Column(
          children: [
            SecondaryAppBar(
              title: (_isEditMode ? 'diary_edit' : 'diary_write').tr(),
              actions: [_buildSubmitAction()],
              onBackPressed: () => _onPopInvoked(false),
            ),
            Expanded(
              child: KeyboardDismiss(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFestivalSelector(colors),
                        const SizedBox(height: AppDimens.space12),
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          minLines: 8,
                          maxLength: 2000,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(color: colors.textTitle),
                          decoration: InputDecoration(
                            hintText: 'diary_content_hint'.tr(),
                            hintStyle: TextStyle(color: colors.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
                            focusedBorder: appInputBorder(colors.activate, width: 2),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space8),
                        _buildImagePicker(colors),
                        _buildVisibilityToggle(colors),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryFestivalSearchSheet extends StatefulWidget {
  final List<FestivalModel> festivals;

  const _DiaryFestivalSearchSheet({required this.festivals});

  @override
  State<_DiaryFestivalSearchSheet> createState() => _DiaryFestivalSearchSheetState();
}

class _DiaryFestivalSearchSheetState extends State<_DiaryFestivalSearchSheet> {
  late List<FestivalModel> _filtered;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filtered = widget.festivals;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppDimens.animXFast, () {
      if (mounted) {
        setState(() {
          _filtered = widget.festivals
              .where((f) =>
                  f.title.toLowerCase().contains(query.toLowerCase()) ||
                  f.titleEn.toLowerCase().contains(query.toLowerCase()))
              .toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Material(
          color: colors.backgroundMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: AppDimens.space12),
              const BottomSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'festival_search_hint'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? EmptyState(icon: Icons.search_off_rounded, title: 'search_no_result'.tr())
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: _filtered.length,
                        itemBuilder: (_, index) {
                          final festival = _filtered[index];
                          return ListTile(
                            title: Text(
                              festival.displayTitle(context.isEnglish),
                              style: const TextStyle(fontSize: AppDimens.fontSizeMd),
                            ),
                            onTap: () => Navigator.pop(ctx, festival),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
