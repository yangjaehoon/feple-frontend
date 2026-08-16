import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 화면에 보이지 않는 위치에 위젯을 잠깐 마운트해서 PNG 이미지로 캡처한다.
/// 위젯이 네트워크 이미지를 포함한다면 호출 전에 precacheImage로 미리 로드해둬야
/// 캡처 시점에 로딩 플레이스홀더가 아닌 실제 이미지가 그려진다.
Future<Uint8List?> captureWidgetAsPng(
  BuildContext context,
  Widget widget, {
  double pixelRatio = 3.0,
}) async {
  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -9999,
      top: -9999,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: boundaryKey, child: widget),
      ),
    ),
  );
  overlay.insert(entry);

  try {
    // 오버레이가 실제로 레이아웃/페인트될 시간을 준다
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}
