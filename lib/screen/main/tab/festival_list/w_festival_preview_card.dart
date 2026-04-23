import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

import 'package:feple/model/festival_preview.dart';

class FestivalPreviewCard extends StatelessWidget {
  final FestivalPreview festival;

  const FestivalPreviewCard({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 120,
            margin: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.backgroundMain,
                        image: DecorationImage(
                          image: ResizeImage(
                              CachedNetworkImageProvider(festival.posterUrl), width: 160),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    if (festival.isEnded) ...[
                      Container(color: Colors.black.withValues(alpha: 0.5)),
                      Center(
                        child: Text(
                          'status_ended'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          festival.localizedTitle(context.locale.languageCode),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: colors.textTitle,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert_rounded,
                            color: colors.textSecondary, size: 20),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Text("msg_review".tr()),
                          ),
                          PopupMenuItem(
                            child: Text("msg_delete".tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: colors.activate, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          festival.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: colors.activate, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        festival.startDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
