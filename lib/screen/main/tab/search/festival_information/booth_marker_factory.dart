import 'dart:ui' as ui;

import 'package:feple/model/booth_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class BoothMarkerFactory {
  BoothMarkerFactory._();

  static const _boothHues = {
    'FOOD': 14.0,
    'BEER': 38.0,
    'EVENT': BitmapDescriptor.hueViolet,
  };

  static const _boothColorValues = {
    'FOOD': Color(0xFFFF7043),
    'BEER': Color(0xFFFFA000),
    'EVENT': Color(0xFF7B1FA2),
  };

  static Future<BitmapDescriptor> create(BoothModel booth) async {
    final hue = _boothHues[booth.boothType] ?? BitmapDescriptor.hueRed;

    if (kIsWeb) return BitmapDescriptor.defaultMarker;

    if (booth.imageUrl == null) {
      return BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    try {
      final res = await http.get(Uri.parse(booth.imageUrl!));
      final bytes = res.bodyBytes;

      const w = 80.0, imgH = 60.0, tailH = 12.0;
      const totalH = imgH + tailH;
      final color =
          _boothColorValues[booth.boothType] ?? const Color(0xFF555555);

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: w.toInt(),
        targetHeight: imgH.toInt(),
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final bgPaint = Paint()..color = color;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, imgH),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, w - 4, imgH - 4),
        const Radius.circular(6),
      ));
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(2, 2, w - 4, imgH - 4),
        Paint(),
      );
      canvas.restore();

      canvas.drawPath(
        Path()
          ..moveTo(w / 2 - 8, imgH)
          ..lineTo(w / 2 + 8, imgH)
          ..lineTo(w / 2, totalH)
          ..close(),
        bgPaint,
      );

      final picture = recorder.endRecording();
      final markerImg = await picture.toImage(w.toInt(), totalH.toInt());
      final byteData =
          await markerImg.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(hue);
    }
  }
}
