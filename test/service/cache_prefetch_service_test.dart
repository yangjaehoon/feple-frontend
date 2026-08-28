import 'package:feple/model/festival_model.dart';
import 'package:feple/service/cache_prefetch_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFestivalDetailService extends Mock implements FestivalDetailService {}

FestivalModel _festival({
  required int id,
  required String start,
  String end = '2099-12-31',
}) =>
    FestivalModel(
      id: id,
      title: 'F$id',
      description: '',
      location: '',
      startDate: start,
      endDate: end,
      posterUrl: '',
    );

void main() {
  late _MockFestivalDetailService detail;
  late CachePrefetchService service;
  late List<int> prefetchedIds;

  setUp(() {
    detail = _MockFestivalDetailService();
    service = CachePrefetchService(detail);
    prefetchedIds = [];
    when(() => detail.fetchTimetable(any())).thenAnswer((inv) async {
      prefetchedIds.add(inv.positionalArguments.first as int);
      return [];
    });
    when(() => detail.fetchSetlist(any())).thenAnswer((_) async => []);
    when(() => detail.fetchWeather(any())).thenAnswer((_) async => null);
    when(() => detail.fetchFestivalArtists(any())).thenAnswer((_) async => []);
  });

  test('종료된 축제는 프리페치하지 않는다', () async {
    await service.prefetchForFestivals([
      _festival(id: 1, start: '2099-01-01'),
      _festival(id: 2, start: '2000-01-01', end: '2000-01-02'), // 종료됨
    ]);
    expect(prefetchedIds, [1]);
  });

  test('시작일이 가까운 순으로 최대 5개만 프리페치', () async {
    final festivals = [
      _festival(id: 10, start: '2099-05-01'),
      _festival(id: 20, start: '2099-01-01'),
      _festival(id: 30, start: '2099-03-01'),
      _festival(id: 40, start: '2099-02-01'),
      _festival(id: 50, start: '2099-06-01'),
      _festival(id: 60, start: '2099-04-01'),
      _festival(id: 70, start: '2099-07-01'),
    ];

    await service.prefetchForFestivals(festivals);

    // 시작일 오름차순 상위 5개: 20(1월) 40(2월) 30(3월) 60(4월) 10(5월)
    expect(prefetchedIds, [20, 40, 30, 60, 10]);
  });
}
