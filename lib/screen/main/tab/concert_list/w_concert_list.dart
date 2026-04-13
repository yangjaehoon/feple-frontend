import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/screen/main/tab/concert_list/w_festival_preview_card.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/f_festival_information.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';

class ConcertListWidget extends StatefulWidget {
  const ConcertListWidget({super.key});

  @override
  State<ConcertListWidget> createState() => _ConcertListWidgetState();
}

class _ConcertListWidgetState extends State<ConcertListWidget> {
  @override
  Widget build(BuildContext context) {
    final previewPoster = context.watch<FestivalPreviewProvider>();

    if (previewPoster.isLoading && previewPoster.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (previewPoster.error != null && previewPoster.items.isEmpty) {
      return Center(child: Text(previewPoster.error!));
    }

    if (previewPoster.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('no_festival_condition'.tr())),
      );
    }

    return Column(
      children: previewPoster.items.map((item) {
        return GestureDetector(
          onTap: () {
            final poster = PosterModel(
              id: item.id,
              title: item.title,
              description: item.description,
              location: item.location,
              startDate: item.startDate,
              endDate: item.endDate ?? '',
              posterUrl: item.posterUrl,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FestivalInformationFragment(poster: poster),
              ),
            );
          },
          child: FestivalPreviewCard(festival: item),
        );
      }).toList(),
    );
  }
}
