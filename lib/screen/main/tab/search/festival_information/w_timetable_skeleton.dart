import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

class TimetableSkeleton extends StatelessWidget {
  const TimetableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateTabSkeleton(),
        _buildStageHeaderSkeleton(),
        _buildTimeSlotSkeleton(),
      ],
    );
  }

  Widget _buildDateTabSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: List.generate(3, (i) => const Padding(
          padding: EdgeInsets.only(right: 8, bottom: 10),
          child: SkeletonBox(
            width: 80,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        )),
      ),
    );
  }

  Widget _buildStageHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: List.generate(3, (i) => const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SkeletonBox(
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildTimeSlotSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: List.generate(5, (row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const SkeletonBox(width: 40, height: 12),
              const SizedBox(width: 8),
              ...List.generate(3, (col) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SkeletonBox(
                    height: row % 2 == 0 ? 48 : 36,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              )),
            ],
          ),
        )),
      ),
    );
  }
}
