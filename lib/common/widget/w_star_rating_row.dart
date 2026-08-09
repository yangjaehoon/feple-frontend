import 'package:flutter/material.dart';

/// 평균 별점을 채움/반쪽/빈 별 5개로 표시하는 공용 위젯.
class StarRatingRow extends StatelessWidget {
  final double rating;
  final double size;

  const StarRatingRow({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && (rating - i) >= 0.5;
        return Icon(
          filled
              ? Icons.star_rounded
              : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}
