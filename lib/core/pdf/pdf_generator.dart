import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:propedia/core/pdf/pdf_fonts.dart';
import 'package:propedia/data/dto/building_dto.dart';

/// PDF 문서 생성기 (웹앱 레이아웃 벤치마킹)
class PdfGenerator {
  static final PdfFonts _fonts = PdfFonts();

  // 레이아웃 상수 (웹앱과 동일)
  static const double _margin = 35;
  static const double _headerHeight = 60;
  static const double _sectionHeaderHeight = 28;
  static const double _rowHeight = 24;
  static const double _sectionGap = 12;

  // 색상 (웹앱과 동일)
  static const PdfColor _colorPrimary = PdfColor.fromInt(0xFF136DEC);
  static const PdfColor _colorDark = PdfColor.fromInt(0xFF334155);
  static const PdfColor _colorGray = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _colorBgLight = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _colorBorder = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _colorWhite = PdfColors.white;

  // 로고 이미지 캐시
  static Uint8List? _proppediaLogo;
  static Uint8List? _goldenrabbitLogo;

  /// 로고 이미지 로드
  static Future<void> _loadLogos() async {
    if (_proppediaLogo == null) {
      try {
        final data = await rootBundle.load('assets/images/proppedia_icon.png');
        _proppediaLogo = data.buffer.asUint8List();
      } catch (e) {
        // 로고 로드 실패 시 무시
      }
    }
    if (_goldenrabbitLogo == null) {
      try {
        final data = await rootBundle.load('assets/images/goldenrabbit_icon.png');
        _goldenrabbitLogo = data.buffer.asUint8List();
      } catch (e) {
        // 로고 로드 실패 시 무시
      }
    }
  }

  /// 부동산 정보 PDF를 생성합니다.
  static Future<Uint8List> generatePropertyPdf({
    required BuildingSearchResponse data,
    AreaInfo? areaInfo,
    Uint8List? mapImage,
  }) async {
    await _fonts.load();
    await _loadLogos();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(_margin),
        build: (context) => _buildContent(context, data, areaInfo, mapImage),
      ),
    );

    return pdf.save();
  }

  /// PDF 내용 구성
  static pw.Widget _buildContent(
    pw.Context context,
    BuildingSearchResponse data,
    AreaInfo? areaInfo,
    Uint8List? mapImage,
  ) {
    final pageWidth = PdfPageFormat.a4.landscape.width - 2 * _margin;
    final leftColumnWidth = pageWidth * 0.57;
    final rightColumnWidth = pageWidth * 0.39;
    final columnGap = pageWidth * 0.04;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // 헤더
        _buildHeader(),
        pw.SizedBox(height: 10),

        // 메인 콘텐츠 (2열)
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 좌측 컬럼
              pw.SizedBox(
                width: leftColumnWidth,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildBasicInfoSection(data, areaInfo, leftColumnWidth),
                    pw.SizedBox(height: _sectionGap),
                    _buildLandSection(data.land, leftColumnWidth, hasBuilding: data.building?.hasData == true),
                    pw.SizedBox(height: _sectionGap),
                    if (data.building != null && data.building!.hasData)
                      _buildBuildingSection(data.building!, areaInfo, data.land, leftColumnWidth),
                  ],
                ),
              ),

              pw.SizedBox(width: columnGap),

              // 우측 컬럼
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    if (areaInfo != null) ...[
                      _buildAreaInfoSection(areaInfo, rightColumnWidth),
                      pw.SizedBox(height: _sectionGap),
                    ] else if (data.building?.type == 'general' &&
                        data.building?.floorInfo != null) ...[
                      _buildFloorInfoSection(data.building!.floorInfo!, rightColumnWidth),
                      pw.SizedBox(height: _sectionGap),
                    ],
                    // 토지만 있는 경우(건물 없음) 지도 섹션의 상단을 기본정보와 맞춤
                    pw.Expanded(
                      child: _buildMapSection(mapImage, data, rightColumnWidth),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 푸터
        pw.SizedBox(height: 8),
        _buildFooter(),
      ],
    );
  }

  /// 헤더
  static pw.Widget _buildHeader() {
    final now = DateFormat('yyyy. MM. dd HH:mm:ss').format(DateTime.now());

    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _colorPrimary, width: 3)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '부동산 정보 조회 결과',
                style: _fonts.style(fontSize: 22, isBold: true, color: _colorPrimary),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Building & Land Information Report',
                style: _fonts.style(fontSize: 10, color: _colorGray),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('생성일시', style: _fonts.style(fontSize: 9, color: _colorGray)),
              pw.Text(now, style: _fonts.style(fontSize: 10, isBold: true, color: _colorDark)),
            ],
          ),
        ],
      ),
    );
  }

  /// 기본정보 섹션
  static pw.Widget _buildBasicInfoSection(BuildingSearchResponse data, AreaInfo? areaInfo, double width) {
    final buildingInfo = data.building?.buildingInfo;
    final recapInfo = data.building?.recapTitleInfo;
    final isMultiUnit = data.building?.type == 'multi_unit';
    final hasBuilding = data.building?.hasData == true;

    // 지번
    final jibunAddress = _getJibunAddress(data);
    // 도로명주소
    final roadAddress = _getRoadAddress(data);

    // 세대/가구/호 (건물이 있는 경우에만) - 조회결과 화면과 동일한 순서
    // 참고: API의 hhld_cnt를 "세대" 위치에, fmly_cnt를 "가구" 위치에 표시
    String sedaeGaguHo = '';
    if (hasBuilding) {
      if (isMultiUnit && recapInfo != null) {
        // 공동주택: recapTitleInfo에서 가져옴 (total_* 또는 일반 필드명)
        final hhld = (recapInfo['total_hhld_cnt'] ?? recapInfo['hhld_cnt'] ?? recapInfo['hhldCnt'] ?? 0).toString();
        final fmly = (recapInfo['total_fmly_cnt'] ?? recapInfo['family_cnt'] ?? recapInfo['familyCnt'] ?? 0).toString();
        final ho = (recapInfo['total_ho_cnt'] ?? recapInfo['ho_cnt'] ?? recapInfo['hoCnt'] ?? 0).toString();
        sedaeGaguHo = '$hhld/$fmly/$ho';
      } else if (buildingInfo != null) {
        // 일반건축물: buildingInfo에서 가져옴
        final hhld = buildingInfo.hhldCnt ?? 0;
        final fmly = buildingInfo.familyCnt ?? 0;
        final ho = buildingInfo.hoCnt ?? 0;
        sedaeGaguHo = '$hhld/$fmly/$ho';
      }
    }

    // 주용도 (건물이 있는 경우에만)
    String mainPurpose = '-';
    if (hasBuilding) {
      // recapTitleInfo에서 먼저 확인 (공동주택)
      final recapPurpose = recapInfo?['main_purpose'] ?? recapInfo?['mainPurpose'];
      if (recapPurpose != null && recapPurpose.toString().isNotEmpty && recapPurpose.toString() != '-') {
        mainPurpose = recapPurpose.toString();
      } else if (buildingInfo?.mainPurpose != null && buildingInfo!.mainPurpose!.isNotEmpty) {
        // buildingInfo에서 확인 (일반건축물)
        mainPurpose = buildingInfo.mainPurpose!;
        // etc_purpose가 있으면 추가
        if (buildingInfo.etcPurpose != null && buildingInfo.etcPurpose!.isNotEmpty) {
          mainPurpose = buildingInfo.etcPurpose!;
        }
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          _buildSectionHeader('기본정보'),
          // 지번 (단일 열)
          if (jibunAddress.isNotEmpty)
            _buildSingleRow('지번', jibunAddress, width, false),
          // 도로명주소 (단일 열)
          if (roadAddress.isNotEmpty)
            _buildSingleRow('도로명주소', roadAddress, width, jibunAddress.isNotEmpty),
          // 세대/가구/호 + 주용도 (2열) - 건물이 있는 경우에만
          if (hasBuilding)
            _buildTwoColumnRow(
              '세대/가구/호', sedaeGaguHo,
              '주용도', mainPurpose,
              width,
              (jibunAddress.isNotEmpty ? 1 : 0) + (roadAddress.isNotEmpty ? 1 : 0) % 2 == 1,
            ),
        ],
      ),
    );
  }

  /// 토지정보 섹션
  static pw.Widget _buildLandSection(LandInfo? land, double width, {bool hasBuilding = true}) {
    if (land == null) return pw.SizedBox.shrink();

    final rows = <List<MapEntry<String, String>>>[];

    // 토지면적 + 필지 수
    String areaText = '-';
    if (land.landArea != null) {
      areaText = '${_formatNumber(land.landArea!)}㎡ (약 ${_toPyeong(land.landArea!)}평)';
      if (land.parcelCount != null && land.parcelCount! > 1) {
        areaText += ' [${land.parcelCount}필지]';
      }
    }
    final priceText = land.publicLandPrice != null
        ? '${_formatPrice(land.publicLandPrice!)} 원/㎡'
        : '-';

    // 공시지가 + 년도
    final priceWithYear = land.publicLandPrice != null
        ? '$priceText${land.priceYear != null ? ' (${land.priceYear}년)' : ''}'
        : '-';

    if (hasBuilding) {
      // 건물이 있는 경우: 간략 표시 (4개 항목)
      rows.add([
        MapEntry('토지면적', areaText),
        MapEntry('용도지역', land.zoneClassification ?? '-'),
      ]);
      rows.add([
        MapEntry('공시지가', priceWithYear),
        MapEntry('지목', land.landCategoryName ?? '-'),
      ]);
    } else {
      // 건물이 없는 경우: 상세 표시 (8개 항목)
      // 지목 + 토지면적
      rows.add([
        MapEntry('지목', land.landCategoryName ?? '-'),
        MapEntry('토지면적', areaText),
      ]);
      // 용도지역 + 이용현황
      rows.add([
        MapEntry('용도지역', land.zoneClassification ?? '-'),
        MapEntry('이용현황', land.landUseSituationName ?? '-'),
      ]);
      // 지형 + 도로접면
      final topoText = <String>[];
      if (land.topographyHeightName != null && land.topographyHeightName!.isNotEmpty) {
        topoText.add(land.topographyHeightName!);
      }
      if (land.topographyFormName != null && land.topographyFormName!.isNotEmpty) {
        topoText.add(land.topographyFormName!);
      }
      rows.add([
        MapEntry('지형', topoText.isNotEmpty ? topoText.join('/') : '-'),
        MapEntry('도로접면', land.roadSideName ?? '-'),
      ]);
      // 공시지가 (년도 포함) + 빈칸
      rows.add([
        MapEntry('공시지가', priceWithYear),
        MapEntry('', ''),
      ]);
    }

    return _buildTwoColumnSection('토지정보', rows, width);
  }

  /// 건물정보 섹션
  static pw.Widget _buildBuildingSection(BuildingInfo building, AreaInfo? areaInfo, LandInfo? land, double width) {
    final info = building.buildingInfo;
    final recapInfo = building.recapTitleInfo;
    final dongTitleInfo = areaInfo?.dongTitleInfo;
    final isMultiUnit = building.type == 'multi_unit';

    final rows = <List<MapEntry<String, String>>>[];

    // 건물명 + 대지면적 (필지 수 포함)
    final buildingNameRaw = recapInfo?['building_name'];
    String? buildingName = buildingNameRaw?.toString();
    if (buildingName == null || buildingName == '-' || buildingName.isEmpty) {
      buildingName = info?.buildingName;
    }
    double? landArea = (recapInfo?['land_area'] as num?)?.toDouble() ?? info?.landArea;
    String landAreaText = '-';
    if (landArea != null) {
      landAreaText = '${_formatNumber(landArea)}㎡ (약 ${_toPyeong(landArea)}평)';
      if (land?.parcelCount != null && land!.parcelCount! > 1) {
        landAreaText += ' [${land.parcelCount}필지]';
      }
    }
    rows.add([
      MapEntry('건물명', buildingName ?? '-'),
      MapEntry('대지면적', landAreaText),
    ]);

    // 연면적 + 용적률산정용연면적
    double? totalArea = (recapInfo?['total_area'] as num?)?.toDouble() ?? info?.totalArea;
    double? calcArea = (recapInfo?['vl_rat_estm_tot_area'] as num?)?.toDouble() ?? info?.vlRatEstmTotArea;
    rows.add([
      MapEntry('연면적', totalArea != null ? '${_formatNumber(totalArea)}㎡ (약 ${_toPyeong(totalArea)}평)' : '-'),
      MapEntry('용적률산정용연면적', calcArea != null ? '${_formatNumber(calcArea)}㎡ (약 ${_toPyeong(calcArea)}평)' : '-'),
    ]);

    // 건축면적 + 높이
    // 공동주택의 경우 dongTitleInfo에서 해당 동의 높이를 가져옴
    double? buildingArea = (recapInfo?['building_area'] as num?)?.toDouble() ?? info?.buildingArea;
    double? height;
    if (isMultiUnit && dongTitleInfo != null) {
      height = (dongTitleInfo['height'] as num?)?.toDouble();
    }
    height ??= (recapInfo?['height'] as num?)?.toDouble() ?? info?.height;
    rows.add([
      MapEntry('건축면적', buildingArea != null ? '${_formatNumber(buildingArea)}㎡ (약 ${_toPyeong(buildingArea)}평)' : '-'),
      MapEntry('높이', height != null && height > 0 ? '${_formatNumber(height)}m' : '-'),
    ]);

    // 건폐율 + 용적률
    double? coverage = (recapInfo?['building_coverage'] as num?)?.toDouble() ?? info?.buildingCoverage;
    double? floorRatio = (recapInfo?['floor_area_ratio'] as num?)?.toDouble() ?? info?.floorAreaRatio;
    rows.add([
      MapEntry('건폐율', coverage != null ? '${coverage.toStringAsFixed(2)}%' : '-'),
      MapEntry('용적률', floorRatio != null ? '${floorRatio.toStringAsFixed(2)}%' : '-'),
    ]);

    // 층수 + 사용승인일
    // 공동주택의 경우 dongTitleInfo에서 해당 동의 층수를 가져옴
    int totalFloors;
    int basementFloors;
    if (isMultiUnit && dongTitleInfo != null) {
      totalFloors = (dongTitleInfo['total_floors'] as num?)?.toInt() ?? (dongTitleInfo['grnd_flr_cnt'] as num?)?.toInt() ?? info?.totalFloors ?? 0;
      basementFloors = (dongTitleInfo['basement_floors'] as num?)?.toInt() ?? (dongTitleInfo['ugrnd_flr_cnt'] as num?)?.toInt() ?? info?.basementFloors ?? 0;
    } else {
      totalFloors = info?.totalFloors ?? 0;
      basementFloors = info?.basementFloors ?? 0;
    }
    final useApprovalRaw = recapInfo?['use_approval_date'] ?? info?.useApprovalDate;
    String useApprovalDate = '-';
    if (useApprovalRaw != null) {
      useApprovalDate = useApprovalRaw.toString();
      if (useApprovalDate == '-' || useApprovalDate.isEmpty) {
        useApprovalDate = '-';
      }
    }
    rows.add([
      MapEntry('층수', '지상 ${totalFloors}층 / 지하 ${basementFloors}층'),
      MapEntry('사용승인일', useApprovalDate),
    ]);

    // 주차대수 + 승강기수
    // 공동주택: 총주차대수 (recapTitleInfo), 해당동승강기수 (dongTitleInfo)
    // 일반건축물: 주차대수, 승강기수
    final parkingRaw = recapInfo?['total_parking'] ?? info?.totalParking;
    String parkingStr = '-';
    if (parkingRaw != null) {
      if (parkingRaw is int || parkingRaw is double) {
        parkingStr = parkingRaw > 0 ? '$parkingRaw대' : '-';
      } else if (parkingRaw is String && parkingRaw.isNotEmpty && parkingRaw != '-') {
        parkingStr = '${parkingRaw}대';
      }
    }

    String parkingLabel = isMultiUnit ? '총주차대수' : '주차대수';
    String elevatorLabel = isMultiUnit ? '해당동승강기수' : '승강기수';

    int? elevatorCnt;
    if (isMultiUnit && dongTitleInfo != null) {
      // 공동주택: dongTitleInfo에서 해당 동의 승강기수
      elevatorCnt = (dongTitleInfo['elevator_count'] as num?)?.toInt() ??
                    (dongTitleInfo['rideUseElvtCnt'] as num?)?.toInt() ??
                    (dongTitleInfo['ride_use_elvt_cnt'] as num?)?.toInt();
    }
    elevatorCnt ??= info?.elevatorCount;

    rows.add([
      MapEntry(parkingLabel, parkingStr),
      MapEntry(elevatorLabel, elevatorCnt != null && elevatorCnt > 0 ? '$elevatorCnt기' : '-'),
    ]);

    // 주구조 + 지붕
    String? roofText = info?.roof ?? info?.etcRoof;
    rows.add([
      MapEntry('주구조', info?.mainStructure ?? '-'),
      MapEntry('지붕', (roofText != null && roofText.isNotEmpty && roofText != '-') ? roofText : '-'),
    ]);

    // 주택공시가격 (일반건축물만 표시, 공동주택은 빈 칸)
    if (isMultiUnit) {
      // 공동주택: 빈 행 유지
      rows.add([
        MapEntry('', ''),
        MapEntry('', ''),
      ]);
    } else {
      // 일반건축물: 주택공시가격 표시
      String housePriceText = '-';
      if (info?.housePrice != null && info!.housePrice! > 0) {
        housePriceText = '${_formatPrice(info.housePrice!)}원';
        if (info.housePriceYear != null) {
          housePriceText += ' (${info.housePriceYear}년)';
        }
      }
      rows.add([
        MapEntry('주택공시가격', housePriceText),
        MapEntry('', ''),
      ]);
    }

    return _buildTwoColumnSection('건물정보', rows, width);
  }

  /// 층별정보 섹션 (6행 고정: 헤더 1행 + 데이터 5행)
  static pw.Widget _buildFloorInfoSection(List<FloorInfo> floorInfoList, double width) {
    // 정렬: 지하(높은순) → 지상(낮은순) → 옥탑(낮은순)
    // 예: 지하2층 → 지하1층 → 1층 → 2층 → ... → 8층 → 옥탑1층 → 옥탑2층
    final undergroundFloors = floorInfoList.where((f) => f.floorGb == '지하').toList();
    final aboveGroundFloors = floorInfoList.where((f) => f.floorGb == '지상').toList();
    final rooftopFloors = floorInfoList.where((f) => f.floorGb == '옥탑').toList();

    undergroundFloors.sort((a, b) => (b.floorNo ?? 0).compareTo(a.floorNo ?? 0)); // 내림차순 (2→1)
    aboveGroundFloors.sort((a, b) => (a.floorNo ?? 0).compareTo(b.floorNo ?? 0)); // 오름차순 (1→2→3)
    rooftopFloors.sort((a, b) => (a.floorNo ?? 0).compareTo(b.floorNo ?? 0)); // 오름차순 (1→2)

    final sortedFloors = [...undergroundFloors, ...aboveGroundFloors, ...rooftopFloors];

    final totalFloors = sortedFloors.length;
    final maxDataRows = 5;

    // 5개 이하면 모두 표시, 5개 초과면 4개 + "이하생략"
    final showMore = totalFloors > maxDataRows;
    final displayCount = showMore ? 4 : totalFloors;
    final displayFloors = sortedFloors.take(displayCount).toList();

    // 빈 행 개수 계산 (5행 고정)
    final emptyRowCount = showMore ? 0 : (maxDataRows - totalFloors);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // 섹션 헤더
          _buildSectionHeader('층별 정보'),
          // 테이블 헤더 (층/용도/면적)
          _buildFloorHeaderRow(width),
          // 데이터 행
          ...displayFloors.asMap().entries.map((entry) {
            final idx = entry.key;
            final floor = entry.value;
            final floorName = _getFloorName(floor);
            final purpose = floor.purpose ?? floor.etcPurpose ?? '-';
            final areaText = floor.area != null ? floor.area!.toStringAsFixed(2) : '-';

            return _buildFloorRow(floorName, purpose, areaText, idx % 2 == 1, width);
          }),
          // 이하생략 행
          if (showMore)
            pw.Container(
              height: _rowHeight,
              decoration: pw.BoxDecoration(
                color: displayCount % 2 == 1 ? PdfColor.fromInt(0xFFFCFCFC) : _colorWhite,
                border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.5)),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '이하생략 (총 ${totalFloors}개 층)',
                style: _fonts.style(fontSize: 9, isBold: true, color: _colorGray),
              ),
            ),
          // 빈 행 (5행 채우기)
          ...List.generate(emptyRowCount, (idx) {
            final rowIdx = displayCount + idx;
            return pw.Container(
              height: _rowHeight,
              decoration: pw.BoxDecoration(
                color: rowIdx % 2 == 1 ? PdfColor.fromInt(0xFFFCFCFC) : _colorWhite,
                border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.5)),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 층별정보 테이블 헤더
  static pw.Widget _buildFloorHeaderRow(double width) {
    return pw.Container(
      height: _rowHeight,
      decoration: pw.BoxDecoration(
        color: _colorBgLight,
        border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          // 층 (25%)
          pw.Container(
            width: width * 0.25,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: _colorBorder, width: 0.5)),
            ),
            child: pw.Text('층', style: _fonts.style(fontSize: 9, isBold: true, color: _colorDark)),
          ),
          // 용도 (50%)
          pw.Container(
            width: width * 0.50,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: _colorBorder, width: 0.5)),
            ),
            child: pw.Text('용도', style: _fonts.style(fontSize: 9, isBold: true, color: _colorDark)),
          ),
          // 면적 (25%)
          pw.Expanded(
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text('면적', style: _fonts.style(fontSize: 9, isBold: true, color: _colorDark)),
            ),
          ),
        ],
      ),
    );
  }

  /// 전유부정보 섹션
  static pw.Widget _buildAreaInfoSection(AreaInfo areaInfo, double width) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          _buildSectionHeader('전유부 정보'),
          // 동/호 + 층수 (2열)
          _buildTwoColumnRow(
            '동/호', '${areaInfo.dongNm ?? ''} ${areaInfo.hoNm ?? ''}',
            '층수', '${areaInfo.floorGb ?? ''} ${areaInfo.floorNo ?? ''}층',
            width, false,
          ),
          // 전용면적
          _buildHighlightRow('전용면적', _formatAreaWithPyeong(areaInfo.exclusiveArea), true, width),
          // 공급면적
          _buildHighlightRow('공급면적', _formatAreaWithPyeong(areaInfo.supplyArea), true, width),
          // 대지지분
          _buildHighlightRow('대지지분', _formatAreaWithPyeong(areaInfo.landShare), false, width),
          // 공동주택가격 (년도 포함)
          _buildSingleRow(
            '공동주택가격',
            areaInfo.housePrice != null
                ? '${_formatPrice(areaInfo.housePrice!)} 원${areaInfo.housePriceYear != null ? ' (${areaInfo.housePriceYear}년)' : ''}'
                : '-',
            width, true,
          ),
        ],
      ),
    );
  }

  /// 지도 섹션
  static pw.Widget _buildMapSection(Uint8List? mapImage, BuildingSearchResponse data, double width) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('위치정보'),
          pw.Expanded(
            child: mapImage != null
                ? pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Image(pw.MemoryImage(mapImage), fit: pw.BoxFit.cover),
                  )
                : pw.Container(
                    color: PdfColor.fromInt(0xFFF1F5F9),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('📍', style: pw.TextStyle(fontSize: 28)),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          _getJibunAddress(data),
                          style: _fonts.style(fontSize: 10, isBold: true, color: _colorPrimary),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 푸터
  static pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // 좌측: 안내문구
        pw.Expanded(
          child: pw.Text(
            '본 자료는 공공데이터포털 및 VWorld API를 기반으로 생성되었습니다. 오류가 있을 수 있으니 정확한 정보는 공적장부를 참고하세요.',
            style: _fonts.style(fontSize: 6, color: _colorGray),
          ),
        ),
        pw.SizedBox(width: 16),
        // 우측: 로고 및 제공처
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (_proppediaLogo != null)
              pw.Image(pw.MemoryImage(_proppediaLogo!), height: 13),
            if (_proppediaLogo != null) pw.SizedBox(width: 4),
            pw.Text(
              'Proppedia 제공',
              style: _fonts.style(fontSize: 7, isBold: true, color: _colorPrimary),
            ),
            pw.SizedBox(width: 6),
            pw.Text('|', style: _fonts.style(fontSize: 7, color: _colorGray)),
            pw.SizedBox(width: 6),
            if (_goldenrabbitLogo != null)
              pw.ClipRRect(
                horizontalRadius: 2,
                verticalRadius: 2,
                child: pw.Image(pw.MemoryImage(_goldenrabbitLogo!), height: 13),
              ),
            if (_goldenrabbitLogo != null) pw.SizedBox(width: 4),
            pw.Text(
              '금토끼부동산 제작',
              style: _fonts.style(fontSize: 7, isBold: true, color: _colorDark),
            ),
            pw.Text('   https://goldenrabbit.biz', style: _fonts.style(fontSize: 7, color: _colorGray)),
          ],
        ),
      ],
    );
  }

  // ========== 공통 위젯 ==========

  /// 섹션 헤더
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      height: _sectionHeaderHeight,
      padding: pw.EdgeInsets.symmetric(horizontal: 10),
      decoration: pw.BoxDecoration(
        color: _colorBgLight,
        border: pw.Border(bottom: pw.BorderSide(color: _colorBorder, width: 1.5)),
      ),
      alignment: pw.Alignment.centerLeft,
      child: pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(color: _colorPrimary, shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 8),
          pw.Text(title, style: _fonts.style(fontSize: 11, isBold: true, color: _colorPrimary)),
        ],
      ),
    );
  }

  /// 단일 열 테이블 섹션
  static pw.Widget _buildTableSection(String title, List<MapEntry<String, String>> rows, double width, {bool isSingleColumn = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          _buildSectionHeader(title),
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            return _buildSingleRow(row.key, row.value, width, idx % 2 == 1);
          }),
        ],
      ),
    );
  }

  /// 2열 테이블 섹션
  static pw.Widget _buildTwoColumnSection(String title, List<List<MapEntry<String, String>>> rows, double width) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorBorder, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          _buildSectionHeader(title),
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final left = row.isNotEmpty ? row[0] : MapEntry('', '');
            final right = row.length > 1 ? row[1] : MapEntry('', '');
            return _buildTwoColumnRow(left.key, left.value, right.key, right.value, width, idx % 2 == 1);
          }),
        ],
      ),
    );
  }

  /// 단일 열 행
  static pw.Widget _buildSingleRow(String label, String value, double width, bool isOdd) {
    final labelWidth = width * 0.30;

    return pw.Container(
      height: _rowHeight,
      decoration: pw.BoxDecoration(
        color: isOdd ? PdfColor.fromInt(0xFFFCFCFC) : _colorWhite,
        border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: labelWidth,
            padding: pw.EdgeInsets.only(left: 8),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(label, style: _fonts.style(fontSize: 9, color: _colorGray)),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: pw.EdgeInsets.only(left: 4),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(value, style: _fonts.style(fontSize: 9, isBold: true, color: _colorDark)),
            ),
          ),
        ],
      ),
    );
  }

  /// 2열 행
  static pw.Widget _buildTwoColumnRow(String label1, String value1, String label2, String value2, double width, bool isOdd) {
    final colWidth = width / 2;
    final labelWidth = colWidth * 0.50;

    return pw.Container(
      height: _rowHeight,
      decoration: pw.BoxDecoration(
        color: isOdd ? PdfColor.fromInt(0xFFFCFCFC) : _colorWhite,
        border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          // 좌측 칼럼
          pw.Container(
            width: colWidth,
            child: pw.Row(
              children: [
                pw.Container(
                  width: labelWidth,
                  padding: pw.EdgeInsets.only(left: 6),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(label1, style: _fonts.style(fontSize: 9, color: _colorGray)),
                ),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.only(left: 2),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(value1, style: _fonts.style(fontSize: 8, isBold: true, color: _colorDark)),
                  ),
                ),
              ],
            ),
          ),
          // 중앙 구분선
          pw.Container(width: 0.5, color: _colorBorder),
          // 우측 칼럼
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Container(
                  width: labelWidth,
                  padding: pw.EdgeInsets.only(left: 6),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(label2, style: _fonts.style(fontSize: 9, color: _colorGray)),
                ),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.only(left: 2),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(value2, style: _fonts.style(fontSize: 8, isBold: true, color: _colorDark)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 층별정보 행
  static pw.Widget _buildFloorRow(String floor, String purpose, String area, bool isOdd, double width) {
    return pw.Container(
      height: _rowHeight,
      decoration: pw.BoxDecoration(
        color: isOdd ? PdfColor.fromInt(0xFFFCFCFC) : _colorWhite,
        border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          // 층 (25%)
          pw.Container(
            width: width * 0.25,
            padding: pw.EdgeInsets.only(left: 6),
            alignment: pw.Alignment.centerLeft,
            decoration: pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: _colorBorder, width: 0.5)),
            ),
            child: pw.Text(floor, style: _fonts.style(fontSize: 8, isBold: true, color: _colorDark)),
          ),
          // 용도 (50%)
          pw.Container(
            width: width * 0.50,
            padding: pw.EdgeInsets.only(left: 6),
            alignment: pw.Alignment.centerLeft,
            decoration: pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: _colorBorder, width: 0.5)),
            ),
            child: pw.Text(purpose, style: _fonts.style(fontSize: 8, color: _colorDark)),
          ),
          // 면적 (25%)
          pw.Expanded(
            child: pw.Container(
              padding: pw.EdgeInsets.only(right: 6),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(area, style: _fonts.style(fontSize: 8, isBold: true, color: _colorDark)),
            ),
          ),
        ],
      ),
    );
  }

  /// 하이라이트 행 (전유부정보용)
  static pw.Widget _buildHighlightRow(String label, String value, bool isBlue, double width) {
    final bgColor = isBlue ? PdfColor.fromInt(0xFFEFF6FF) : PdfColor.fromInt(0xFFF0FDF4);
    final textColor = isBlue ? _colorPrimary : PdfColor.fromInt(0xFF22C55E);

    return pw.Container(
      height: _rowHeight,
      padding: pw.EdgeInsets.symmetric(horizontal: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border(top: pw.BorderSide(color: _colorBorder, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: width * 0.42,
            child: pw.Text(label, style: _fonts.style(fontSize: 9, isBold: true, color: textColor)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: _fonts.style(fontSize: 9, isBold: true, color: textColor)),
          ),
        ],
      ),
    );
  }

  // ========== 헬퍼 함수 ==========

  static String _getFloorName(FloorInfo floor) {
    if (floor.floorName != null && floor.floorName!.isNotEmpty) {
      return floor.floorName!;
    }
    final gb = floor.floorGb ?? '지상';
    final no = floor.floorNo ?? 0;
    return '$gb ${no}층';
  }

  static String _getJibunAddress(BuildingSearchResponse data) {
    final buildingInfo = data.building?.buildingInfo;
    final recapInfo = data.building?.recapTitleInfo;
    final address = data.address;

    String? platPlc = recapInfo?['plat_plc']?.toString();
    if (platPlc == null || platPlc == '-' || platPlc.trim().isEmpty) {
      platPlc = buildingInfo?.platPlc;
    }

    if (platPlc == null || platPlc == '-' || platPlc.trim().isEmpty) {
      final parts = <String>[];
      if (address?.sidoName != null) parts.add(address!.sidoName!);
      if (address?.sigunguName != null) parts.add(address!.sigunguName!);
      if (address?.eupmyeondongName != null) parts.add(address!.eupmyeondongName!);
      if (data.codes?.pnu != null && data.codes!.pnu!.length >= 19) {
        final bun = int.tryParse(data.codes!.pnu!.substring(11, 15))?.toString() ?? '';
        final ji = int.tryParse(data.codes!.pnu!.substring(15, 19))?.toString() ?? '';
        if (bun.isNotEmpty) {
          final jibun = (ji.isNotEmpty && ji != '0') ? '$bun-$ji' : bun;
          parts.add(jibun);
        }
      }
      platPlc = parts.join(' ');
    } else if (address?.sidoName != null && !platPlc.startsWith(address!.sidoName!)) {
      platPlc = '${address.sidoName!} $platPlc';
    }

    return platPlc.replaceAll(RegExp(r'번지$'), '').trim();
  }

  static String _getRoadAddress(BuildingSearchResponse data) {
    final buildingInfo = data.building?.buildingInfo;
    final recapInfo = data.building?.recapTitleInfo;

    String? roadAddr = recapInfo?['new_plat_plc']?.toString();
    if (roadAddr == null || roadAddr == '-' || roadAddr.trim().isEmpty) {
      roadAddr = buildingInfo?.newPlatPlc;
    }

    return roadAddr?.trim() ?? '';
  }

  static String _formatNumber(double value) {
    if (value == value.toInt()) {
      return NumberFormat('#,###').format(value.toInt());
    }
    return NumberFormat('#,###.#').format(value);
  }

  static String _formatPrice(int value) {
    return NumberFormat('#,###').format(value);
  }

  static String _toPyeong(double sqm) {
    return (sqm / 3.305785).toStringAsFixed(1);
  }

  static String _formatAreaWithPyeong(double? area) {
    if (area == null) return '-';
    return '${_formatNumber(area)}㎡ (약 ${_toPyeong(area)}평)';
  }
}
