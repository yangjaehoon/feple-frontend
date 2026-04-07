import 'dart:ui' as ui;

import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/booth_model.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/foundation.dart' show Factory, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// ── 위젯 ──────────────────────────────────────────────────────────────────────
class FestivalBoothMap extends StatefulWidget {
  final int festivalId;
  final double? festivalLat;
  final double? festivalLng;

  const FestivalBoothMap({
    super.key,
    required this.festivalId,
    this.festivalLat,
    this.festivalLng,
  });

  @override
  State<FestivalBoothMap> createState() => _FestivalBoothMapState();
}

class _FestivalBoothMapState extends State<FestivalBoothMap> {
  List<BoothModel> _booths = [];
  bool _loading = true;
  GoogleMapController? _mapController;
  Position? _userPosition;
  Set<Marker> _markers = {};

  static const _boothHues = {
    'FOOD': 14.0,   // #FF7043 deep orange
    'BEER': 38.0,   // #FFA000 amber
    'EVENT': BitmapDescriptor.hueViolet,
  };

  static const _boothColorValues = {
    'FOOD': Color(0xFFFF7043),
    'BEER': Color(0xFFFFA000),
    'EVENT': Color(0xFF7B1FA2),
  };

  @override
  void initState() {
    super.initState();
    _fetchBooths();
    _getUserLocation();
  }

  Future<void> _fetchBooths() async {
    try {
      final res = await DioClient.dio.get('/festivals/${widget.festivalId}/booths');
      final list = (res.data as List)
          .map((e) => BoothModel.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('[BoothMap] 부스 ${list.length}개 로드됨 (festivalId=${widget.festivalId})');
      if (mounted) {
        setState(() {
          _booths = list;
          _loading = false;
        });
        _buildMarkers().catchError((e) {
          debugPrint('[BoothMap] 마커 생성 오류: $e');
        });
      }
    } catch (e) {
      debugPrint('[BoothMap] API 오류: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<BitmapDescriptor> _markerIcon(BoothModel booth) async {
    final hue = _boothHues[booth.boothType] ?? BitmapDescriptor.hueRed;

    // 웹은 canvas 지원 불안정 → 기본 마커 사용
    if (kIsWeb) return BitmapDescriptor.defaultMarker;

    // 이미지 없으면 색상 핀
    if (booth.imageUrl == null) {
      return BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    try {
      final res = await http.get(Uri.parse(booth.imageUrl!));
      final bytes = res.bodyBytes;

      const w = 80.0, imgH = 60.0, tailH = 12.0;
      const totalH = imgH + tailH;
      final color = _boothColorValues[booth.boothType] ?? const Color(0xFF555555);

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

      // 배경 카드
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, imgH),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, bgPaint);

      // 흰 테두리
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 이미지 (클립)
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

      // 꼬리 삼각형
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
      final byteData = await markerImg.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(hue);
    }
  }

  Future<void> _buildMarkers() async {
    final markers = <Marker>{};
    for (final booth in _booths) {
      final icon = await _markerIcon(booth);
      markers.add(Marker(
        markerId: MarkerId('booth_${booth.id}'),
        position: LatLng(booth.latitude, booth.longitude),
        icon: icon,
        infoWindow: InfoWindow(
          title: booth.name,
          snippet: booth.boothTypeName +
              (booth.description != null ? ' · ${booth.description}' : ''),
        ),
      ));
    }
    if (mounted) setState(() => _markers = markers);
  }

  LatLng get _initialPosition {
    if (widget.festivalLat != null && widget.festivalLng != null) {
      return LatLng(widget.festivalLat!, widget.festivalLng!);
    }
    if (_booths.isNotEmpty) {
      return LatLng(_booths.first.latitude, _booths.first.longitude);
    }
    return const LatLng(37.5665, 126.9780);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.store_rounded, size: 15, color: colors.activate),
                  const SizedBox(width: 8),
                  Text('부스 지도',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textTitle)),
                  const SizedBox(width: 10),
                  // 범례
                  _LegendDot(color: const Color(0xFFFF7043), label: '음식'),
                  const SizedBox(width: 8),
                  _LegendDot(color: const Color(0xFFFFA000), label: '주류'),
                  const SizedBox(width: 8),
                  _LegendDot(color: const Color(0xFF7B1FA2), label: '이벤트'),
                ],
              ),
            ),

            if (_loading)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_booths.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('등록된 부스가 없습니다.',
                      style: TextStyle(color: colors.textSecondary)),
                ),
              )
            else
              SizedBox(
                height: 340,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 17,
                  ),
                  markers: _markers,
                  myLocationEnabled: _userPosition != null,
                  myLocationButtonEnabled: _userPosition != null,
                  onMapCreated: (c) => _mapController = c,
                  zoomControlsEnabled: false,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}
