import 'package:dio/dio.dart';
import 'package:propedia/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  AuthInterceptor({required this.tokenStorage});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 인증이 필요없는 경로
    final noAuthPaths = [
      '/app/api/auth/google',
    ];

    if (!noAuthPaths.any((path) => options.path.contains(path))) {
      final token = await tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // JWT 만료 시 토큰 삭제 (재로그인 유도)
      await tokenStorage.deleteTokens();
    }

    handler.next(err);
  }
}
