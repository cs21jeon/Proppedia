import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:propedia/core/constants/app_colors.dart';
import 'package:propedia/data/dto/building_dto.dart';
import 'package:propedia/presentation/providers/building_provider.dart';
import 'package:propedia/presentation/widgets/common/app_footer.dart';

class SearchJibunScreen extends ConsumerStatefulWidget {
  const SearchJibunScreen({super.key});

  @override
  ConsumerState<SearchJibunScreen> createState() => _SearchJibunScreenState();
}

class _SearchJibunScreenState extends ConsumerState<SearchJibunScreen> {
  final _bjdongController = TextEditingController();
  final _bunController = TextEditingController();
  final _jiController = TextEditingController();
  final _bjdongFocusNode = FocusNode();
  final _bunFocusNode = FocusNode();
  final _jiFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  String? _selectedBjdongCode;
  String? _selectedBjdongName;
  String _landType = '1'; // 1=대지, 2=임야

  List<BjdongSearchItem> _bjdongResults = [];
  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _bjdongFocusNode.addListener(_onFocusChange);
    // Tab키로 포커스 이동 시 전체 텍스트 선택
    _bunFocusNode.addListener(() {
      if (_bunFocusNode.hasFocus && _bunController.text.isNotEmpty) {
        _bunController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _bunController.text.length,
        );
      }
    });
    _jiFocusNode.addListener(() {
      if (_jiFocusNode.hasFocus && _jiController.text.isNotEmpty) {
        _jiController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _jiController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _bjdongController.dispose();
    _bunController.dispose();
    _jiController.dispose();
    _bjdongFocusNode.removeListener(_onFocusChange);
    _bjdongFocusNode.dispose();
    _bunFocusNode.dispose();
    _jiFocusNode.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_bjdongFocusNode.hasFocus) {
      // 포커스를 받았을 때 기존 검색 결과가 있고 법정동이 선택되지 않았으면 드롭다운 다시 표시
      if (_bjdongResults.isNotEmpty && _selectedBjdongCode == null) {
        _showOverlay();
      }
    } else {
      // 클릭 이벤트가 처리될 시간을 주기 위해 지연
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_bjdongFocusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onBjdongChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.trim().isNotEmpty) {
        _searchBjdong(value);
      } else {
        setState(() {
          _bjdongResults = [];
        });
        _removeOverlay();
      }
    });
  }

  Future<void> _searchBjdong(String query) async {
    try {
      debugPrint('🔍 법정동 검색 시작: $query');
      final repository = ref.read(buildingRepositoryProvider);
      final results = await repository.searchBjdong(query);
      debugPrint('✅ 법정동 검색 결과: ${results.length}건');
      setState(() {
        _bjdongResults = results;
      });
      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      debugPrint('❌ 법정동 검색 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 오류: $e')),
        );
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _bjdongResults.length,
                itemBuilder: (context, index) {
                  final item = _bjdongResults[index];
                  return InkWell(
                    onTap: () {
                      debugPrint('🎯 법정동 선택: ${item.fullAddress}');
                      _selectBjdong(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        item.fullAddress ?? item.eupmyeondongName ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectBjdong(BjdongSearchItem item) {
    setState(() {
      _selectedBjdongCode = item.code;
      _selectedBjdongName = item.fullAddress ?? item.eupmyeondongName;
      _bjdongController.text = _selectedBjdongName ?? '';
    });
    _removeOverlay();
    _bjdongFocusNode.unfocus();
  }

  void _search() {
    _removeOverlay();

    if (_selectedBjdongCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('법정동을 선택해주세요')),
      );
      return;
    }

    final bun = _bunController.text.trim();
    if (bun.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본번을 입력해주세요')),
      );
      return;
    }

    final ji = _jiController.text.trim().isEmpty ? '0000' : _jiController.text.trim();

    ref.read(buildingSearchProvider.notifier).searchByJibun(
          bjdongCode: _selectedBjdongCode!,
          bun: bun,
          ji: ji,
          landType: _landType,
        );

    context.push('/result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지번 주소 검색'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _removeOverlay();
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 문구
              Container(
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
                        '법정동과 번지를 입력하여\n건축물 정보를 검색합니다',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 토지구분 선택
              Text(
                '토지구분',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLandTypeButton(
                      label: '대지',
                      value: '1',
                      isSelected: _landType == '1',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLandTypeButton(
                      label: '임야',
                      value: '2',
                      isSelected: _landType == '2',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 법정동 입력
              Text(
                '법정동',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              CompositedTransformTarget(
                link: _layerLink,
                child: TextField(
                  controller: _bjdongController,
                  focusNode: _bjdongFocusNode,
                  decoration: InputDecoration(
                    hintText: '동/읍/면 이름을 입력하세요',
                    prefixIcon: const Icon(Icons.location_city),
                    suffixIcon: _selectedBjdongCode != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _bjdongController.clear();
                                _selectedBjdongCode = null;
                                _selectedBjdongName = null;
                              });
                              _removeOverlay();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onBjdongChanged,
                ),
              ),

              if (_selectedBjdongCode != null) ...[
                const SizedBox(height: 8),
                Text(
                  '선택됨: $_selectedBjdongName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 번지 입력
              Text(
                '번지',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _bunController,
                      focusNode: _bunFocusNode,
                      decoration: InputDecoration(
                        hintText: '본번',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('-', style: TextStyle(fontSize: 24)),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _jiController,
                      focusNode: _jiFocusNode,
                      decoration: InputDecoration(
                        hintText: '부번 (없으면 비움)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 검색 버튼
              ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('검색'),
              ),

              const SizedBox(height: 24),

              // 예시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '입력 예시',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 서울시 동작구 사당동 123-45\n'
                      '  → 법정동: 사당동, 본번: 123, 부번: 45\n\n'
                      '• 서울시 강남구 역삼동 123\n'
                      '  → 법정동: 역삼동, 본번: 123, 부번: (비움)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooterSimple(),
    );
  }

  Widget _buildLandTypeButton({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _landType = value;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
        ),
      ),
      child: Text(label),
    );
  }
}
