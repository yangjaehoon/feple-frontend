import 'package:feple/common/widget/w_suggestion_sheet.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/artist_suggestion_service.dart';
import 'package:flutter/material.dart';

class ArtistSuggestionSheet extends StatelessWidget {
  const ArtistSuggestionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SuggestionSheet(
      i18nPrefix: 'artist_suggestion',
      submit: ({required name, note}) =>
          sl<ArtistSuggestionService>().submit(artistName: name, note: note),
    );
  }
}
