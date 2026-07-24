import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// 탭한 리스트 항목이 상세 데이터를 fetch하는 동안 보여주는 작은 스피너.
/// blocking fetch 자체를 없애진 않지만, 탭이 씹히지 않았다는 즉각적 피드백을 준다.
class TapLoadingIndicator extends StatelessWidget {
  final double size;

  const TapLoadingIndicator({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.appColors.activate,
      ),
    );
  }
}
