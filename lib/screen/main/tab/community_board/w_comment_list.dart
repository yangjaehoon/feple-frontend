import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/app_colors.dart';
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: AppColors.skyBlue, content: Text('comment_deleted'.tr())));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(backgroundColor: AppColors.skyBlue, content: Text('delete_failed'.tr(args: [e.toString()]))));
                    }
                  }));
        });
  }
}
