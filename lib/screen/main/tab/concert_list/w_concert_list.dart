import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/provider/poster/w_festival_preview_card.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/f_festival_information.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/FestivalPreviewProvider.dart';

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
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('해당 조건의 페스티벌이 없습니다.')),
      );
    }

    return Column(
      children: previewPoster.items.map((item) {
        return GestureDetector(
          onTap: () {
            final poster = PosterModel(
              id: item.id,
              title: item.title,
              description: '',
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
