import 'package:fast_app_base/provider/poster/w_festival_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/FestivalPreviewProvider.dart';
import '../../../../provider/poster/poster_provider.dart';
import '../../../../provider/poster/w_build_poster_card.dart';

class ConcertListWidget extends StatefulWidget {
  const ConcertListWidget({Key? key}) : super(key: key);

  @override
  State<ConcertListWidget> createState() => _ConcertListWidgetState();
}

class _ConcertListWidgetState extends State<ConcertListWidget> {
  @override
  Widget build(BuildContext context) {
    // Provider.of를 사용하여 PosterProvider 인스턴스를 가져옵니다.
    // final poster = Provider.of<PosterProvider>(context); //파이어베이스에서 가져오는거
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
              return buildFestivalPreviewCard(item);
            },
    );
  }
}
