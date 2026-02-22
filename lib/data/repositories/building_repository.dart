import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:propedia/data/datasources/remote/building_api.dart';
import 'package:propedia/data/dto/building_dto.dart';

class BuildingRepository {
  final BuildingApi _buildingApi;

  BuildingRepository({required BuildingApi buildingApi})
      : _buildingApi = buildingApi;

  /// 도로명 주소로 검색
  Future<RoadSearchResponse> searchByRoad(String roadName) async {
    try {
      debugPrint('📡 API 호출: searchByRoad($roadName)');
      final request = RoadSearchRequest(roadName: roadName);
      final response = await _buildingApi.searchByRoad(request);
      debugPrint('📡 API 응답: success=${response.success}');
      return response;
    } on DioException catch (e) {
      debugPrint('📡 API DioException: ${e.type} - ${e.message}');
      debugPrint('📡 Response: ${e.response?.data}');
      final message = e.response?.data?['error'] ?? '검색 중 오류가 발생했습니다';
      throw Exception(message);
    }
  }

  /// 지번 주소로 검색
  Future<BuildingSearchResponse> searchByJibun({
    required String bjdongCode,
    required String bun,
    String ji = '0000',
    String landType = '1',
  }) async {
    try {
      final request = JibunSearchRequest(
        bjdongCode: bjdongCode,
        bun: bun,
        ji: ji,
        landType: landType,
      );
      return await _buildingApi.searchByJibun(request);
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? '검색 중 오류가 발생했습니다';
      throw Exception(message);
    }
  }

  /// 건물관리번호로 검색 (도로명 검색 결과에서 선택 시)
  Future<BuildingSearchResponse> searchByBdMgtSn(
    String bdMgtSn, {
    String? lnbrMnnm,
    String? lnbrSlno,
  }) async {
    try {
      debugPrint('📡 API 호출: searchByBdMgtSn($bdMgtSn, lnbrMnnm=$lnbrMnnm, lnbrSlno=$lnbrSlno)');
      final request = BdMgtSnSearchRequest(
        bdMgtSn: bdMgtSn,
        lnbrMnnm: lnbrMnnm,
        lnbrSlno: lnbrSlno,
      );
      final response = await _buildingApi.searchByBdMgtSn(request);
      debugPrint('📡 API 응답: success=${response.success}');
      if (response.building != null) {
        debugPrint('📡 Building type: ${response.building?.type}');
        debugPrint('📡 dongHoDict keys: ${response.building?.dongHoDict?.keys.toList()}');
        if (response.building?.dongHoDict != null) {
          response.building!.dongHoDict!.forEach((dong, hoList) {
            debugPrint('📡 동[$dong] 호수 목록 (${hoList is List ? hoList.length : 0}개): ${hoList is List ? hoList.take(3).toList() : hoList}...');
          });
        }
      }
      return response;
    } on DioException catch (e) {
      debugPrint('📡 API DioException: ${e.type} - ${e.message}');
      final message = e.response?.data?['error'] ?? '검색 중 오류가 발생했습니다';
      throw Exception(message);
    }
  }

  /// 대지와 임야 모두 검색하여 존재하는 결과 반환
  ///
  /// 지번 검색 시 대지(landType='1')와 임야(landType='2') 양쪽 모두 검색하여
  /// 실제로 데이터가 존재하는 결과만 반환합니다.
  Future<List<LandTypeSearchResult>> searchBothLandTypes({
    required String bjdongCode,
    required String bun,
    String ji = '0',
  }) async {
    try {
      debugPrint('📡 양쪽 토지 유형 검색: bjdong=$bjdongCode, bun=$bun, ji=$ji');

      // 대지와 임야 동시 검색
      final results = await Future.wait([
        _searchByJibunSafe(bjdongCode: bjdongCode, bun: bun, ji: ji, landType: '1'),
        _searchByJibunSafe(bjdongCode: bjdongCode, bun: bun, ji: ji, landType: '2'),
      ]);

      final validResults = <LandTypeSearchResult>[];

      // 대지 결과 확인 - success이고 실제 데이터가 있는지 체크
      if (results[0] != null && _hasValidData(results[0]!)) {
        debugPrint('✅ 대지 검색 성공 (실제 데이터 있음)');
        validResults.add(LandTypeSearchResult(
          landType: '1',
          landTypeName: '대지',
          response: results[0]!,
        ));
      } else {
        debugPrint('ℹ️ 대지 검색: 데이터 없음');
      }

      // 임야 결과 확인 - success이고 실제 데이터가 있는지 체크
      if (results[1] != null && _hasValidData(results[1]!)) {
        debugPrint('✅ 임야 검색 성공 (실제 데이터 있음)');
        validResults.add(LandTypeSearchResult(
          landType: '2',
          landTypeName: '임야 (산)',
          response: results[1]!,
        ));
      } else {
        debugPrint('ℹ️ 임야 검색: 데이터 없음');
      }

      debugPrint('📡 양쪽 검색 결과: ${validResults.length}건');
      return validResults;
    } catch (e) {
      debugPrint('❌ 양쪽 검색 에러: $e');
      return [];
    }
  }

  /// 검색 결과에 실제 유효한 데이터가 있는지 확인
  ///
  /// 핵심: 토지 정보(land)가 있어야 해당 토지 유형이 실제로 존재하는 것.
  /// 백엔드는 land_type과 관계없이 동일한 건물 정보를 반환하지만,
  /// 토지 정보는 실제 해당 토지 유형이 존재할 때만 반환함.
  bool _hasValidData(BuildingSearchResponse response) {
    if (!response.success) return false;

    // 에러 메시지가 있으면 유효하지 않음
    if (response.error != null && response.error!.isNotEmpty) {
      debugPrint('📡 데이터 유효성: 에러 메시지 있음 - ${response.error}');
      return false;
    }

    // 토지 정보가 있는지 확인 (핵심 검증)
    // 토지 정보가 있어야 해당 land_type이 실제로 존재하는 것
    final land = response.land;
    final hasLand = land != null && (
        (land.landArea != null && land.landArea! > 0) ||
        (land.publicLandPrice != null && land.publicLandPrice! > 0)
    );

    debugPrint('📡 데이터 유효성 검사:');
    debugPrint('   - hasLand: $hasLand');
    if (land != null) {
      debugPrint('     - landArea: ${land.landArea}');
      debugPrint('     - publicLandPrice: ${land.publicLandPrice}');
    } else {
      debugPrint('     - land is null (해당 토지 유형 없음)');
    }

    // 토지 정보가 있어야만 유효 (건물 정보는 land_type 구분 없이 반환되므로 신뢰 불가)
    return hasLand;
  }

  /// 에러를 throw하지 않고 null 반환하는 지번 검색 (내부용)
  Future<BuildingSearchResponse?> _searchByJibunSafe({
    required String bjdongCode,
    required String bun,
    String ji = '0',
    String landType = '1',
  }) async {
    try {
      final request = JibunSearchRequest(
        bjdongCode: bjdongCode,
        bun: bun,
        ji: ji,
        landType: landType,
      );
      return await _buildingApi.searchByJibun(request);
    } catch (e) {
      debugPrint('📡 지번 검색 실패 (landType=$landType): $e');
      return null;
    }
  }

  /// 법정동 검색 (자동완성)
  Future<List<BjdongSearchItem>> searchBjdong(String query) async {
    try {
      debugPrint('📡 API 호출: searchBjdong($query)');
      final response = await _buildingApi.searchBjdong(query);
      debugPrint('📡 API 응답: success=${response.success}, count=${response.results.length}');
      if (response.success) {
        return response.results;
      }
      return [];
    } on DioException catch (e) {
      debugPrint('📡 API DioException: ${e.type} - ${e.message}');
      debugPrint('📡 Response: ${e.response?.data}');
      final message = e.response?.data?['error'] ?? '검색 중 오류가 발생했습니다';
      throw Exception(message);
    }
  }

  /// 공동주택 동/호별 상세 정보 조회
  Future<AreaInfo?> getAreaInfo({
    required String bjdongCode,
    required String bun,
    String ji = '0000',
    required String dongNm,
    required String hoNm,
  }) async {
    try {
      final request = AreaInfoRequest(
        bjdongCode: bjdongCode,
        bun: bun,
        ji: ji,
        dongNm: dongNm,
        hoNm: hoNm,
      );
      final response = await _buildingApi.getAreaInfo(request);
      if (response.success) {
        return response.areaInfo;
      }
      return null;
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? '조회 중 오류가 발생했습니다';
      throw Exception(message);
    }
  }
}

/// 토지 유형별 검색 결과
///
/// 대지/임야 병렬 검색 시 각각의 결과를 담는 클래스
class LandTypeSearchResult {
  /// 토지 유형 코드 ('1'=대지, '2'=임야)
  final String landType;

  /// 토지 유형 이름 (UI 표시용)
  final String landTypeName;

  /// 검색 응답
  final BuildingSearchResponse response;

  LandTypeSearchResult({
    required this.landType,
    required this.landTypeName,
    required this.response,
  });
}
