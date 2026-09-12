import 'package:feple/model/photo_destination.dart';

extension PhotoCategoryStyle on PhotoCategory {
  String get labelKey => switch (kind) {
        PhotoCategoryKind.daily => 'photo_category_daily',
        PhotoCategoryKind.sns => 'photo_category_sns',
        PhotoCategoryKind.other => 'photo_category_other',
      };
}
