import 'package:dio/dio.dart';
import 'package:propedia/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor({required this.tokenStorage, required this.dio});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 인증이 필요없는 경로는 토큰 추가 안함
    final noAuthPaths = [
      '/app/api/auth/login',
      '/app/api/auth/register',
      '/app/api/auth/refresh',
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
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await tokenStorage.getRefreshToken();
        if (refreshToken != null) {
          // 토큰 갱신 시도
          final response = await dio.post(
            '/app/api/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.data['success'] == true) {
            final newAccessToken = response.data['access_token'] as String;
            await tokenStorage.saveAccessToken(newAccessToken);

            // 원래 요청 재시도
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(options);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        // 토큰 갱신 실패 - 로그아웃 처리 필요
        await tokenStorage.deleteTokens();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}
