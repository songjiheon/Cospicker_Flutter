import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cospicker/models/content_type.dart';
import 'package:cospicker/core/constants/app_constants.dart';
import 'package:cospicker/core/utils/logger_util.dart';
import 'package:cospicker/core/utils/error_handler.dart';
import 'package:cospicker/core/utils/env_util.dart';

// 데이터 로딩 상태를 명확히 구분하기 위한 열거형 추가
enum DataStatus { initial, loading, success, failure }

// 콘텐츠 타입 (숙소=32, 맛집=39)을 구분하는 열거형 추가
//enum ContentType { accommodation, restaurant }


// Accommodation 모델 정의 (변경 없음)
class Accommodation {
  final String id;
  final String title;
  final double lat;
  final double lng;
  final String? image;
  final ContentType type; // 마커 색상 구분을 위해 타입 추가

  Accommodation({
    required this.id,
    required this.title,
    required this.lat,
    required this.lng,
    this.image,
    required this.type,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json, ContentType type) {
    return Accommodation(
      id: json['contentid'] ?? '',
      title: json['title'] ?? '제목 없음',
      lat: double.tryParse(json['mapy']?.toString() ?? '0') ?? 0,
      lng: double.tryParse(json['mapx']?.toString() ?? '0') ?? 0,
      image: json['firstimage'],
      type: type,
    );
  }
}

// tour API 호출 함수
Future<List<dynamic>> fetchTourApiLocationBased({
  required double lat,
  required double lng,
  required int contentTypeId, //(맛집 32 /숙소 39)
  int radius = 3000,
  String arrange = "E",
  int numOfRows = 10,
  int pageNo = 1,
}) async {
  final serviceKey = EnvUtil.getServiceKey();
  final mobileOS = EnvUtil.getMobileOS();
  final mobileApp = EnvUtil.getMobileApp();

  final url = Uri.parse(
    "${AppConstants.tourApiBaseUrl}${AppConstants.tourApiEndpoint}"
    "?serviceKey=$serviceKey"
    "&mapX=$lng"
    "&mapY=$lat"
    "&radius=$radius"
    "&arrange=$arrange"
    "&numOfRows=$numOfRows"
    "&pageNo=$pageNo"
    "&contentTypeId=$contentTypeId"
    "&MobileOS=$mobileOS"
    "&MobileApp=$mobileApp"
    "&_type=json",
  );
  AppLogger.d("📡 TourAPI 요청 (ContentType: $contentTypeId): $url");
  try {
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );
    AppLogger.d("📩 Raw API Response: ${response.body}");

    if (response.statusCode != 200) {
      AppLogger.w(
        "Error: HTTP Status ${response.statusCode}, Body: ${response.body}",
      );
      return [];
    }

    // JSON 파싱
    final jsonData = json.decode(response.body);
    final items = jsonData["response"]["body"]["items"];

    if (items == null) {
      AppLogger.w("🔍 TourAPI 응답: items 필드가 비어있습니다.");
      return [];
    }
    // items가 Map인 경우 (데이터가 하나일 때)와 List인 경우를 모두 처리
    final itemData = items["item"];
    if (itemData is List) {
      return itemData;
    } else if (itemData is Map) {
      return [itemData];
    } else {
      return [];
    }
  } catch (e) {
    ErrorHandler.logError(e, context: 'Tour API 호출');
    return [];
  }
}

// 숙소/맛집 정보를 공통으로 가져오는 함수
Future<List<Accommodation>> fetchContent(
  double lat,
  double lng,
  ContentType type,
) async {
  final contentTypeId = (type == ContentType.accommodation) ? 32 : 39;

  final rawList = await fetchTourApiLocationBased(
    lat: lat,
    lng: lng,
    contentTypeId: contentTypeId,
    arrange: "E",
    radius: 2000,
    numOfRows: 50,
  );
  return rawList
      .map((item) => Accommodation.fromJson(item, type))
      .where(
        (acc) =>
            acc.lat != 0 &&
            acc.lng != 0 &&
            acc.image != null &&
            acc.image!.isNotEmpty,
      )
      .toList();
}

class NearMapScreen extends StatefulWidget {
  final ContentType type;

  const NearMapScreen({super.key, required this.type});

  @override
  State<NearMapScreen> createState() => _NearMapScreenState();
}

class _NearMapScreenState extends State<NearMapScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  DataStatus _dataLoadingStatus = DataStatus.initial;
  LatLng? _initialPosition;
  List<Accommodation> _accommodations = [];

  //현재 선택된 콘텐츠 타입 상태
  ContentType _selectedContentType = ContentType.accommodation;

  @override
  void initState() {
    super.initState();
    _selectedContentType = widget.type;
    _determinePosition();
  }

  // 위치 권한 확인 및 초기 위치 설정
  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _initialPosition = const LatLng(37.5665, 126.9780);
        }
      }

      if (_initialPosition == null) {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _initialPosition = LatLng(pos.latitude, pos.longitude);
        AppLogger.d("현재 위치: $_initialPosition");
      }
    } catch (e) {
      ErrorHandler.logError(e, context: '위치 가져오기');
      _initialPosition = const LatLng(37.5665, 126.9780);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // 숙소/맛집 마커 및 목록 로딩
  void _loadMarkers(LatLng pos, ContentType type) async {
    if (_dataLoadingStatus == DataStatus.loading) return;

    // 타입이 같을 시 로딩 x
    if (_dataLoadingStatus == DataStatus.success &&
        _selectedContentType == type)
      return;

    if (!mounted) return;
    setState(() {
      _dataLoadingStatus = DataStatus.loading; // 로딩 시작
      _selectedContentType = type; // 선택된 타입 업데이트
    });

    try {
      final accommodations = await fetchContent(
        pos.latitude,
        pos.longitude,
        type,
      );

      if (!mounted) return;

      setState(() {
        _accommodations = accommodations;
        _markers = accommodations.map((acc) {
          // 타입에 따라 마커 색상 구분
          final hue = acc.type == ContentType.accommodation
              ? BitmapDescriptor
                    .hueAzure // 숙소: 하늘색
              : BitmapDescriptor.hueRed; // 맛집: 빨간색

          return Marker(
            markerId: MarkerId(acc.id),
            position: LatLng(acc.lat, acc.lng),
            infoWindow: InfoWindow(title: acc.title),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          );
        }).toSet();
        _dataLoadingStatus = DataStatus.success; // 로딩 완료
      });
      AppLogger.d("총 마커 개수: ${_markers.length} (로딩 완료)");
    } catch (e) {
      if (mounted) {
        setState(() {
          _dataLoadingStatus = DataStatus.failure; // 로딩 실패
        });
      }
      ErrorHandler.logError(e, context: '마커 로딩');
    }
  }

  //  콘텐츠 타입을 전환하고 마커를 다시 로드하는 함수
  void _switchContentType(ContentType newType) {
    if (_selectedContentType == newType) return;

    if (_initialPosition != null) {
      _loadMarkers(_initialPosition!, newType);
    }
  }

  // 현재 위치로 이동 하는 버튼
  void _moveToCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16),
        ),
      );

      // 위치 이동 후 현재 타입으로 마커를 다시 로드 (혹시 위치가 바뀌었을 경우 대비)
      _loadMarkers(LatLng(pos.latitude, pos.longitude), _selectedContentType);
    } catch (e) {
      ErrorHandler.logError(e, context: '현재 위치로 이동');
      if (mounted) {
        ErrorHandler.handleError(context, e);
      }
    }
  }

  // DraggableScrollableSheet 내부에서 사용될 숙소/맛집 목록 위젯
  Widget _buildAccommodationList(ScrollController scrollController) {
    final typeName = _selectedContentType == ContentType.accommodation
        ? '숙소'
        : '맛집';

    // 로딩 및 초기 상태
    if (_dataLoadingStatus == DataStatus.loading ||
        _dataLoadingStatus == DataStatus.initial) {
      return Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: _selectedContentType == ContentType.accommodation
                    ? Colors.blueAccent
                    : Colors.redAccent,
              ),
            ),
          ),
        ],
      );
    }

    // 데이터 없음 상태
    if (_accommodations.isEmpty && _dataLoadingStatus == DataStatus.success) {
      return Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  '주변 2km 이내에 이미지가 있는 $typeName 정보가 없습니다. 지도를 이동하여 다시 검색해보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_dataLoadingStatus == DataStatus.failure) {
      return Container();
    }
    // 성공 및 목록 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDragHandle(),
        // 제목
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          child: Text(
            '주변 $typeName 목록 (${_accommodations.length}개)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        // 숙소/맛집 리스트
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: _accommodations.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              final acc = _accommodations[index];

              // 항목 간 구분선 추가
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        acc.image!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            acc.type == ContentType.accommodation
                                ? Icons.hotel
                                : Icons.restaurant,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      acc.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${acc.type == ContentType.accommodation ? '숙소' : '맛집'} ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // 리스트 항목을 탭하면 해당 마커 위치로 지도를 이동
                      _controller?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(acc.lat, acc.lng),
                            zoom: 16,
                          ),
                        ),
                      );
                    },
                  ),
                  // 항목 하단에 얇은 구분선 추가
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // 드래그 핸들 위젯 분리
  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // 콘텐츠 타입 전환 버튼 위젯 (숙소/맛집)
  Widget _buildContentButton(ContentType type, String label, IconData icon) {
    final isSelected = _selectedContentType == type;
    final color = type == ContentType.accommodation
        ? Colors.blueAccent
        : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(25),
        elevation: 4,
        child: InkWell(
          onTap: () => _switchContentType(type),
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isSelected ? Colors.white : color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialPosition == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 마커 및 로딩 시작합니다.
    _loadMarkers(_initialPosition!, _selectedContentType);

    return Scaffold(
      extendBodyBehindAppBar: true, // AppBar 영역까지 지도 확장
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Google Map (전체 화면 배경)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition!,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            onMapCreated: (controller) => _controller = controller,
            // 맵 이동이 끝났을 때 현재 지도 중앙 기준으로 다시 로드
            onCameraIdle: () {
              // 카메라 이동이 끝났을 때 처리 (필요시 구현)
              // _controller?.getVisibleRegion().then((LatLngBounds bounds) {
              //   final centerLat =
              //       (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
              //   final centerLng =
              //       (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
              //   // 현재 지도의 중심 위치를 기준으로 다시 검색 (중앙 위치가 이전과 크게 바뀌었을 때)
              // });
            },
          ),

          // 2. 지도 상단 (상단 좌측: 타이틀, 상단 우측: 버튼 그룹)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildContentButton(
                            ContentType.accommodation,
                            '숙소',
                            Icons.hotel_rounded,
                          ),
                          _buildContentButton(
                            ContentType.restaurant,
                            '맛집',
                            Icons.restaurant_menu_rounded,
                          ),
                        ],
                      ),
                      // 현재 위치 버튼 (FAB 스타일 적용)
                      FloatingActionButton.small(
                        heroTag: 'locationButton',
                        onPressed: _moveToCurrentLocation,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueGrey,
                        elevation: 4,
                        child: const Icon(Icons.my_location_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          //숙소 목록 (끌어올릴 수 있는 숙소 목록)
          DraggableScrollableSheet(
            initialChildSize: 0.2, // 초기 높이 조정
            minChildSize: 0.1,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.15, 0.45, 0.9], // 중간 스냅 포인트 추가
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildAccommodationList(scrollController),
              );
            },
          ),
        ],
      ),
    );
  }
}
