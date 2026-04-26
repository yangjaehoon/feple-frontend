import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/common.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';

/// 아티스트 게시판 글쓰기 화면
class ArtistWritePost extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistWritePost({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistWritePost> createState() => _ArtistWritePostState();
}

class _ArtistWritePostState extends State<ArtistWritePost> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _postService = sl<PostService>();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      await _postService.createArtistPost(
        artistId: widget.artistId,
        title: title,
        content: content,
      );
      if (!mounted) return;
      context.showSuccessSnackbar('post_success'.tr());
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackbar('post_failed'.tr(args: [e.toString()]));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('name_board_write'.tr(args: [widget.artistName])),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => _submit(),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('done'.tr(),
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      backgroundColor: colors.backgroundMain,
      body: KeyboardDismiss(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  maxLength: 50,
                  style: TextStyle(color: colors.textTitle),
                  decoration: InputDecoration(
                    hintText: 'enter_title'.tr(),
                    hintStyle: TextStyle(color: colors.textSecondary),
                    counterStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.activate, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
                    ),
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
                  style: TextStyle(color: colors.textTitle),
                  decoration: InputDecoration(
                    hintText: 'enter_content'.tr(),
                    hintStyle: TextStyle(color: colors.textSecondary),
                    counterStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.activate, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'enter_content'.tr() : null,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
