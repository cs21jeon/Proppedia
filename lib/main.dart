import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오맵 SDK 초기화 (Web이 아닌 경우에만)
  if (!kIsWeb) {
    AuthRepository.initialize(appKey: '1a41388ca117958d172c6ba8e71c7c75');
  }

  runApp(
    const ProviderScope(
      child: PropediaApp(),
    ),
  );
}