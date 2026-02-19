import 'package:propedia/core/storage/login_preferences.dart';
import 'package:propedia/core/storage/token_storage.dart';
import 'package:propedia/data/datasources/remote/auth_api.dart';
import 'package:propedia/data/dto/auth_dto.dart';
import 'package:propedia/domain/entities/user.dart';

class AuthRepository {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  final LoginPreferences _loginPreferences;

  AuthRepository({
    required AuthApi authApi,
    required TokenStorage tokenStorage,
    LoginPreferences? loginPreferences,
  })  : _authApi = authApi,
        _tokenStorage = tokenStorage,
        _loginPreferences = loginPreferences ?? LoginPreferences();

  /// 회원가입
  Future<User> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _authApi.register(
      RegisterRequest(email: email, password: password, name: name),
    );

    if (!response.success || response.user == null) {
      throw Exception(response.message ?? '회원가입에 실패했습니다');
    }

    return response.user!;
  }

  /// 로그인
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _authApi.login(
      LoginRequest(email: email, password: password),
    );

    if (!response.success ||
        response.accessToken == null ||
        response.refreshToken == null ||
        response.user == null) {
      throw Exception(response.message ?? '로그인에 실패했습니다');
    }

    // 토큰 저장
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken!,
      refreshToken: response.refreshToken!,
    );

    return response.user!;
  }

  /// 내 정보 조회
  Future<User?> getMe() async {
    try {
      final response = await _authApi.getMe();
      if (response.success && response.user != null) {
        return response.user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      // 서버 로그아웃 실패해도 로컬 토큰 삭제
    }
    await _tokenStorage.deleteTokens();
  }

  /// 자동 로그인 체크
  /// 토큰이 있고, 자동 로그인 설정이 켜져 있는 경우에만 자동 로그인
  Future<User?> checkAutoLogin() async {
    // 1. 토큰 존재 여부 확인
    final hasToken = await _tokenStorage.hasToken();
    if (!hasToken) return null;

    // 2. 자동 로그인 설정 확인
    final autoLoginEnabled = await _loginPreferences.getAutoLogin();
    if (!autoLoginEnabled) {
      // 자동 로그인이 꺼져 있으면 토큰은 유지하되 로그인 화면으로 이동
      return null;
    }

    // 3. 서버에서 사용자 정보 조회
    return await getMe();
  }

  /// 토큰 존재 여부
  Future<bool> hasToken() async {
    return await _tokenStorage.hasToken();
  }

  /// 자동 로그인 설정 여부
  Future<bool> isAutoLoginEnabled() async {
    return await _loginPreferences.getAutoLogin();
  }
}
