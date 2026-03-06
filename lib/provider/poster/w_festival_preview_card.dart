import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

import '../../model/FestivalPreview.dart';

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
            color: colors.cardShadow.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.backgroundMain,
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: ResizeImage(NetworkImage(festival.posterUrl), width: 220),
                fit: BoxFit.cover,
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
                          festival.title ?? '페스티벌 이름',
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
                          const PopupMenuItem(
                            child: Text("리뷰"),
                          ),
                          const PopupMenuItem(
                            child: Text("삭제"),
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
                          festival.location ?? '',
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
                        festival.startDate ?? '',
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