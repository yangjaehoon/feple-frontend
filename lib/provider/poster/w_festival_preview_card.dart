
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/model/poster_model.dart';
import 'package:flutter/material.dart';

import '../../model/FestivalPreview.dart';

Widget buildFestivalPreviewCard(FestivalPreview festival) {
  debugPrint('imgUrl=${festival.posterUrl}');

  return Container(
    height: 140,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.skyBlue.withOpacity(0.12),
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
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(festival.posterUrl),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textMain,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppColors.textMuted, size: 20),
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
                        color: AppColors.skyBlue, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        festival.location ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
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
                        color: AppColors.skyBlue, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      festival.startDate ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
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