import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/foundation.dart';

class FestivalArtistsNotifier extends ChangeNotifier {
  final int festivalId;
  final int? userId;

  List<FestivalArtistItem> artists = [];
  Set<int> followedIds = {};
  bool isLoading = true;
  void Function(String)? onError;

  FestivalArtistsNotifier({required this.festivalId, this.userId});

  Future<void> fetch() async {
    try {
      final artistFuture =
          DioClient.dio.get('/festivals/$festivalId/artists');
      final followFuture = userId != null
          ? DioClient.dio.get('/users/$userId/following')
          : null;

      final artistRes = await artistFuture;
      final fetched = (artistRes.data as List)
          .map((e) => FestivalArtistItem.fromJson(e))
          .toList();

      Set<int> followed = {};
      if (followFuture != null) {
        final followRes = await followFuture;
        followed = (followRes.data as List)
            .map((a) => (a['id'] as num).toInt())
            .toSet();
      }

      // 팔로우한 아티스트를 앞으로 정렬
      fetched.sort((a, b) {
        final aF = followed.contains(a.artistId) ? 0 : 1;
        final bF = followed.contains(b.artistId) ? 0 : 1;
        return aF.compareTo(bF);
      });

      artists = fetched;
      followedIds = followed;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      onError?.call(e.toString());
    }
  }
}
