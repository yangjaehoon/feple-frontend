import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/permission_rationale.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/booth_model.dart';
import 'package:feple/service/festival_detail_service.dart';
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
  State<FestivalBoothMap> createState() => FestivalBoothMapState();
}

class FestivalBoothMapState extends State<FestivalBoothMap> {
  Future<void> refresh() => _fetchBooths();
  List<BoothModel> _booths = [];
  bool _isLoading = true;
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
    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    try {
      final list = await sl<FestivalDetailService>().fetchBooths(widget.festivalId);
      debugPrint('[BoothMap] 부스 ${list.length}개 로드됨 (festivalId=${widget.festivalId})');
      if (mounted) {
        setState(() {
          _booths = list;
          _isLoading = false;
        });
        try {
          await _buildMarkers();
        } catch (e) {
          debugPrint('[BoothMap] 마커 생성 오류: $e');
        }
      }
    } catch (e) {
      debugPrint('[BoothMap] API 오류: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) return;

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        final proceed = await PermissionRationale.showLocation(context);
        if (!proceed) return;
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _userPosition = pos);
    } catch (e) {
      debugPrint('[BoothMap] 위치 정보 로드 실패: $e');
    }
  }

  Future<void> _buildMarkers() async {
    // await 도중 refresh()가 다시 호출되면 _booths 필드가 새 리스트로
    // 재할당될 수 있어 로컬로 스냅샷을 캡처 — 아래에서 계속 이 스냅샷만 사용
    final booths = _booths;
    // 부스마다 이미지 다운로드+마커 생성이 독립적이므로 병렬로 처리 —
    // 순차 await는 부스 수만큼 네트워크 왕복 시간이 그대로 누적됨
    final icons = await Future.wait(booths.map(BoothMarkerFactory.create));
    final markers = <Marker>{
      for (var i = 0; i < booths.length; i++)
        Marker(
          markerId: MarkerId('booth_${booths[i].id}'),
          position: LatLng(booths[i].latitude, booths[i].longitude),
          icon: icons[i],
          infoWindow: InfoWindow(
            title: booths[i].name,
            snippet: booths[i].boothTypeName +
                (booths[i].description != null ? ' · ${booths[i].description}' : ''),
          ),
        ),
    };
    // 마커 계산이 끝나기 전에 새로운 fetch가 _booths를 이미 교체했다면
    // 이 결과는 낡은 스냅샷 기준이므로 버린다 — 그 fetch의 _buildMarkers()가
    // 곧 올바른 마커로 다시 채운다.
    if (mounted && identical(_booths, booths)) setState(() => _markers = markers);
  }

  bool get _hasKnownLocation =>
      (widget.festivalLat != null && widget.festivalLng != null) || _booths.isNotEmpty;

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
          _buildBody(),
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
                  fontSize: AppDimens.fontSizeLg,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle)),
          // 등록된 부스가 있을 때만 범례를 보여준다 — 빈 상태에서 색상 범례부터
          // 먼저 보여주면 아직 아무것도 없는데 뭔가 있는 것처럼 앞서가 보임
          if (_booths.isNotEmpty) ...[
            const SizedBox(width: 10),
            _LegendDot(color: AppColors.boothFood, label: 'booth_food'.tr()),
            const SizedBox(width: 8),
            _LegendDot(color: AppColors.boothAlcohol, label: 'booth_alcohol'.tr()),
            const SizedBox(width: 8),
            _LegendDot(color: AppColors.boothEvent, label: 'booth_event'.tr()),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeleton();
    }
    if (_hasError) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).width * 0.513, // 200/390
        child: ErrorState(message: 'load_error'.tr(), onRetry: _fetchBooths),
      );
    }
    // 페스티벌 좌표도, 부스도 없어 지도를 그릴 근거가 전혀 없는 경우 —
    // 이럴 때 임의 좌표(서울시청)를 실제 위치처럼 보여주면 사용자를 오도한다.
    if (!_hasKnownLocation) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('booth_map_location_unavailable'.tr(),
              style: TextStyle(color: context.appColors.textSecondary)),
        ),
      );
    }
    // 부스가 없어도 페스티벌 위치를 중심으로 지도는 보여준다 (마커만 없음)
    return _buildMap();
  }

  Widget _buildSkeleton() {
    final skeletonHeight = MediaQuery.sizeOf(context).width * 0.769; // 300/390
    return SizedBox(
      height: skeletonHeight,
      child: Stack(
        children: [
          SkeletonBox(height: skeletonHeight, borderRadius: BorderRadius.zero),
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

  Widget _buildMap() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).width * 0.872, // 340/390
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
        // SingleChildScrollView 안에 있어 EagerGestureRecognizer 없이는
        // 지도 팬/줌 제스처가 부모 스크롤과 경쟁하다 묻힘 — 제거 금지
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
                fontSize: AppDimens.fontSizeXxs,
                color: context.appColors.textSecondary)),
      ],
    );
  }
}
