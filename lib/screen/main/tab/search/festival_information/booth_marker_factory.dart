import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:feple/common/constant/app_colors.dart';
import 'package:feple/model/booth_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class _BoothTypeStyle {
  final double hue;
  final Color color;

  const _BoothTypeStyle(this.hue, this.color);
}

/// 부스 썸네일을 담은 커스텀 지도 마커 비트맵을 만든다.
/// 이미지가 없거나(웹 포함) 조회/합성이 실패하면 부스 타입 색상의 기본 핀으로 폴백.
class BoothMarkerFactory {
  BoothMarkerFactory._();

  static const _boothStyles = {
    'FOOD': _BoothTypeStyle(14.0, AppColors.boothFood),
    'BEER': _BoothTypeStyle(38.0, AppColors.boothAlcohol),
    'EVENT': _BoothTypeStyle(BitmapDescriptor.hueViolet, AppColors.boothEvent),
  };

  // 마커 도형 치수 (논리 픽셀)
  static const _cardWidth = 80.0;
  static const _cardHeight = 60.0;
  static const _tailHeight = 12.0;
  static const _totalHeight = _cardHeight + _tailHeight;
  static const _cornerRadius = 8.0;
  static const _innerCornerRadius = 6.0;
  static const _innerInset = 2.0;
  static const _borderWidth = 2.0;
  static const _tailHalfWidth = 8.0;
  static const _fetchTimeout = Duration(seconds: 5);

  static Future<BitmapDescriptor> create(BoothModel booth) async {
    final style = _boothStyles[booth.boothType];
    final hue = style?.hue ?? BitmapDescriptor.hueRed;
    final fallback = BitmapDescriptor.defaultMarkerWithHue(hue);

    if (kIsWeb) return BitmapDescriptor.defaultMarker;
    if (booth.imageUrl == null) return fallback;

    try {
      final bytes = await _fetchImageBytes(booth.imageUrl!);
      if (bytes == null) return fallback;

      final thumbnail = await _decodeThumbnail(bytes);
      try {
        return await _composeMarker(
          thumbnail,
          style?.color ?? AppColors.markerGray,
        );
      } finally {
        thumbnail.dispose();
      }
    } catch (_) {
      return fallback;
    }
  }

  static Future<Uint8List?> _fetchImageBytes(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(_fetchTimeout);
    return res.statusCode == 200 ? res.bodyBytes : null;
  }

  static Future<ui.Image> _decodeThumbnail(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _cardWidth.toInt(),
      targetHeight: _cardHeight.toInt(),
    );
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  /// 썸네일을 둥근 카드 + 테두리 + 아래쪽 꼬리 삼각형으로 감싸 PNG 마커로 인코딩.
  static Future<BitmapDescriptor> _composeMarker(
    ui.Image thumbnail,
    Color cardColor,
  ) async {
    final recorder = ui.PictureRecorder();
    _paintCard(Canvas(recorder), thumbnail, cardColor);
    final picture = recorder.endRecording();

    ui.Image? markerImage;
    try {
      markerImage = await picture.toImage(
        _cardWidth.toInt(),
        _totalHeight.toInt(),
      );
      final png = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw StateError('marker PNG encode returned null');
      }
      return BitmapDescriptor.bytes(png.buffer.asUint8List());
    } finally {
      picture.dispose();
      markerImage?.dispose();
    }
  }

  static void _paintCard(Canvas canvas, ui.Image thumbnail, Color cardColor) {
    final cardPaint = Paint()..color = cardColor;
    final cardRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, _cardWidth, _cardHeight),
      const Radius.circular(_cornerRadius),
    );

    canvas.drawRRect(cardRRect, cardPaint);
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );

    final imageRect = Rect.fromLTWH(
      _innerInset,
      _innerInset,
      _cardWidth - _innerInset * 2,
      _cardHeight - _innerInset * 2,
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      imageRect,
      const Radius.circular(_innerCornerRadius),
    ));
    canvas.drawImageRect(
      thumbnail,
      Rect.fromLTWH(
        0,
        0,
        thumbnail.width.toDouble(),
        thumbnail.height.toDouble(),
      ),
      imageRect,
      Paint(),
    );
    canvas.restore();

    canvas.drawPath(
      Path()
        ..moveTo(_cardWidth / 2 - _tailHalfWidth, _cardHeight)
        ..lineTo(_cardWidth / 2 + _tailHalfWidth, _cardHeight)
        ..lineTo(_cardWidth / 2, _totalHeight)
        ..close(),
      cardPaint,
    );
  }
}
