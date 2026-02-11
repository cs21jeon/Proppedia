import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:propedia/core/pdf/pdf_generator.dart';
import 'package:propedia/data/datasources/remote/naver_map_api.dart';
import 'package:propedia/data/dto/building_dto.dart';
import 'package:propedia/presentation/providers/map_provider.dart';
import 'package:share_plus/share_plus.dart';

/// PDF 생성 상태
enum PdfStatus { initial, loading, success, error }

/// PDF 상태 클래스
class PdfState {
  final PdfStatus status;
  final Uint8List? pdfBytes;
  final String? errorMessage;

  const PdfState({
    this.status = PdfStatus.initial,
    this.pdfBytes,
    this.errorMessage,
  });

  PdfState copyWith({
    PdfStatus? status,
    Uint8List? pdfBytes,
    String? errorMessage,
  }) {
    return PdfState(
      status: status ?? this.status,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// PDF 상태 관리 Notifier
class PdfNotifier extends StateNotifier<PdfState> {
  final Ref _ref;
  final NaverMapApi _naverMapApi;

  PdfNotifier(this._ref)
      : _naverMapApi = NaverMapApi(),
        super(const PdfState());

  /// PDF 생성
  Future<void> generatePdf({
    required BuildingSearchResponse data,
    AreaInfo? areaInfo,
  }) async {
    state = state.copyWith(status: PdfStatus.loading, errorMessage: null);

    try {
      // 1. 좌표 가져오기 (지오코딩)
      Uint8List? mapImage;
      final address = _getAddress(data);

      if (address.isNotEmpty && _naverMapApi.isConfigured) {
        final geocoding = await _ref.read(geocodingProvider(address).future);

        if (geocoding.success && geocoding.lat != null && geocoding.lng != null) {
          // 2. 네이버 Static Map 이미지 가져오기
          mapImage = await _naverMapApi.getStaticMapImage(
            lat: geocoding.lat!,
            lng: geocoding.lng!,
            width: 600,
            height: 400,
            level: 17,
          );
        }
      }

      // 3. PDF 생성
      final pdfBytes = await PdfGenerator.generatePropertyPdf(
        data: data,
        areaInfo: areaInfo,
        mapImage: mapImage,
      );

      state = state.copyWith(
        status: PdfStatus.success,
        pdfBytes: pdfBytes,
      );
    } catch (e) {
      state = state.copyWith(
        status: PdfStatus.error,
        errorMessage: 'PDF 생성 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// PDF 미리보기
  Future<void> previewPdf() async {
    if (state.pdfBytes == null) return;

    await Printing.layoutPdf(
      onLayout: (_) async => state.pdfBytes!,
      name: _generateFileName(),
    );
  }

  /// PDF 저장
  Future<String?> savePdf() async {
    if (state.pdfBytes == null) return null;

    try {
      if (kIsWeb) {
        // Web: 다운로드 트리거
        await Printing.sharePdf(
          bytes: state.pdfBytes!,
          filename: _generateFileName(),
        );
        return 'PDF 다운로드가 시작되었습니다';
      } else {
        // 모바일/데스크톱: 파일 저장
        final directory = await _getDownloadDirectory();
        final fileName = _generateFileName();
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(state.pdfBytes!);

        return filePath;
      }
    } catch (e) {
      return null;
    }
  }

  /// PDF 공유
  Future<void> sharePdf() async {
    if (state.pdfBytes == null) return;

    await Printing.sharePdf(
      bytes: state.pdfBytes!,
      filename: _generateFileName(),
    );
  }

  /// 상태 초기화
  void reset() {
    state = const PdfState();
  }

  /// 다운로드 디렉토리 가져오기
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Android: Downloads 폴더
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) {
        return dir;
      }
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      // Windows/macOS/Linux: Documents 폴더
      return await getApplicationDocumentsDirectory();
    }
  }

  /// 파일명 생성
  String _generateFileName() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '부동산정보_$timestamp.pdf';
  }

  /// 주소 문자열 생성
  String _getAddress(BuildingSearchResponse data) {
    final buildingInfo = data.building?.buildingInfo;
    final recapInfo = data.building?.recapTitleInfo;
    final address = data.address;

    String? platPlc = recapInfo?['plat_plc'] as String?;
    if (platPlc == null || platPlc == '-' || platPlc.trim().isEmpty) {
      platPlc = buildingInfo?.platPlc;
    }

    if (platPlc == null || platPlc == '-' || platPlc.trim().isEmpty) {
      platPlc = address?.fullAddress;
    }

    if (platPlc == null || platPlc.trim().isEmpty) {
      final parts = <String>[];
      if (address?.sidoName != null) parts.add(address!.sidoName!);
      if (address?.sigunguName != null) parts.add(address!.sigunguName!);
      if (address?.eupmyeondongName != null) parts.add(address!.eupmyeondongName!);
      platPlc = parts.join(' ');
    }

    if (address?.sidoName != null && platPlc != null && !platPlc.startsWith(address!.sidoName!)) {
      platPlc = '${address.sidoName!} $platPlc';
    }

    return platPlc?.replaceAll(RegExp(r'번지$'), '').trim() ?? '';
  }
}

/// PDF Provider
final pdfProvider = StateNotifierProvider<PdfNotifier, PdfState>((ref) {
  return PdfNotifier(ref);
});
