import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final poster = Provider.of<PosterProvider>(context);

    return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: poster.posters.length,
            itemBuilder: (context, index) {
              final poster1 = poster.posters[index];
              return buildPosterCard(poster1);
            },
    );
  }
}
