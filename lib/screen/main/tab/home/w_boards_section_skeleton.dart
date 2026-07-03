import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

class BoardsSectionSkeleton extends StatelessWidget {
  const BoardsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              SkeletonBox(
                width: 3,
                height: 20,
                borderRadius: BorderRadius.circular(AppDimens.barRadius),
              ),
              const SizedBox(width: 8),
              const SkeletonBox(width: 130, height: 18),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (_, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SkeletonBox(
                width: 110,
                height: 110,
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
