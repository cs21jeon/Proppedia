import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:propedia/data/models/search_history.dart';
import 'package:propedia/data/repositories/history_repository.dart';
import 'package:propedia/presentation/providers/auth_provider.dart';

// Repository Provider
final historyRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HistoryRepository(apiClient.dio);
});

// 검색 기록 상태
class HistoryState {
  final List<SearchHistory> localHistory;
  final Map<String, List<Map<String, dynamic>>> serverHistory;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.localHistory = const [],
    this.serverHistory = const {},
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<SearchHistory>? localHistory,
    Map<String, List<Map<String, dynamic>>>? serverHistory,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      localHistory: localHistory ?? this.localHistory,
      serverHistory: serverHistory ?? this.serverHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 검색 기록 Provider
class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRepository _repository;

  HistoryNotifier(this._repository) : super(const HistoryState());

  /// 검색 기록 추가
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
    try {
      await _repository.addHistory(
        searchType: searchType,
        displayAddress: displayAddress,
        roadAddress: roadAddress,
        jibunAddress: jibunAddress,
        buildingName: buildingName,
        pnu: pnu,
        bdMgtSn: bdMgtSn,
        dongName: dongName,
        hoName: hoName,
        buildingType: buildingType,
        latitude: latitude,
        longitude: longitude,
      );

      // 목록 갱신
      loadLocalHistory();
    } catch (e) {
      debugPrint('검색 기록 저장 에러: $e');
    }
  }

  /// 로컬 검색 기록 로드
  void loadLocalHistory() {
    final history = _repository.getHistory();
    state = state.copyWith(localHistory: history);
  }

  /// 서버 검색 기록 로드
  Future<void> loadServerHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final history = await _repository.getServerHistory();
      state = state.copyWith(
        serverHistory: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 검색 기록 삭제 (로컬)
  Future<void> deleteHistory(String id) async {
    await _repository.deleteHistory(id);
    loadLocalHistory();
  }

  /// 검색 기록 삭제 (서버)
  Future<void> deleteServerHistory(int id) async {
    try {
      await _repository.deleteServerHistory(id);
      await loadServerHistory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 검색 기록 전체 삭제
  Future<void> clearHistory() async {
    await _repository.clearHistory();
    state = state.copyWith(localHistory: []);
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryNotifier(repository);
});
