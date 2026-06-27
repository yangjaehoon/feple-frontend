import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/open_source_package.dart';
import 'package:flutter/material.dart';

class OpensourceItem extends StatelessWidget {
  final Package package;

  const OpensourceItem(this.package, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              package.name,
              style: TextStyle(
                fontSize: AppDimens.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: colors.textTitle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8, right: 20),
            child: Text(
              package.description,
              style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textSecondary),
            ),
          ),
          if (package.authors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: Text(
                package.authors.join(', '),
                style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textSecondary),
              ),
            ),
          if (package.homepage != null && package.homepage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 15),
              child: Text(
                package.homepage!,
                style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textSecondary),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: colors.drawerBg,
              border: Border.all(color: colors.divider),
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            ),
            margin: const EdgeInsets.only(left: 20, top: 15, right: 20),
            height: 230,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Text(
                package.license ?? '',
                style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
