import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:propedia/core/constants/app_colors.dart';
import 'package:propedia/presentation/providers/building_provider.dart';
import 'package:propedia/presentation/providers/map_provider.dart';
import 'package:propedia/presentation/widgets/common/app_footer.dart';

class SearchMapScreen extends ConsumerStatefulWidget {
  const SearchMapScreen({super.key});

  @override
  ConsumerState<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends ConsumerState<SearchMapScreen> {
  KakaoMapController? _mapController;
  Set<Polygon> _polygons = {};
  bool _isMapReady = false;
  String? _mapError;

  // 기본 위치 (서울시청)
  static const _defaultLat = 37.5665;
  static const _defaultLng = 126.9780;

  @override
  void dispose() {
    ref.read(mapSearchProvider.notifier).resetState();
    super.dispose();
  }

  /// 필지 경계 폴리곤 업데이트
  void _updatePolygon(MapSearchState mapState) {
    if (mapState.parcelGeometry != null) {
      final geometry = mapState.parcelGeometry!;
      final coordinates = geometry.coordinates;

      List<LatLng> path = [];

      try {
        if (geometry.type == 'Polygon' && coordinates.isNotEmpty) {
          // Polygon: coordinates[0]이 외곽선
          final ring = coordinates[0] as List;
          for (var coord in ring) {
            if (coord is List && coord.length >= 2) {
              path.add(LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ));
            }
          }
        } else if (geometry.type == 'MultiPolygon' && coordinates.isNotEmpty) {
          // MultiPolygon: coordinates[0][0]이 첫 번째 폴리곤의 외곽선
          final firstPolygon = coordinates[0] as List;
          if (firstPolygon.isNotEmpty) {
            final ring = firstPolygon[0] as List;
            for (var coord in ring) {
              if (coord is List && coord.length >= 2) {
                path.add(LatLng(
                  (coord[1] as num).toDouble(),
                  (coord[0] as num).toDouble(),
                ));
              }
            }
          }
        }
      } catch (e) {
        debugPrint('❌ 폴리곤 파싱 오류: $e');
      }

      if (path.isNotEmpty) {
        setState(() {
          _polygons = {
            Polygon(
              polygonId: 'parcel',
              points: path,
              strokeColor: AppColors.primary,
              strokeWidth: 3,
              fillColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          };
        });
        debugPrint('✅ 폴리곤 표시: ${path.length}개 점');
      }
    } else {
      // 폴리곤 제거
      if (_polygons.isNotEmpty) {
        setState(() {
          _polygons = {};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapSearchProvider);
    final currentLocation = ref.watch(currentLocationProvider);

    // 상태 변경 시 폴리곤 업데이트
    ref.listen<MapSearchState>(mapSearchProvider, (previous, next) {
      if (next.status == SearchStatus.success) {
        _updatePolygon(next);
      } else if (next.status == SearchStatus.initial || next.status == SearchStatus.error) {
        // 초기화 또는 에러 시 폴리곤 제거
        if (_polygons.isNotEmpty) {
          setState(() {
            _polygons = {};
          });
        }
      }
    });

    // Web은 미지원
    if (kIsWeb) {
      return _buildWebFallback(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('지도에서 검색'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 지도 영역 (카드 스타일)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // 카카오맵
                      KakaoMap(
                        onMapCreated: (controller) {
                          debugPrint('🗺️ 카카오맵 생성됨');
                          _mapController = controller;
                          setState(() {
                            _isMapReady = true;
                            _mapError = null;
                          });
                          // 현재 위치로 이동
                          currentLocation.whenData((position) {
                            if (position != null) {
                              _moveToLocation(position.latitude, position.longitude);
                            }
                          });
                        },
                        onMapTap: _onMapTap,
                        center: LatLng(_defaultLat, _defaultLng),
                        polygons: _polygons.toList(),
                      ),

                      // 지도 로딩 중
                      if (!_isMapReady && _mapError == null)
                        Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('지도 로딩 중...'),
                              ],
                            ),
                          ),
                        ),

                      // 현재 위치 버튼
                      if (_isMapReady)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FloatingActionButton(
                            heroTag: 'currentLocation',
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: _moveToCurrentLocation,
                            child: const Icon(
                              Icons.my_location,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 정보 영역
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildBottomSection(context, mapState),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooterSimple(),
    );
  }

  Widget _buildBottomSection(BuildContext context, MapSearchState mapState) {
    // 로딩 중
    if (mapState.status == SearchStatus.loading) {
      return const Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 에러
    if (mapState.status == SearchStatus.error && mapState.errorMessage != null) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                mapState.errorMessage!,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 지번 정보가 있는 경우
    if (mapState.jibunInfo != null) {
      return _buildInfoCard(context, mapState);
    }

    // 초기 상태 (안내 메시지)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '지도를 탭하여 위치를 선택하세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '선택한 위치의 토지/건물 정보를 조회할 수 있습니다',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFallback(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도에서 검색'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                '지도 검색은 모바일 앱에서만 지원됩니다',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Android 또는 iOS 앱을 사용해주세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooterSimple(),
    );
  }

  Widget _buildInfoCard(BuildContext context, MapSearchState mapState) {
    final jibunInfo = mapState.jibunInfo!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주소
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    jibunInfo.landTypeName ?? (jibunInfo.landType == '1' ? '대' : '임'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    jibunInfo.address,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 도로명 주소
            if (jibunInfo.roadAddress != null && jibunInfo.roadAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '도로명: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Expanded(
                      child: Text(
                        jibunInfo.roadAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[800],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // 주용도
            if (jibunInfo.mainPurpose != null && jibunInfo.mainPurpose!.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주용도: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Expanded(
                    child: Text(
                      jibunInfo.mainPurpose!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[800],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            const Spacer(),

            // 조회하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _onSearchBuilding(jibunInfo),
                icon: const Icon(Icons.search),
                label: const Text('조회하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapTap(LatLng latLng) async {
    debugPrint('🗺️ 지도 탭: ${latLng.latitude}, ${latLng.longitude}');

    // 컨트롤러를 통해 마커 업데이트
    if (_mapController != null) {
      // 기존 마커 제거 후 새 마커 추가
      await _mapController!.clearMarker();
      await _mapController!.addMarker(
        markers: [
          Marker(
            markerId: 'selected',
            latLng: latLng,
          ),
        ],
      );
    }

    // 폴리곤 제거
    if (_polygons.isNotEmpty) {
      setState(() {
        _polygons = {};
      });
    }

    // 지도 중심 이동
    _moveToLocation(latLng.latitude, latLng.longitude);

    // 좌표로 검색
    ref.read(mapSearchProvider.notifier).searchByCoordinate(
          latLng.latitude,
          latLng.longitude,
        );
  }

  void _moveToLocation(double lat, double lng) {
    _mapController?.setCenter(LatLng(lat, lng));
  }

  void _moveToCurrentLocation() async {
    final location = ref.read(currentLocationProvider);
    location.whenData((position) {
      if (position != null) {
        _moveToLocation(position.latitude, position.longitude);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치를 가져올 수 없습니다')),
        );
      }
    });

    // 현재 위치 다시 가져오기
    ref.invalidate(currentLocationProvider);
  }

  void _onSearchBuilding(jibunInfo) {
    // 건물 검색 provider로 검색
    ref.read(buildingSearchProvider.notifier).searchByJibun(
          bjdongCode: jibunInfo.bjdongCode,
          bun: jibunInfo.bun,
          ji: jibunInfo.ji,
          landType: jibunInfo.landType,
        );

    // 결과 화면으로 이동
    context.push('/result');
  }
}
