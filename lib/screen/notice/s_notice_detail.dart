import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/model/notice_model.dart';
import 'package:flutter/material.dart';

class NoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'notices'.tr()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppDimens.fontSizeTitle,
                      color: colors.textTitle,
                    ),
                  ),
                  if (notice.formattedDate != null) ...[
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      notice.formattedDate!,
                      style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: AppDimens.space20),
                  Divider(height: 1, color: colors.listDivider),
                  const SizedBox(height: AppDimens.space20),
                  Text(
                    notice.content,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeMd,
                      color: colors.textTitle,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
