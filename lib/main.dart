import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // 카카오맵 SDK 초기화 (Web이 아닌 경우에만)
  if (!kIsWeb) {
    final kakaoJsKey = dotenv.env['KAKAO_JAVASCRIPT_KEY'] ?? '';
    AuthRepository.initialize(appKey: kakaoJsKey);
  }

  runApp(
    const ProviderScope(
      child: PropediaApp(),
    ),
  );
}