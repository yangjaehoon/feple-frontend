import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:flutter/material.dart';

/// 통합 검색 화면에서 아직 아무것도 입력하지 않았을 때 보여주는 최근 검색어 목록.
class RecentSearchesView extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const RecentSearchesView({
    super.key,
    required this.recentSearches,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(colors),
        if (recentSearches.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'no_recent_searches'.tr(),
              style: TextStyle(
                  fontSize: AppDimens.fontSizeSm,
                  color: colors.textSecondary.withValues(alpha: 0.6)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: recentSearches.length,
              itemBuilder: (_, index) {
                final keyword = recentSearches[index];
                return AnimatedListItem(
                  index: index,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    dense: true,
                    leading: Icon(Icons.history_rounded,
                        size: 18, color: colors.textSecondary),
                    title: Text(keyword,
                        style: TextStyle(
                            fontSize: AppDimens.fontSizeMd,
                            color: colors.textTitle)),
                    trailing: IconButton(
                      tooltip: 'delete'.tr(),
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: colors.textSecondary),
                      onPressed: () => onRemove(keyword),
                    ),
                    onTap: () => onSelect(keyword),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'recent_searches'.tr(),
            style: TextStyle(
                fontSize: AppDimens.fontSizeSm,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary),
          ),
          if (recentSearches.isNotEmpty)
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                'clear_all'.tr(),
                style: TextStyle(
                    fontSize: AppDimens.fontSizeXs,
                    color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
