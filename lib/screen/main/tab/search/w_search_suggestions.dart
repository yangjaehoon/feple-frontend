import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/util/text_highlight.dart';
import 'package:feple/common/widget/w_tap_loading_indicator.dart';
import 'package:feple/model/search_suggestion.dart';
import 'package:feple/screen/main/tab/search/search_style.dart';
import 'package:flutter/material.dart';

/// 입력 중 자동완성 목록 — 아티스트/페스티벌 그룹으로 나눠 보여준다.
/// id가 있는 항목은 탭 시 상세로 바로 이동(로딩 중이면 [navigatingId]로 표시).
class SearchSuggestionsView extends StatelessWidget {
  final List<SearchSuggestion> suggestions;
  final String highlightKeyword;
  final int? navigatingId;
  final ValueChanged<SearchSuggestion> onSelect;

  const SearchSuggestionsView({
    super.key,
    required this.suggestions,
    required this.highlightKeyword,
    required this.navigatingId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    final artists =
        suggestions.where((s) => s.type == SearchType.artist).toList();
    final festivals =
        suggestions.where((s) => s.type == SearchType.festival).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        if (artists.isNotEmpty) ...[
          _groupHeader('search_artists'.tr(), colors),
          ..._tiles(context, artists, colors),
        ],
        if (festivals.isNotEmpty) ...[
          _groupHeader('search_festivals'.tr(), colors),
          ..._tiles(context, festivals, colors),
        ],
      ],
    );
  }

  Widget _groupHeader(String label, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXs,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  List<Widget> _tiles(
    BuildContext context,
    List<SearchSuggestion> items,
    AbstractThemeColors colors,
  ) {
    return List.generate(items.length, (i) {
      final suggestion = items[i];
      final isLoading =
          suggestion.id != null && navigatingId == suggestion.id;
      return Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: _leading(context, suggestion, colors),
            title: buildHighlightedText(
              suggestion.displayLabel(context.isEnglish),
              highlightKeyword,
              TextStyle(
                  color: colors.textTitle, fontSize: AppDimens.fontSizeLg),
              colors.activate,
            ),
            trailing: isLoading
                ? const TapLoadingIndicator()
                : Icon(Icons.north_west_rounded,
                    size: 16, color: colors.textSecondary),
            onTap: isLoading ? null : () => onSelect(suggestion),
          ),
          if (i < items.length - 1)
            Divider(
                height: 1,
                thickness: 1,
                color: colors.listDivider,
                indent: 72,
                endIndent: 16),
        ],
      );
    });
  }

  Widget _leading(
    BuildContext context,
    SearchSuggestion suggestion,
    AbstractThemeColors colors,
  ) {
    final imageUrl = suggestion.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(suggestion.type.icon, color: colors.textSecondary, size: 20);
    }
    final size = ResponsiveSize(context).w(40);
    if (suggestion.type == SearchType.artist) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.textSecondary.withValues(alpha: 0.2),
        backgroundImage: CachedNetworkImageProvider(imageUrl, maxWidth: 80),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        memCacheWidth: 80,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: size,
          height: size,
          color: colors.textSecondary.withValues(alpha: 0.2),
        ),
        errorWidget: (_, _, _) =>
            Icon(suggestion.type.icon, color: colors.textSecondary, size: 20),
      ),
    );
  }
}
