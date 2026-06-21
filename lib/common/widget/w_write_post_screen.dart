import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/image_upload_helper.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WritePostScreen extends StatefulWidget {
  final String title;
  final Future<void> Function(String title, String content, bool anonymous, String? imageObjectKey) onSubmit;
  final String? initialTitle;
  final String? initialContent;
  final bool showAnonymous;
  final String? initialImageUrl;

  const WritePostScreen({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialTitle,
    this.initialContent,
    this.showAnonymous = true,
    this.initialImageUrl,
  });

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _titleHasBannedWord = false;
  bool _contentHasBannedWord = false;
  bool _anonymous = false;
  Uint8List? _selectedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
    if (widget.initialContent != null) _contentController.text = widget.initialContent!;
    _existingImageUrl = widget.initialImageUrl;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _selectedImage = bytes);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      String? imageObjectKey;
      if (_selectedImage != null) {
        final presign = await ImageUploadHelper.compressAndUpload(
          presignEndpoint: PostService.postImagePresignEndpoint,
          imageData: _selectedImage!,
        );
        imageObjectKey = presign.objectKey;
      } else if (_existingImageUrl != null) {
        imageObjectKey = _existingImageUrl;
      }
      await widget.onSubmit(title, content, _anonymous, imageObjectKey);
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

  InputDecoration _fieldDecoration(String hintKey, {String? bannedWordMessage}) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(AppDimens.cardRadiusTiny);
    return InputDecoration(
      hintText: hintKey.tr(),
      hintStyle: TextStyle(color: colors.textSecondary),
      counterStyle: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXxs),
      border: OutlineInputBorder(borderRadius: radius),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colors.activate, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
      errorText: bannedWordMessage,
    );
  }

  Widget _buildSubmitAction() {
    return SizedBox(
      width: 64,
      child: TextButton(
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : Text(
                'done'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildImagePicker(AbstractThemeColors colors) {
    Widget? preview;
    if (_selectedImage != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: Image.memory(_selectedImage!, fit: BoxFit.cover, width: 72, height: 72),
      );
    } else if (_existingImageUrl != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: CachedNetworkImage(
          imageUrl: _existingImageUrl!,
          width: 72,
          height: 72,
          memCacheWidth: 144,
          fit: BoxFit.cover,
          fadeInDuration: AppDimens.animXFast,
          fadeOutDuration: AppDimens.animTapFeedback,
        ),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: colors.listDivider),
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            ),
            child: preview ?? Icon(Icons.add_photo_alternate_outlined, color: colors.textSecondary, size: 32),
          ),
        ),
        if (_selectedImage != null || _existingImageUrl != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'remove_image'.tr(),
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            onPressed: () => setState(() {
              _selectedImage = null;
              _existingImageUrl = null;
            }),
          ),
        ],
      ],
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
              Switch(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
                activeThumbColor: colors.activate,
                activeTrackColor: colors.activate.withValues(alpha: 0.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 6),
              Text(
                'post_anonymous'.tr(),
                style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textTitle),
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
            style: TextStyle(color: colors.textTitle),
            decoration: _fieldDecoration(
              'enter_title',
              bannedWordMessage: _titleHasBannedWord ? 'post_banned_word'.tr() : null,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_title'.tr() : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            maxLines: null,
            minLines: 8,
            maxLength: 500,
            style: TextStyle(color: colors.textTitle),
            decoration: _fieldDecoration(
              'enter_content',
              bannedWordMessage: _contentHasBannedWord ? 'post_banned_word'.tr() : null,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_content'.tr() : null,
          ),
          const SizedBox(height: 12),
          _buildImagePicker(colors),
          if (widget.showAnonymous) _buildAnonymousToggle(colors),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(
            title: widget.title,
            actions: [_buildSubmitAction()],
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
    );
  }
}
