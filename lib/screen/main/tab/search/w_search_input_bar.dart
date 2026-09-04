import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_borderless_input_theme.dart';
import 'package:flutter/material.dart';

/// 통합 검색 화면 상단의 뒤로가기 + borderless 검색 입력창 + 검색 아이콘.
/// 입력창 우측 지우기 버튼은 [controller]를 직접 구독해 독립적으로 갱신한다.
class SearchInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const SearchInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.appBarColor,
        child: Row(
          children: [
            IconButton(
              tooltip: 'back'.tr(),
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: colors.appBarIconColor),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              // 앱바 위 borderless 검색창 — BorderlessInputTheme 없이는 전역 테마의
              // OutlineInputBorder가 파란 바탕 위에 옅은 테두리로 남는다.
              child: BorderlessInputTheme(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                      color: colors.appBarIconColor,
                      fontSize: AppDimens.fontSizeXl),
                  cursorColor: Colors.white70,
                  decoration: InputDecoration(
                    hintText: 'search_hint'.tr(),
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    filled: false,
                    suffixIcon: AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) => _buildClearSuffix(),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
            IconButton(
              tooltip: 'search'.tr(),
              icon: Icon(Icons.search_rounded, color: colors.appBarIconColor),
              onPressed: onSearch,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearSuffix() {
    if (controller.text.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'clear'.tr(),
      icon: const Icon(Icons.clear, color: Colors.white70),
      onPressed: onClear,
    );
  }
}
