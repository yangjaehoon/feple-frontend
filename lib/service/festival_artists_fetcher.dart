import 'package:feple/model/festival_artist_item.dart';

abstract class FestivalArtistsFetcher {
  Future<List<FestivalArtistItem>> fetchFestivalArtists(int festivalId);
}
