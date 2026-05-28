import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/booth_model.dart';
import 'package:feple/service/festival_service.dart';
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
  bool _hasError = false;
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
    if (mounted) setState(() { _loading = true; _hasError = false; });
    try {
      final list = await sl<FestivalService>().fetchBooths(widget.festivalId);
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
      if (mounted) setState(() { _loading = false; _hasError = true; });
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
    } catch (e) {
      debugPrint('[BoothMap] 위치 정보 로드 실패: $e');
    }
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

    return SurfaceCard(
      margin: const EdgeInsets.all(AppDimens.paddingHorizontal),
      shadowAlpha: 0.1,
      clipContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          _buildBody(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Icon(Icons.store_rounded, size: 15, color: colors.activate),
          const SizedBox(width: 8),
          Text('booth_map_title'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle)),
          const SizedBox(width: 10),
          _LegendDot(color: AppColors.boothFood, label: 'booth_food'.tr()),
          const SizedBox(width: 8),
          _LegendDot(color: AppColors.boothAlcohol, label: 'booth_alcohol'.tr()),
          const SizedBox(width: 8),
          _LegendDot(color: AppColors.boothEvent, label: 'booth_event'.tr()),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    if (_loading) {
      return _buildSkeleton();
    }
    if (_hasError) {
      return _buildErrorState(colors);
    }
    if (_booths.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('no_booth'.tr(),
              style: TextStyle(color: colors.textSecondary)),
        ),
      );
    }
    return _buildMap();
  }

  Widget _buildSkeleton() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          const SkeletonBox(height: 300, borderRadius: BorderRadius.zero),
          const Positioned(
            top: 70, left: 60,
            child: SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
          const Positioned(
            top: 140, left: 180,
            child: SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
          const Positioned(
            top: 200, left: 110,
            child: SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AbstractThemeColors colors) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40,
                color: colors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text('load_error'.tr(),
                style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchBooths,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
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
