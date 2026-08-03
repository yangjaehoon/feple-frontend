import 'package:feple/common/widget/w_suggestion_sheet.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/festival_suggestion_service.dart';
import 'package:flutter/material.dart';

class FestivalSuggestionSheet extends StatelessWidget {
  const FestivalSuggestionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SuggestionSheet(
      i18nPrefix: 'festival_suggestion',
      submit: ({required name, note}) => sl<FestivalSuggestionService>()
          .submit(festivalName: name, note: note),
    );
  }
}
