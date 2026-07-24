import 'dart:convert';

import 'package:feple/network/api_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences에 직접 만료된 데이터를 삽입 (TTL 검증용)
Future<void> _putWithAge(String url, dynamic data, int ageMs) async {
  final ts = DateTime.now().millisecondsSinceEpoch - ageMs;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_cache_$url', jsonEncode({'data': data, 'ts': ts}));
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiCacheStore.clearForTesting();
    await ApiCacheStore.init();
  });

  // ───────────────────────────────────────────────────
  // A. SWR — getSync 즉시 반환
  // ───────────────────────────────────────────────────
  group('A. SWR - getSync', () {
    test('put() 후 getSync()는 즉시 데이터 반환', () async {
      const url = 'http://api/festivals/1';
      await ApiCacheStore.put(url, {'title': '록 페스티벌'});

      final result = ApiCacheStore.getSync(url);

      expect(result, isNotNull);
      expect(result['title'], '록 페스티벌');
    });

    test('캐시 없으면 getSync()는 null 반환', () {
      expect(ApiCacheStore.getSync('http://api/festivals/99'), isNull);
    });

    test('앱 재시작 후 메모리 없을 때 _prefs(SharedPreferences)에서 즉시 읽기', () async {
      const url = 'http://api/artists/1';

      // 온라인에서 데이터 저장 (SharedPreferences까지 저장)
      await ApiCacheStore.put(url, {'name': '아이유'});

      // 앱 재시작 시뮬레이션 — 메모리만 초기화, SharedPreferences는 유지
      ApiCacheStore.clearForTesting();
      await ApiCacheStore.init();

      // getSync()가 _prefs를 통해 즉시 읽어야 함 (5초 타임아웃 없이)
      final result = ApiCacheStore.getSync(url);

      expect(result, isNotNull);
      expect(result['name'], '아이유');
    });

    test('put() 후 get()도 동일 데이터 반환', () async {
      const url = 'http://api/festivals/2';
      await ApiCacheStore.put(url, [1, 2, 3]);

      expect(await ApiCacheStore.get(url), [1, 2, 3]);
    });
  });

  // ───────────────────────────────────────────────────
  // B. TTL — 엔드포인트별 만료 검증
  // ───────────────────────────────────────────────────
  group('B. TTL - 엔드포인트별 만료', () {
    test('신선한 데이터는 어느 엔드포인트든 반환', () async {
      final urls = [
        'http://api/festivals/1/weather',
        'http://api/festivals/1/timetable',
        'http://api/artists/1/songs',
        'http://api/posts/1',
        'http://api/notifications/my/unread-count',
      ];
      for (final url in urls) {
        await ApiCacheStore.put(url, 'data');
        expect(ApiCacheStore.getSync(url), isNotNull, reason: url);
      }
    });

    test('날씨: 3시간 초과 데이터는 만료 처리', () async {
      const url = 'http://api/festivals/1/weather';
      await _putWithAge(url, '맑음', 4 * 60 * 60 * 1000); // 4시간 전

      expect(ApiCacheStore.getSync(url), isNull);
    });

    test('날씨: 2시간 된 데이터는 유효', () async {
      const url = 'http://api/festivals/1/weather';
      await _putWithAge(url, '흐림', 2 * 60 * 60 * 1000); // 2시간 전

      expect(ApiCacheStore.getSync(url), '흐림');
    });

    test('알림: 2분 초과 데이터는 만료 처리', () async {
      const url = 'http://api/notifications/my/unread-count';
      await _putWithAge(url, 5, 3 * 60 * 1000); // 3분 전

      expect(ApiCacheStore.getSync(url), isNull);
    });

    test('알림: 1분 된 데이터는 유효', () async {
      const url = 'http://api/notifications/my/unread-count';
      await _putWithAge(url, 5, 60 * 1000); // 1분 전

      expect(ApiCacheStore.getSync(url), 5);
    });

    test('게시글: 30분 초과 데이터는 만료 처리', () async {
      const url = 'http://api/posts/1';
      await _putWithAge(url, {'title': '글'}, 31 * 60 * 1000); // 31분 전

      expect(ApiCacheStore.getSync(url), isNull);
    });

    test('타임테이블: 12시간 초과 데이터는 만료 처리', () async {
      const url = 'http://api/festivals/1/timetable';
      await _putWithAge(url, [], 13 * 60 * 60 * 1000); // 13시간 전

      expect(ApiCacheStore.getSync(url), isNull);
    });

    test('타임테이블: 11시간 된 데이터는 유효', () async {
      const url = 'http://api/festivals/1/timetable';
      await _putWithAge(url, [], 11 * 60 * 60 * 1000); // 11시간 전

      expect(ApiCacheStore.getSync(url), isNotNull);
    });

    test('곡 목록: 30일 이전 데이터는 만료, 29일 데이터는 유효', () async {
      const expiredUrl = 'http://api/artists/1/songs?expired';
      const freshUrl = 'http://api/artists/1/songs?fresh';
      await _putWithAge(expiredUrl, [], 31 * 24 * 60 * 60 * 1000); // 31일 전
      await _putWithAge(freshUrl, ['곡1'], 29 * 24 * 60 * 60 * 1000); // 29일 전

      expect(ApiCacheStore.getSync(expiredUrl), isNull);
      expect(ApiCacheStore.getSync(freshUrl), isNotNull);
    });

    test('기본(페스티벌 목록): 7일 초과 만료', () async {
      const url = 'http://api/festivals';
      await _putWithAge(url, [], 8 * 24 * 60 * 60 * 1000); // 8일 전

      expect(ApiCacheStore.getSync(url), isNull);
    });
  });

  // ───────────────────────────────────────────────────
  // C. 캐시 무효화 — invalidateFor
  // ───────────────────────────────────────────────────
  group('C. 캐시 무효화 - invalidateFor', () {
    test('페스티벌 좋아요 → liked, liked-festivals 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/festivals/1/liked', true);
      await ApiCacheStore.put('http://api/users/10/liked-festivals', []);
      await ApiCacheStore.put('http://api/festivals/1', {'title': '페스티벌'}); // 무관

      await ApiCacheStore.invalidateFor('http://api/festivals/1/like');

      expect(ApiCacheStore.getSync('http://api/festivals/1/liked'), isNull);
      expect(ApiCacheStore.getSync('http://api/users/10/liked-festivals'), isNull);
      expect(ApiCacheStore.getSync('http://api/festivals/1'), isNotNull); // 유지
    });

    test('아티스트 팔로우 → follow, following 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/artists/5/follow', false);
      await ApiCacheStore.put('http://api/users/10/following', []);
      await ApiCacheStore.put('http://api/artists/5/songs', []); // 무관

      await ApiCacheStore.invalidateFor('http://api/artists/5/follow');

      expect(ApiCacheStore.getSync('http://api/artists/5/follow'), isNull);
      expect(ApiCacheStore.getSync('http://api/users/10/following'), isNull);
      expect(ApiCacheStore.getSync('http://api/artists/5/songs'), isNotNull); // 유지
    });

    test('게시글 스크랩 → scraped, scrapped 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/posts/3/scraped', false);
      await ApiCacheStore.put('http://api/posts/my/scrapped', []);
      await ApiCacheStore.put('http://api/posts/3', {'title': '글'}); // 무관

      await ApiCacheStore.invalidateFor('http://api/posts/3/scrap');

      expect(ApiCacheStore.getSync('http://api/posts/3/scraped'), isNull);
      expect(ApiCacheStore.getSync('http://api/posts/my/scrapped'), isNull);
      expect(ApiCacheStore.getSync('http://api/posts/3'), isNotNull); // 유지
    });

    test('게시글 좋아요 → liked, liked-posts 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/posts/3/liked', false);
      await ApiCacheStore.put('http://api/users/1/liked-posts', []);

      await ApiCacheStore.invalidateFor('http://api/posts/3/like');

      expect(ApiCacheStore.getSync('http://api/posts/3/liked'), isNull);
      expect(ApiCacheStore.getSync('http://api/users/1/liked-posts'), isNull);
    });

    test('게시글 삭제/수정 → posts 패턴 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/posts/7', {'title': '글'});
      await ApiCacheStore.put('http://api/posts/search?q=rock', []);
      await ApiCacheStore.put('http://api/festivals/1', {'title': '페스'}); // 무관

      await ApiCacheStore.invalidateFor('http://api/posts/7');

      expect(ApiCacheStore.getSync('http://api/posts/7'), isNull);
      expect(ApiCacheStore.getSync('http://api/posts/search?q=rock'), isNull);
      expect(ApiCacheStore.getSync('http://api/festivals/1'), isNotNull); // 유지
    });

    test('댓글 작성 → comments 패턴 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/comments/post/10', []);
      await ApiCacheStore.put('http://api/festivals/1', {'title': '페스'}); // 무관

      await ApiCacheStore.invalidateFor('http://api/comments');

      expect(ApiCacheStore.getSync('http://api/comments/post/10'), isNull);
      expect(ApiCacheStore.getSync('http://api/festivals/1'), isNotNull); // 유지
    });

    test('알림 읽음 처리 → notifications 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/notifications/my/unread-count', 3);
      await ApiCacheStore.put('http://api/posts/1', {'title': '글'}); // 무관

      await ApiCacheStore.invalidateFor('http://api/notifications/1/read');

      expect(ApiCacheStore.getSync('http://api/notifications/my/unread-count'), isNull);
      expect(ApiCacheStore.getSync('http://api/posts/1'), isNotNull); // 유지
    });

    test('세트리스트 수정 → 해당 페스티벌 setlist 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/festivals/2/setlist', []);
      await ApiCacheStore.put('http://api/festivals/3/setlist', []); // 다른 페스티벌, 유지

      await ApiCacheStore.invalidateFor('http://api/festivals/2/artists/10/setlist');

      expect(ApiCacheStore.getSync('http://api/festivals/2/setlist'), isNull);
      expect(ApiCacheStore.getSync('http://api/festivals/3/setlist'), isNotNull); // 유지
    });

    test('페스티벌 참석 → attending 캐시만 삭제', () async {
      await ApiCacheStore.put('http://api/festivals/1/attending', false);
      await ApiCacheStore.put('http://api/festivals/1/liked', true); // 무관

      await ApiCacheStore.invalidateFor('http://api/festivals/1/attending');

      expect(ApiCacheStore.getSync('http://api/festivals/1/attending'), isNull);
      expect(ApiCacheStore.getSync('http://api/festivals/1/liked'), isNotNull); // 유지
    });

    test('인증 제출 → certifications 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/certifications/my', []);

      await ApiCacheStore.invalidateFor('http://api/certifications');

      expect(ApiCacheStore.getSync('http://api/certifications/my'), isNull);
    });

    test('유저 차단 → 유저 캐시뿐 아니라 posts/comments 캐시도 삭제', () async {
      await ApiCacheStore.put('http://api/users/10', {'nickname': '차단대상'});
      await ApiCacheStore.put('http://api/users/blocked', []);
      await ApiCacheStore.put('http://api/posts/board/free', [{'title': '글'}]);
      await ApiCacheStore.put('http://api/comments/post/10', []);
      await ApiCacheStore.put('http://api/festivals/1', {'title': '페스'}); // 무관

      await ApiCacheStore.invalidateFor('http://api/users/10/block');

      expect(ApiCacheStore.getSync('http://api/users/10'), isNull);
      expect(ApiCacheStore.getSync('http://api/users/blocked'), isNull);
      expect(ApiCacheStore.getSync('http://api/posts/board/free'), isNull);
      expect(ApiCacheStore.getSync('http://api/comments/post/10'), isNull);
      expect(ApiCacheStore.getSync('http://api/festivals/1'), isNotNull); // 유지
    });

    test('프로필 수정 → 해당 유저 캐시 삭제', () async {
      await ApiCacheStore.put('http://api/users/10', {'nickname': '구닉네임'});
      await ApiCacheStore.put('http://api/users/20', {'nickname': '다른유저'}); // 무관

      await ApiCacheStore.invalidateFor('http://api/users/10/bio');

      expect(ApiCacheStore.getSync('http://api/users/10'), isNull);
      expect(ApiCacheStore.getSync('http://api/users/20'), isNotNull); // 유지
    });

    test('조회수(view)는 무효화 패턴 없음 — 다른 캐시 영향 없음', () async {
      await ApiCacheStore.put('http://api/posts/1', {'title': '글'});

      await ApiCacheStore.invalidateFor('http://api/posts/1/view');

      expect(ApiCacheStore.getSync('http://api/posts/1'), isNotNull); // 유지
    });

    test('무효화 시 메모리와 SharedPreferences 모두 삭제됨', () async {
      const url = 'http://api/festivals/9/liked';
      await ApiCacheStore.put(url, true);

      await ApiCacheStore.invalidateFor('http://api/festivals/9/like');

      // 메모리 삭제 확인
      expect(ApiCacheStore.getSync(url), isNull);

      // SharedPreferences에서도 삭제 확인 — 메모리 초기화 후 get() 사용
      ApiCacheStore.clearForTesting();
      await ApiCacheStore.init();
      expect(await ApiCacheStore.get(url), isNull);
    });
  });
}
