import 'package:feple/common/common.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/image_upload_helper.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/app_input_border.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/service/app_review_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:feple/common/util/responsive_size.dart';

class WritePost extends StatefulWidget {
  final String title;
  final Future<void> Function(PostDraft draft) onSubmit;
  final String? initialTitle;
  final String? initialContent;
  final bool showAnonymous;
  final List<String> initialImageUrls;

  const WritePost({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialTitle,
    this.initialContent,
    this.showAnonymous = true,
    this.initialImageUrls = const [],
  });

  @override
  State<WritePost> createState() => _WritePostState();
}

class _WritePostState extends State<WritePost> {
  static const _maxImages = 10; // 백엔드 PostRequestDto.MAX_IMAGES와 동일

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _titleHasBannedWord = false;
  bool _contentHasBannedWord = false;
  bool _anonymous = false;
  final List<Uint8List> _selectedImages = [];
  late List<String> _existingImageUrls;

  int get _totalImageCount => _existingImageUrls.length + _selectedImages.length;

  bool get _isDirty =>
      _titleController.text != (widget.initialTitle ?? '') ||
      _contentController.text != (widget.initialContent ?? '') ||
      _selectedImages.isNotEmpty ||
      !listEquals(_existingImageUrls, widget.initialImageUrls);

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    _existingImageUrls = [...widget.initialImageUrls];
    _titleController.addListener(_clearTitleBannedWord);
    _contentController.addListener(_clearContentBannedWord);
  }

  void _clearTitleBannedWord() {
    if (!mounted) return;
    if (_titleHasBannedWord) setState(() => _titleHasBannedWord = false);
  }

  void _clearContentBannedWord() {
    if (!mounted) return;
    if (_contentHasBannedWord) setState(() => _contentHasBannedWord = false);
  }

  @override
  void dispose() {
    _titleController.removeListener(_clearTitleBannedWord);
    _contentController.removeListener(_clearContentBannedWord);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _totalImageCount;
    if (remaining <= 0) {
      context.showErrorSnackbar('max_images_exceeded'.tr(args: ['$_maxImages']));
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(
        maxWidth: 1080,
        imageQuality: 85,
        limit: remaining,
      );
      if (picked.isEmpty) return;
      final toAdd = picked.take(remaining).toList();
      final bytesList = await Future.wait(toAdd.map((x) => x.readAsBytes()));
      if (!mounted) return;
      setState(() => _selectedImages.addAll(bytesList));
      if (picked.length > remaining) {
        context.showErrorSnackbar('max_images_exceeded'.tr(args: ['$_maxImages']));
      }
    } on PlatformException catch (e) {
      debugPrint('image pick error: $e');
      if (mounted) context.showErrorSnackbar('photo_pick_failed'.tr());
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      final uploaded = await Future.wait(_selectedImages.map(
        (bytes) => ImageUploadHelper.compressAndUpload(
          presignEndpoint: PostService.postImagePresignEndpoint,
          imageData: bytes,
        ),
      ));
      final imageObjectKeys = [
        ..._existingImageUrls,
        ...uploaded.map((p) => p.objectKey),
      ];
      await widget.onSubmit(PostDraft(
        title: title,
        content: content,
        anonymous: _anonymous,
        imageObjectKeys: imageObjectKeys,
      ));
      unawaited(AppReviewService.recordPostCreated());
      if (!mounted) return;
      context.showSuccessSnackbar('post_success'.tr());
      Navigator.of(context).pop();
    } on BannedWordException catch (e) {
      if (!mounted) return;
      setState(() {
        _titleHasBannedWord = e.field == 'title';
        _contentHasBannedWord = e.field == 'content';
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('post submit error: $e');
      context.showErrorSnackbar(networkAwareErrorKey(e, 'post_failed').tr());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration(
    String hintKey, {
    String? bannedWordMessage,
  }) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(AppDimens.cardRadiusTiny);
    return InputDecoration(
      hintText: hintKey.tr(),
      hintStyle: TextStyle(color: colors.textSecondary),
      counterStyle: TextStyle(
        color: colors.textSecondary,
        fontSize: AppDimens.fontSizeXxs,
      ),
      border: OutlineInputBorder(borderRadius: radius),
      focusedBorder: appInputBorder(colors.activate, width: 2),
      errorBorder: appInputBorder(colors.error, width: 1.5),
      focusedErrorBorder: appInputBorder(colors.error, width: 2),
      errorText: bannedWordMessage,
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.appColors.appBarIconColor,
                  ),
                ),
              )
            : Text(
                'done'.tr(),
                style: TextStyle(
                  color: context.appColors.appBarIconColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildImageThumbnail(AbstractThemeColors colors, {
    required Widget preview,
    required VoidCallback onRemove,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            child: preview,
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Semantics(
              button: true,
              label: 'remove_image'.tr(),
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile(AbstractThemeColors colors, double size) {
    return Semantics(
      button: true,
      label: 'photo_add'.tr(),
      child: GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: colors.listDivider),
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            color: colors.textSecondary,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(AbstractThemeColors colors) {
    final size = ResponsiveSize(context).w(72);
    final tiles = <Widget>[
      for (var i = 0; i < _existingImageUrls.length; i++)
        _buildImageThumbnail(
          colors,
          size: size,
          preview: AppNetworkImage(
            imageUrl: _existingImageUrls[i],
            width: size,
            height: size,
            excludeFromSemantics: true,
          ),
          onRemove: () => setState(() => _existingImageUrls.removeAt(i)),
        ),
      for (var i = 0; i < _selectedImages.length; i++)
        _buildImageThumbnail(
          colors,
          size: size,
          preview: ExcludeSemantics(
            child: Image.memory(
              _selectedImages[i],
              fit: BoxFit.cover,
              width: size,
              height: size,
            ),
          ),
          onRemove: () => setState(() => _selectedImages.removeAt(i)),
        ),
      if (_totalImageCount < _maxImages) _buildAddImageTile(colors, size),
    ];

    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => tiles[i],
      ),
    );
  }

  Widget _buildAnonymousToggle(AbstractThemeColors colors) {
    return Column(
      children: [
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _anonymous = !_anonymous),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Switch.adaptive(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
                activeThumbColor: colors.activate,
                activeTrackColor: colors.activate.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'post_anonymous'.tr(),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  color: colors.textTitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AbstractThemeColors colors) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            maxLength: 50,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: colors.textTitle),
            decoration: _fieldDecoration(
              'enter_title',
              bannedWordMessage: _titleHasBannedWord
                  ? 'post_banned_word'.tr()
                  : null,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'enter_title'.tr() : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            maxLines: null,
            minLines: 8,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            style: TextStyle(color: colors.textTitle),
            decoration: _fieldDecoration(
              'enter_content',
              bannedWordMessage: _contentHasBannedWord
                  ? 'post_banned_word'.tr()
                  : null,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'enter_content'.tr() : null,
          ),
          const SizedBox(height: 12),
          _buildImagePicker(colors),
          if (widget.showAnonymous) _buildAnonymousToggle(colors),
        ],
      ),
    );
  }

  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (_isSubmitting) return;
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
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
              title: widget.title,
              actions: [_buildSubmitAction()],
              onBackPressed: () => _onPopInvoked(false),
            ),
            Expanded(
              child: KeyboardDismiss(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(child: _buildForm(colors)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
