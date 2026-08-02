import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_edit_photo_sheet.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockArtistScheduleService extends Mock implements ArtistScheduleService {}

ArtistPhoto _photo({String title = '제목', String description = ''}) => ArtistPhoto(
      photoId: 1,
      url: 'https://example.com/1.jpg',
      uploaderUserId: 10,
      uploaderNickname: '업로더',
      createdAt: DateTime(2025),
      title: title,
      description: description,
      likeCount: 0,
      isLiked: false,
      isAnonymous: false,
    );

FestivalPreview _festival({int id = 1, String title = '페스티벌'}) => FestivalPreview(
      id: id,
      title: title,
      location: '서울',
      posterUrl: '',
      startDate: '2026-08-01',
    );

void main() {
  late MockArtistScheduleService mockService;

  setUp(() {
    mockService = MockArtistScheduleService();
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
    sl.registerSingleton<ArtistScheduleService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<ArtistScheduleService>()) {
      sl.unregister<ArtistScheduleService>();
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    required ArtistPhoto photo,
    required void Function(String, String) onSave,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        startLocale: const Locale('ko'),
        fallbackLocale: const Locale('ko'),
        path: 'assets/translations',
        useOnlyLangCode: true,
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppBottomSheet<void>(
                    context,
                    builder: (_) => EditPhotoSheet(artistId: 1, photo: photo, onSave: onSave),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  group('EditPhotoSheet 렌더링', () {
    testWidgets('기존 제목을 미리 채운다', (tester) async {
      when(() => mockService.fetchFestivals(1)).thenAnswer((_) async => []);

      await pump(tester, photo: _photo(title: '기존 제목'), onSave: (_, _) {});

      expect(find.text('기존 제목'), findsOneWidget);
    });

    testWidgets('페스티벌 로딩 중에는 로딩 힌트를 보여준다', (tester) async {
      final completer = Completer<List<FestivalPreview>>();
      when(() => mockService.fetchFestivals(1)).thenAnswer((_) => completer.future);

      await pump(tester, photo: _photo(), onSave: (_, _) {});

      expect(find.text('loading'.tr()), findsOneWidget);
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('로딩이 끝나면 사진 설명에 맞는 카테고리를 자동 선택한다', (tester) async {
      when(() => mockService.fetchFestivals(1)).thenAnswer((_) async => [_festival()]);

      // description이 비어있으면 PhotoDestination.fromDescription이 'other'
      // 카테고리를 자동 선택하므로, 드롭다운은 힌트가 아니라 선택된 라벨을 보여준다.
      await pump(tester, photo: _photo(description: ''), onSave: (_, _) {});

      expect(find.text('photo_category_other'.tr()), findsOneWidget);
    });

    testWidgets('페스티벌 로딩 실패 시 안내 snackbar를 보여준다', (tester) async {
      // pump() 헬퍼가 내부적으로 pumpAndSettle()을 호출하는데, snackbar가 즉시
      // 뜨고 지속시간까지 다 흘러 사라져버리면 검증할 수 없다 — Completer로 시트가
      // 완전히 열린 뒤에 실패를 발생시키고, 프레임 하나만 진행해 등장 직후를 잡는다.
      final completer = Completer<List<FestivalPreview>>();
      when(() => mockService.fetchFestivals(1)).thenAnswer((_) => completer.future);

      await pump(tester, photo: _photo(), onSave: (_, _) {});
      completer.completeError(Exception('network'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('err_fetch_data'.tr()), findsOneWidget);
    });
  });

  group('EditPhotoSheet 저장', () {
    testWidgets('제목이 비어있으면 저장하지 않고 시트가 유지된다', (tester) async {
      var saveCalled = false;
      when(() => mockService.fetchFestivals(1)).thenAnswer((_) async => []);

      await pump(tester, photo: _photo(title: '기존 제목'), onSave: (_, _) => saveCalled = true);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.widgetWithText(LoadingButton, 'save'.tr()));
      await tester.pump();

      expect(saveCalled, isFalse);
      expect(find.byType(EditPhotoSheet), findsOneWidget);
    });

    testWidgets('제목을 입력하고 저장하면 onSave가 호출되고 시트가 닫힌다', (tester) async {
      String? savedTitle;
      String? savedDesc;
      when(() => mockService.fetchFestivals(1)).thenAnswer((_) async => []);

      // description이 daily 카테고리와 일치하면 로드 후 자동으로 그 카테고리가
      // 선택되고, 저장 시에도 동일한 description이 그대로 유지된다.
      await pump(
        tester,
        photo: _photo(title: '기존 제목', description: '일상 사진'),
        onSave: (title, desc) {
          savedTitle = title;
          savedDesc = desc;
        },
      );

      await tester.enterText(find.byType(TextField), '새 제목');
      await tester.tap(find.widgetWithText(LoadingButton, 'save'.tr()));
      await tester.pumpAndSettle();

      expect(savedTitle, '새 제목');
      expect(savedDesc, '일상 사진');
      expect(find.byType(EditPhotoSheet), findsNothing);
    });
  });
}
