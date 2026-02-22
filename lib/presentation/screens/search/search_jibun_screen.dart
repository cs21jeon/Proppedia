import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:propedia/core/constants/app_colors.dart';
import 'package:propedia/core/utils/jibun_address_parser.dart';
import 'package:propedia/data/dto/building_dto.dart';
import 'package:propedia/data/repositories/building_repository.dart';
import 'package:propedia/presentation/providers/building_provider.dart';
import 'package:propedia/presentation/widgets/common/app_footer.dart';

class SearchJibunScreen extends ConsumerStatefulWidget {
  const SearchJibunScreen({super.key});

  @override
  ConsumerState<SearchJibunScreen> createState() => _SearchJibunScreenState();
}

class _SearchJibunScreenState extends ConsumerState<SearchJibunScreen> {
  final _addressController = TextEditingController();
  final _addressFocusNode = FocusNode();

  // 파싱 결과
  JibunParseResult? _parseResult;

  // 법정동 검색 결과
  List<BjdongSearchItem> _bjdongResults = [];
  BjdongSearchItem? _selectedBjdong;

  // 토지 유형 검색 결과 (대지/임야 둘 다 존재하는 경우)
  List<LandTypeSearchResult> _landTypeResults = [];
  LandTypeSearchResult? _selectedLandType;

  // 상태
  bool _isSearchingBjdong = false;
  bool _isSearchingLandType = false;
  String? _errorMessage;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _addressFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _parseInput();
    });
  }

  /// 입력 파싱 (검색 버튼 누르기 전 준비 단계)
  void _parseInput() {
    final input = _addressController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _parseResult = null;
        _bjdongResults = [];
        _selectedBjdong = null;
        _landTypeResults = [];
        _selectedLandType = null;
        _errorMessage = null;
      });
      return;
    }

    // 파싱
    final result = JibunAddressParser.parse(input);
    setState(() {
      _parseResult = result;
      _errorMessage = result.error;
      // 새로운 입력 시 이전 선택 초기화
      _selectedBjdong = null;
      _landTypeResults = [];
      _selectedLandType = null;
    });
  }

  /// 검색 버튼 클릭 시 실행
  Future<void> _search() async {
    // 1. 파싱 확인
    if (_parseResult == null || !_parseResult!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소와 번지를 입력해주세요 (예: 사당동 123-45)')),
      );
      return;
    }

    if (!_parseResult!.hasAddressQuery) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('법정동을 함께 입력해주세요 (예: 사당동 ${_parseResult!.bun}-${_parseResult!.jiForApi})')),
      );
      return;
    }

    // 2. 법정동 검색
    setState(() {
      _isSearchingBjdong = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(buildingRepositoryProvider);
      final bjdongResults = await repository.searchBjdong(_parseResult!.addressQuery!);

      if (bjdongResults.isEmpty) {
        setState(() {
          _isSearchingBjdong = false;
          _errorMessage = '해당 법정동을 찾을 수 없습니다: ${_parseResult!.addressQuery}';
        });
        return;
      }

      // 법정동이 1개면 바로 진행, 여러 개면 선택 요청
      if (bjdongResults.length == 1) {
        _selectedBjdong = bjdongResults.first;
        setState(() {
          _bjdongResults = [];
          _isSearchingBjdong = false;
        });
        await _searchLandTypes();
      } else {
        // 여러 개면 선택 UI 표시
        setState(() {
          _bjdongResults = bjdongResults;
          _isSearchingBjdong = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSearchingBjdong = false;
        _errorMessage = '법정동 검색 중 오류가 발생했습니다';
      });
    }
  }

  /// 법정동 선택 후 토지 유형 검색
  void _selectBjdongAndSearch(BjdongSearchItem item) async {
    setState(() {
      _selectedBjdong = item;
      _bjdongResults = []; // 드롭다운 닫기
    });
    await _searchLandTypes();
  }

  /// 대지/임야 검색
  ///
  /// 검색 로직:
  /// 1. 사당동 272-26 → 대지만 있으면 바로 결과, 임야만 있어도 바로 결과
  /// 2. 사당동 산 272-26 → 임야만 있으면 바로 결과, 대지만 있어도 바로 결과
  /// 3. 둘 다 있는 경우에만 선택 UI 표시
  Future<void> _searchLandTypes() async {
    if (_selectedBjdong == null || _parseResult == null || !_parseResult!.hasLotNumber) {
      return;
    }

    setState(() {
      _isSearchingLandType = true;
      _landTypeResults = [];
      _selectedLandType = null;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(buildingRepositoryProvider);

      // 항상 대지/임야 양쪽 모두 검색 (산 입력 여부와 관계없이)
      debugPrint('🔍 대지/임야 양쪽 검색: bun=${_parseResult!.bun}, ji=${_parseResult!.jiForApi}');
      final results = await repository.searchBothLandTypes(
        bjdongCode: _selectedBjdong!.code,
        bun: _parseResult!.bun!,
        ji: _parseResult!.jiForApi,
      );

      setState(() {
        _isSearchingLandType = false;
      });

      if (results.isEmpty) {
        setState(() {
          _errorMessage = '해당 지번을 찾을 수 없습니다';
        });
      } else if (results.length == 1) {
        // 한쪽만 존재하면 바로 결과 화면으로 (산 입력 여부와 관계없이)
        _goToResult(results.first.response);
      } else {
        // 둘 다 존재하는 경우에만 선택 UI 표시
        setState(() {
          _landTypeResults = results;
        });
      }
    } catch (e) {
      debugPrint('❌ 토지 유형 검색 에러: $e');
      setState(() {
        _isSearchingLandType = false;
        _errorMessage = '검색 중 오류가 발생했습니다';
      });
    }
  }

  /// 토지 유형 선택 후 결과 화면으로 이동
  void _selectLandTypeAndGo(LandTypeSearchResult result) {
    _goToResult(result.response);
  }

  /// 결과 화면으로 이동
  void _goToResult(BuildingSearchResponse response) {
    ref.read(buildingSearchProvider.notifier).setSearchResult(
      response,
      searchType: 'jibun',
    );
    context.push('/result');
  }

  void _clearInput() {
    _addressController.clear();
    setState(() {
      _parseResult = null;
      _bjdongResults = [];
      _selectedBjdong = null;
      _landTypeResults = [];
      _selectedLandType = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSearchingBjdong || _isSearchingLandType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('지번 주소 검색'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 문구
              _buildInfoBox(),

              const SizedBox(height: 24),

              // 통합 입력 필드
              _buildAddressInput(),

              // 법정동 선택 (다중 결과)
              if (_bjdongResults.length > 1) ...[
                const SizedBox(height: 16),
                _buildBjdongSelector(),
              ],

              // 토지 유형 선택 (대지/임야 둘 다 존재)
              if (_landTypeResults.length > 1) ...[
                const SizedBox(height: 16),
                _buildLandTypeSelector(),
              ],

              // 에러 메시지
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(),
              ],

              // 검색 버튼
              const SizedBox(height: 24),
              _buildSearchButton(isLoading),

              const SizedBox(height: 24),

              // 입력 예시
              _buildExampleBox(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooterSimple(),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '법정동과 번지를 함께 입력하세요\n예: 사당동 123-45',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '지번 주소',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          focusNode: _addressFocusNode,
          decoration: InputDecoration(
            hintText: '예: 사당동 123-45, 사당동 산 123',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _addressController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearInput,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
      ],
    );
  }

  Widget _buildBjdongSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '동일 이름 ${_bjdongResults.length}건 - 선택해주세요',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._bjdongResults.map((item) => InkWell(
                onTap: () => _selectBjdongAndSearch(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.fullAddress ?? item.eupmyeondongName ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLandTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '토지 유형을 선택해주세요',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '해당 번지가 대지와 임야 모두에 존재합니다',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ..._landTypeResults.map((result) => InkWell(
                onTap: () => _selectLandTypeAndGo(result),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.landType == '2' ? Icons.forest : Icons.landscape,
                        size: 18,
                        color: result.landType == '2' ? Colors.green : Colors.brown,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.landTypeName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _search,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('검색'),
    );
  }

  Widget _buildExampleBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '입력 예시',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• 사당동 123-45\n'
            '• 동작구 사당동 123-45\n'
            '• 서울시 강남구 역삼동 123-45\n'
            '• 사당동 산 123-45 (임야)',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
