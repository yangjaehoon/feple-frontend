import 'package:feple/common/common.dart';
import 'package:feple/model/booth_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'booth_marker_factory.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchBooths();
    _getUserLocation();
  }

  Future<void> _fetchBooths() async {
    try {
      final res =
          await DioClient.dio.get('/festivals/${widget.festivalId}/booths');
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
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<void> _buildMarkers() async {
    final markers = <Marker>{};
    for (final booth in _booths) {
      final icon = await BoothMarkerFactory.create(booth);
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
      ],
    );
  }
}
