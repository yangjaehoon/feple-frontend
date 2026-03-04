import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fast_app_base/service/post_service.dart';

import '../../../../provider/user_provider.dart';

class WritePost extends StatefulWidget {
  final String boardname;

  const WritePost({super.key, required this.boardname});

  @override
  State<WritePost> createState() => _WritePostState();
}

class _WritePostState extends State<WritePost> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _postService = PostService();
  bool _isSubmitting = false;

  /// boardname → PostService boardType 변환
  String get _serviceBoardType {
    switch (widget.boardname) {
      case 'GetuserBoard':
        return 'MateBoard';
      default:
        return widget.boardname;
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.skyBlue, content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    final user = context.read<UserProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.skyBlue, content: Text('로그인 정보가 없습니다.')),
      );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(backgroundColor: AppColors.skyBlue, content: Text('게시글이 성공적으로 등록되었습니다.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.skyBlue, content: Text('게시글 등록에 실패했습니다.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 쓰기'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => _submit(),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('완료', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
