import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/provider/poster/w_festival_preview_card.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/f_festival_information.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/FestivalPreviewProvider.dart';

class ConcertListWidget extends StatefulWidget {
  const ConcertListWidget({Key? key}) : super(key: key);

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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: previewPoster.items.length,
      itemBuilder: (context, index) {
        final item = previewPoster.items[index];
        return GestureDetector(
          onTap: () {
            // Convert FestivalPreview → PosterModel for detail page
            final poster = PosterModel(
              id: item.id,
              title: item.title,
              description: '',
              location: item.location,
              startDate: item.startDate,
              endDate: '',
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
          child: buildFestivalPreviewCard(item),
        );
      },
    );
  }
}
