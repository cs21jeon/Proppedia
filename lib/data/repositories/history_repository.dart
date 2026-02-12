import 'package:dio/dio.dart';
import 'package:propedia/core/database/database_service.dart';
import 'package:propedia/data/datasources/remote/history_api.dart';
import 'package:propedia/data/models/search_history.dart';

class HistoryRepository {
  final HistoryApi _api;

  HistoryRepository(Dio dio) : _api = HistoryApi(dio);

  /// 검색 기록 저장 (로컬 + 서버)
  Future<void> addHistory({
    required String searchType,
    required String displayAddress,
    String? roadAddress,
    String? jibunAddress,
    String? buildingName,
    String? pnu,
    String? bdMgtSn,
    String? dongName,
    String? hoName,
    String? buildingType,
    double? latitude,
    double? longitude,
  }) async {
    // 로컬 저장
    final history = SearchHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      searchType: searchType,
      displayAddress: displayAddress,
      roadAddress: roadAddress,
      jibunAddress: jibunAddress,
      buildingName: buildingName,
      pnu: pnu,
      bdMgtSn: bdMgtSn,
      searchedAt: DateTime.now(),
      dongName: dongName,
      hoName: hoName,
      buildingType: buildingType,
    );

    await DatabaseService.addSearchHistory(history);

    // 서버 저장 (실패해도 로컬은 유지)
    try {
      await _api.saveSearchHistory({
        'search_type': searchType,
        'address_text': displayAddress,
        'pnu': pnu,
        'building_name': buildingName,
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (_) {
      // 서버 저장 실패 무시 (오프라인 지원)
    }
  }

  /// 검색 기록 조회 (로컬)
  List<SearchHistory> getHistory() {
    return DatabaseService.getSearchHistory();
  }

  /// 검색 기록 조회 (서버 - 날짜별 그룹핑)
  Future<Map<String, List<Map<String, dynamic>>>> getServerHistory({
    int limit = 100,
  }) async {
    try {
      final response = await _api.getSearchHistory(limit: limit);
      if (response['success'] == true) {
        final historyData = response['history'];
        if (historyData is Map) {
          return Map<String, List<Map<String, dynamic>>>.from(
            historyData.map((key, value) => MapEntry(
              key as String,
              (value as List).map((e) => e as Map<String, dynamic>).toList(),
            )),
          );
        }
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// 검색 기록 삭제 (로컬)
  Future<void> deleteHistory(String id) async {
    await DatabaseService.deleteSearchHistory(id);
  }

  /// 검색 기록 삭제 (서버)
  Future<void> deleteServerHistory(int id) async {
    await _api.deleteSearchHistory(id);
  }

  /// 검색 기록 전체 삭제 (로컬)
  Future<void> clearHistory() async {
    await DatabaseService.clearSearchHistory();
  }
}
