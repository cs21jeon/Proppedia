import 'package:dio/dio.dart';
import 'package:propedia/data/dto/auth_dto.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// 회원가입
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/app/api/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      // 에러 응답에서 메시지 추출
      if (e.response?.data != null) {
        return AuthResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  /// 로그인
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/app/api/auth/login',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      // 에러 응답에서 메시지 추출
      if (e.response?.data != null) {
        return AuthResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  /// 토큰 갱신
  Future<AuthResponse> refreshToken(RefreshTokenRequest request) async {
    try {
      final response = await _dio.post(
        '/app/api/auth/refresh',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return AuthResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  /// 내 정보 조회
  Future<UserResponse> getMe() async {
    final response = await _dio.get('/app/api/auth/me');
    return UserResponse.fromJson(response.data);
  }

  /// 로그아웃
  Future<ApiResponse> logout() async {
    final response = await _dio.post('/app/api/auth/logout');
    return ApiResponse.fromJson(response.data);
  }
}
