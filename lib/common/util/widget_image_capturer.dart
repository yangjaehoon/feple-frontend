import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 화면 밖 오프셋 — 어떤 화면 크기/배율에서도 보이지 않도록 충분히 크게 잡는다.
const double _offscreenOffset = 10000;

/// 캡처 대상이 실제로 페인트를 마칠 때까지 기다리는 최대 프레임 수.
/// (네트워크 이미지 디코드 등으로 첫 프레임에 페인트가 안 끝날 수 있음)
const int _maxPaintWaitFrames = 10;

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
      left: -_offscreenOffset,
      top: -_offscreenOffset,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: boundaryKey, child: widget),
      ),
    ),
  );
  overlay.insert(entry);

  try {
    // 고정 프레임 수("2번이면 되겠지")를 추측하는 대신, boundary가 실제로
    // 페인트를 마칠 때까지(또는 상한까지) 기다린다 — 느린 첫 프레임에 빈 PNG가
    // 나오는 것을 방지.
    RenderRepaintBoundary? boundary;
    for (var i = 0; i < _maxPaintWaitFrames; i++) {
      await WidgetsBinding.instance.endOfFrame;
      boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) break;
    }
    if (boundary == null || boundary.debugNeedsPaint) return null;

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
