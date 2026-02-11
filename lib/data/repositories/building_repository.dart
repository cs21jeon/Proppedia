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
