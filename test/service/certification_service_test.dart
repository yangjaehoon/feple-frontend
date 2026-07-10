import 'dart:io';
import 'package:feple/model/certification_model.dart';
import 'package:feple/network/api_cache_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = CertificationService();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null,
    );
    HttpOverrides.global = null;
    await server.start();
    DioClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  setUp(() => ApiCacheStore.clearForTesting());

  tearDownAll(() => server.shutdown());

  const certJson = '{"id":1,"festivalId":10,"status":"APPROVED",'
      '"festivalTitle":"RockFest","festivalTitleEn":"RockFest"}';

  group('CertificationService', () {
    // ── getPublicCertifications ────────────────────────────────────────────

    test('getPublicCertifications parses certification list', () async {
      server.enqueue(
        body: '[$certJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final certs = await service.getPublicCertifications(1);

      expect(certs.length, 1);
      expect(certs.first.id, 1);
      expect(certs.first.festivalId, 10);
      expect(certs.first.status, CertStatus.approved);
    });

    test('getPublicCertifications returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.getPublicCertifications(1), isEmpty);
    });

    // ── getMyCertifications ────────────────────────────────────────────────

    test('getMyCertifications parses certification list', () async {
      server.enqueue(
        body: '[$certJson]',
        headers: {'Content-Type': 'application/json'},
      );

      final certs = await service.getMyCertifications();

      expect(certs.length, 1);
      expect(certs.first.status, CertStatus.approved);
    });

    // ── getCertState ───────────────────────────────────────────────────────

    test('getCertState NONE returns CertStateResult.none', () async {
      server.enqueue(
        body: '{"certState":"NONE"}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.getCertState(10);

      expect(result.status, isNull);
      expect(result.certId, isNull);
    });

    test('getCertState APPROVED parses certId and rating', () async {
      server.enqueue(
        body: '{"certState":"APPROVED","certId":42,"myRating":4,"myReview":"great"}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.getCertState(10);

      expect(result.status, CertStatus.approved);
      expect(result.certId, 42);
      expect(result.myRating, 4);
      expect(result.myReview, 'great');
    });

    test('getCertState null certState treated as NONE', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.getCertState(10);

      expect(result.status, isNull);
    });

    // ── submitRating ───────────────────────────────────────────────────────

    test('submitRating completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.submitRating(1, 5, 'good'), completes);
    });

    // ── getFestivalReviews ─────────────────────────────────────────────────

    test('getFestivalReviews parses review page', () async {
      server.enqueue(
        body: '{"averageRating":4.5,"ratingCount":10,'
            '"distribution":{"5":6,"4":4},'
            '"reviews":[{"reviewId":1,"nickname":"tester","rating":5,"likeCount":2,"likedByMe":false}],'
            '"hasNext":false}',
        headers: {'Content-Type': 'application/json'},
      );

      final page = await service.getFestivalReviews(1);

      expect(page.averageRating, 4.5);
      expect(page.ratingCount, 10);
      expect(page.distribution[5], 6);
      expect(page.reviews.length, 1);
      expect(page.reviews.first.nickname, 'tester');
      expect(page.hasNext, false);
    });

    // ── toggleReviewLike ───────────────────────────────────────────────────

    test('toggleReviewLike returns true when liked', () async {
      server.enqueue(
        body: '{"liked":true}',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.toggleReviewLike(1), true);
    });

    test('toggleReviewLike returns false when unliked', () async {
      server.enqueue(
        body: '{"liked":false}',
        headers: {'Content-Type': 'application/json'},
      );

      expect(await service.toggleReviewLike(1), false);
    });

    // ── getFestivalRating ──────────────────────────────────────────────────

    test('getFestivalRating parses average and count', () async {
      server.enqueue(
        body: '{"averageRating":3.8,"ratingCount":25}',
        headers: {'Content-Type': 'application/json'},
      );

      final rating = await service.getFestivalRating(1);

      expect(rating.averageRating, 3.8);
      expect(rating.ratingCount, 25);
    });

    test('getFestivalRating uses defaults when null', () async {
      server.enqueue(
        body: '{}',
        headers: {'Content-Type': 'application/json'},
      );

      final rating = await service.getFestivalRating(1);

      expect(rating.averageRating, 0.0);
      expect(rating.ratingCount, 0);
    });
  });
}
