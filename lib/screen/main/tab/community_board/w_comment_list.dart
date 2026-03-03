import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/comment_provider.dart';

class CommentList extends StatelessWidget {
  final int postId;

  const CommentList({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommentProvider>();

    return ListView.builder(
        itemCount: provider.comments.length,
        itemBuilder: (ctx, i) {
          final comment = provider.comments[i];
          return ListTile(
              title: Text(comment.content),
              trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    try {
                      await provider.deleteComment(comment.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('댓글이 삭제되었습니다.')));
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                    }
                  }));
        });
  }
}
