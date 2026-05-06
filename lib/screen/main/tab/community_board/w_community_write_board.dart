import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/injection.dart';
import 'package:provider/provider.dart';
import 'package:feple/service/post_service.dart';

import '../../../../provider/user_provider.dart';

class WritePost extends StatefulWidget {
  final String boardname;

  const WritePost({super.key, required this.boardname});

  @override
  State<WritePost> createState() => _WritePostState();
}

class _WritePostState extends State<WritePost> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _postService = sl<PostService>();
  bool _isSubmitting = false;

  /// boardname → PostService boardType 변환
  String get _serviceBoardType {
    switch (widget.boardname) {
      case 'GetuserBoard':
        return BoardTypes.mate;
      default:
        return widget.boardname;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final user = context.read<UserProvider>().user;
    if (user == null) {
      context.showInfoSnackbar('no_login_info'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _postService.createPost(
        boardType: _serviceBoardType,
        title: title,
        content: content,
      );
      if (!mounted) return;
      AppEvents.postChanged.value++;
      context.showSuccessSnackbar('post_success'.tr());
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      debugPrint('post submit error: $e');
      context.showErrorSnackbar('post_failed'.tr());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: AppDimens.appBarHeight,
              color: colors.appBarColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'write_post'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => _submit(),
                      child: _isSubmitting
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : Text('done'.tr(),
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: KeyboardDismiss(
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
          ),
        ],
      ),
    );
  }
}
