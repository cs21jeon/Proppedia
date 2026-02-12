# Propedia (부동산백과) Flutter 앱 마이그레이션 계획

## Context (배경)

현재 GoldenRabbit 부동산 정보 시스템을 **Propedia (부동산백과)** 라는 이름의 Flutter 앱으로 마이그레이션합니다. 기존 시스템은 정적 HTML/CSS/JavaScript 프론트엔드와 Flask 백엔드로 구성되어 있으며, 이를 크로스 플랫폼 모바일 앱으로 전환하여 다음 목표를 달성하고자 합니다:

### 마이그레이션 이유
1. **모바일 네이티브 경험 제공**: Android/iOS 앱스토어 배포를 통한 접근성 향상
2. **크로스 플랫폼 개발**: 단일 코드베이스로 Android, iOS, Web 지원
3. **향상된 사용자 경험**: 네이티브 성능, 오프라인 지원, 푸시 알림 등
4. **유지보수 효율성**: 기존 HTML/JS 파편화된 구조를 Flutter의 위젯 기반 구조로 통합

### 프로젝트 범위
- **타겟 플랫폼**: Android, iOS, Flutter Web (모두)
- **마이그레이션 범위**: 사용자 기능 전체 (어드민 기능은 기존 웹 유지)
- **우선순위**: **건축물 조회 앱** 기능 먼저 개발 (`/app/` 디렉토리 기능)
- **예상 기간**: 12-14주

### 현재 시스템 구조

**프론트엔드 (2개 인터페이스)**:
1. 메인 사이트 (`/index.html` 등): 금토끼부동산 매물 정보 조회
2. 건축물 조회 앱 (`/app/` 디렉토리): 도로명/지번/지도 검색 기능

**백엔드**:
- API Server (8000): 공개 매물 API
- Property Manager (5000): 건축물 검색 API + JWT 인증

---

## 권장 접근 방식

### 아키텍처

**Clean Architecture + MVVM + Riverpod**를 채택합니다:

```
lib/
├── core/                   # 네트워크, 라우팅, 유틸리티
├── data/                   # 모델, Repository 구현, API
├── domain/                 # 비즈니스 로직 (선택적)
├── presentation/           # UI, 화면, 위젯, Provider
└── shared/                 # 테마, 확장 함수
```

**레이어 분리**:
- Presentation (UI) → Provider (상태 관리) → Repository → API
- 각 레이어는 독립적으로 테스트 가능
- 의존성 주입은 Riverpod으로 자동 처리

### 상태 관리: Riverpod 2.0+

- **FutureProvider**: 단순 API 호출 (매물 목록 등)
- **StateNotifier**: 복잡한 상태 (검색, 필터링)
- **StateProvider**: 간단한 UI 상태 (탭 인덱스, 다크모드)
- **StreamProvider**: 실시간 데이터 (검색 기록 감시)

### 네트워크: Dio + Retrofit

- `ApiClient`: Dio 기반 HTTP 클라이언트
- `AuthInterceptor`: JWT 토큰 자동 추가 및 갱신
- 에러 핸들링: 네트워크, 인증, 서버 오류 분리

### 지도 기능: 카카오맵

- Android/iOS: `kakao_map_plugin`
- Web: `HtmlElementView`로 기존 HTML 재사용
- Native App Key는 환경설정 파일에서 확인 가능

### 로컬 데이터베이스: Isar

- 검색 기록, 즐겨찾기 저장
- SQLite보다 빠르고 타입 안전함
- Stream으로 실시간 UI 업데이트

### 보안

- JWT 토큰: `flutter_secure_storage`로 암호화 저장
- API 키: 환경 변수 관리
- HTTPS 통신 기본 설정

---

## 단계별 마이그레이션 계획 (우선순위 반영)

### Phase 1: 프로젝트 초기화 및 인프라 구축 (1주)

**작업 내용**:
1. Flutter 프로젝트 생성: `flutter create propedia`
2. 필수 패키지 설치 (pubspec.yaml)
3. 폴더 구조 생성 (core, data, presentation 등)
4. 테마 설정 (Tailwind CSS → Flutter 변환)
5. ApiClient, AuthInterceptor 구현
6. go_router 라우팅 설정

**검증**: 빈 화면이지만 앱 실행 및 네비게이션 작동 확인

---

### Phase 2: 인증 시스템 구현 (1주)

**작업 내용**:
1. User 모델, Auth DTO 정의
2. AuthRepository + AuthApi 구현
3. JWT 토큰 저장/불러오기 (SecureStorage)
4. AuthProvider (Riverpod)
5. LoginScreen, RegisterScreen UI
6. 자동 로그인 처리

**API 연동**:
- `POST /app/api/auth/register`
- `POST /app/api/auth/login`
- `POST /app/api/auth/refresh`

**검증**: 회원가입 → 로그인 → 앱 재시작 → 자동 로그인

---

### Phase 3: 건축물 검색 기능 (도로명/지번) (2주)

**우선순위 1 - 핵심 기능**

**작업 내용**:
1. Building, Land 모델 정의
2. BuildingRepository + BuildingApi 구현
3. SearchProvider (StateNotifier)
4. SearchMethodScreen (검색 방식 선택)
5. SearchRoadScreen (도로명 검색)
6. SearchJibunScreen (지번 검색 + 법정동 자동완성)
7. ResultScreen (검색 결과 상세 표시)

**API 연동**:
- `POST /app/api/search/road` - 도로명 검색
- `POST /app/api/search/jibun` - 지번 검색
- `GET /app/api/bjdong/search?query=...` - 법정동 자동완성

**주요 기능**:
- 층별 정보 표시
- 토지 특성 정보
- 대지지분 계산 표시
- PDF 다운로드 (선택적)

**검증**: 도로명/지번 검색 → 건축물 정보 표시 → 토지 정보 확인

---

### Phase 4: 지도 검색 기능 (2주)

**우선순위 2**

**작업 내용**:
1. 카카오맵 SDK 설정 (Android/iOS)
2. SearchMapScreen 구현
3. 좌표 클릭 → 지번 변환
4. 필지 경계 표시 (GeoJSON → Polygon)
5. Flutter Web: HtmlElementView로 기존 HTML 재사용

**API 연동**:
- `POST /app/api/map/click-jibun` - 좌표 → 지번 변환
- `GET /app/api/map/parcel-boundary?pnu=...` - 필지 경계

**검증**: 지도 로드 → 클릭 → 지번 표시 → 필지 경계 표시 → 검색

---

### Phase 5: 검색 기록 및 즐겨찾기 (1주)

**작업 내용**:
1. Isar 데이터베이스 초기화
2. SearchHistory, Favorite 스키마 정의
3. DatabaseService 구현
4. HistoryScreen (검색 기록 목록)
5. FavoritesScreen (즐겨찾기 목록)
6. 서버 동기화 (선택적)

**API 연동**:
- `GET /app/api/user/search-history`
- `POST /app/api/user/favorites`
- `DELETE /app/api/user/favorites/{id}`

**검증**: 검색 → 기록 저장 → 기록 목록 표시 → 삭제 → 즐겨찾기 추가

---

### Phase 6: 프로필 및 설정 (1주)

**작업 내용**:
1. ProfileScreen UI
2. 다크모드 토글 (ThemeMode Provider)
3. 사용 통계 표시
4. 로그아웃

**API 연동**:
- `GET /app/api/user/usage-stats`

**검증**: 프로필 확인 → 다크모드 전환 → 사용 통계 표시 → 로그아웃

---

### Phase 7: 매물 정보 조회 (메인 사이트 기능) (2주)

**우선순위 3 - 건축물 앱 완성 후 진행**

**작업 내용**:
1. Property 모델 정의
2. PropertyRepository + PropertyApi 구현
3. HomeScreen (매물 검색 인터페이스)
4. PropertyListView (카테고리별 매물 목록)
5. PropertyCard 위젯
6. PropertyDetailScreen (매물 상세)
7. 조건 검색 (매가, 수익률, 면적 등)

**API 연동**:
- `GET /api/property-list`
- `GET /api/category-properties?view=...`
- `GET /api/property-detail?id=...`
- `POST /property-manager/api/search-map`

**검증**: 매물 목록 로드 → 카테고리 필터 → 상세 보기 → 조건 검색

---

### Phase 8: 매물 지도 표시 (1주)

**작업 내용**:
1. 카카오맵에 매물 마커 표시
2. 마커 클릭 → 매물 상세 모달
3. coordinates.json 캐시 활용

**검증**: 지도에 279개 매물 표시 → 마커 클릭 → 상세 정보

---

### Phase 9: Flutter Web 빌드 및 배포 (1주)

**작업 내용**:
1. 반응형 디자인 검증
2. Web 빌드 최적화 (CanvasKit vs HTML)
3. PWA 설정 (manifest.json)
4. Nginx 설정 (`/flutter-app/` 경로)

**배포**:
```bash
flutter build web --release --web-renderer html
sudo cp -r build/web/* /home/webapp/goldenrabbit/frontend/public/flutter-app/
sudo systemctl reload nginx
```

**검증**: https://goldenrabbit.biz/flutter-app/ 접속 확인

---

### Phase 10: 모바일 앱 빌드 및 배포 (2주)

**Android**:
1. 서명 키 생성
2. Play Console 앱 등록
3. AAB 빌드: `flutter build appbundle --release`
4. 내부 테스트 → 프로덕션 배포

**iOS**:
1. Apple Developer 설정
2. 프로비저닝 프로파일
3. IPA 빌드: `flutter build ipa --release`
4. App Store Connect 업로드

**검증**: 각 플랫폼 스토어에서 다운로드 및 실행 확인

---

### Phase 11: 테스트 및 버그 수정 (2주)

**작업 내용**:
1. 유닛 테스트 (Repository, API)
2. 위젯 테스트 (주요 화면)
3. 통합 테스트 (사용자 시나리오)
4. 버그 수정 및 성능 최적화

**검증**: 모든 테스트 통과

---

## 주요 파일 및 경로

### 새로 생성할 Flutter 프로젝트

**프로젝트 루트**: `/home/webapp/goldenrabbit/propedia/`

**핵심 파일**:
- `lib/main.dart` - 앱 진입점
- `lib/core/network/api_client.dart` - Dio HTTP 클라이언트
- `lib/core/network/auth_interceptor.dart` - JWT 인터셉터
- `lib/data/repositories/building_repository.dart` - 건축물 검색 Repository
- `lib/data/datasources/remote/building_api.dart` - 건축물 검색 API
- `lib/presentation/screens/search/search_jibun_screen.dart` - 지번 검색 화면
- `lib/presentation/screens/search/result_screen.dart` - 검색 결과 화면
- `lib/presentation/providers/search_provider.dart` - 검색 상태 관리
- `pubspec.yaml` - 패키지 의존성

### 참조할 기존 파일

**프론트엔드 (UI/UX 참고)**:
- `/home/webapp/goldenrabbit/frontend/public/app/index.html` - 검색 방식 선택 UI
- `/home/webapp/goldenrabbit/frontend/public/app/search-jibun.html` - 지번 검색 UI
- `/home/webapp/goldenrabbit/frontend/public/app/result.html` - 검색 결과 표시 UI
- `/home/webapp/goldenrabbit/frontend/public/app/js/search.js` - API 호출 패턴
- `/home/webapp/goldenrabbit/frontend/public/app/js/map.js` - 지도 기능

**백엔드 (API 스펙 확인)**:
- `/home/webapp/goldenrabbit/backend/property-manager/routes/app_api.py` - 건축물 검색 API 엔드포인트
- `/home/webapp/goldenrabbit/backend/property-manager/routes/app_auth.py` - JWT 인증 API
- `/home/webapp/goldenrabbit/backend/api/app.py` - 매물 API 엔드포인트

**환경 설정**:
- `/home/webapp/goldenrabbit/backend/.env` - 카카오맵 API 키 확인
- `/home/webapp/goldenrabbit/config/nginx/goldenrabbit.conf` - Nginx 설정 참고

---

## 재사용 가능한 백엔드 API

기존 Flask 백엔드 API를 그대로 사용합니다:

### 건축물 검색 API (Port 5000)

```
POST https://goldenrabbit.biz/app/api/search/road
POST https://goldenrabbit.biz/app/api/search/jibun
POST https://goldenrabbit.biz/app/api/search/bdmgtsn
GET  https://goldenrabbit.biz/app/api/bjdong/search?query=사당동
POST https://goldenrabbit.biz/app/api/map/click-jibun
GET  https://goldenrabbit.biz/app/api/map/parcel-boundary?pnu=1159010700103020000
```

### 인증 API (Port 5000)

```
POST https://goldenrabbit.biz/app/api/auth/register
POST https://goldenrabbit.biz/app/api/auth/login
POST https://goldenrabbit.biz/app/api/auth/refresh
GET  https://goldenrabbit.biz/property-manager/check-auth
```

### 사용자 데이터 API (Port 5000)

```
GET  https://goldenrabbit.biz/app/api/user/search-history
POST https://goldenrabbit.biz/app/api/user/favorites
GET  https://goldenrabbit.biz/app/api/user/usage-stats
```

### 매물 API (Port 8000)

```
GET  https://goldenrabbit.biz/api/property-list
GET  https://goldenrabbit.biz/api/category-properties?view=viwXXX
GET  https://goldenrabbit.biz/api/property-detail?id=recXXX
POST https://goldenrabbit.biz/api/submit-inquiry
POST https://goldenrabbit.biz/property-manager/api/search-map
```

---

## 필수 패키지 (pubspec.yaml)

```yaml
name: propedia
description: Propedia - 부동산백과
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # 상태 관리
  flutter_riverpod: ^2.4.10
  riverpod_annotation: ^2.3.4

  # 네트워크
  dio: ^5.4.0
  retrofit: ^4.0.3

  # 로컬 저장소
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # 라우팅
  go_router: ^13.0.0

  # UI
  cached_network_image: ^3.3.1
  flutter_hooks: ^0.20.5
  hooks_riverpod: ^2.4.10
  shimmer: ^3.0.0

  # 지도
  kakao_map_plugin: ^0.4.2
  geolocator: ^11.0.0

  # JSON
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # 유틸리티
  intl: ^0.19.0
  logger: ^2.0.2+1
  flutter_svg: ^2.0.9
  url_launcher: ^6.2.4

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.11
  isar_generator: ^3.1.0+1
  retrofit_generator: ^8.0.6
  mocktail: ^1.0.3
```

---

## 검증 방법 (End-to-End)

### 건축물 조회 앱 검증 시나리오

1. **회원가입 및 로그인**
   - 앱 실행 → 회원가입 화면
   - 이메일, 비밀번호 입력 → 회원가입 API 호출
   - 자동 로그인 → 홈 화면 이동
   - 토큰이 SecureStorage에 저장되었는지 확인

2. **지번 검색**
   - "지번주소로 검색" 선택
   - 법정동 입력: "사당동" → 자동완성 목록 표시
   - "사당동" 선택 → bjdong_code 자동 입력
   - 본번: "314", 부번: "21" 입력
   - "검색" 버튼 → API 호출 → 로딩 표시
   - 검색 결과 화면에 건축물 정보 표시
   - 층별 정보, 토지 정보 확인

3. **검색 기록 저장 및 조회**
   - 검색 후 자동으로 Isar DB에 저장
   - 하단 탭 "기록" 선택 → 검색 기록 목록 표시
   - 최신순 정렬 확인
   - 기록 클릭 → 상세 정보 다시 표시

4. **즐겨찾기**
   - 검색 결과에서 "즐겨찾기 추가" 버튼
   - 서버 API 호출 + 로컬 DB 저장
   - "즐겨찾기" 탭 → 목록 표시
   - 삭제 기능 확인

5. **지도 검색**
   - "지도에서 검색" 선택
   - 카카오맵 로드 확인
   - 지도 클릭 → 좌표 → 지번 변환 API 호출
   - 지번 표시 → "이 위치 검색" 버튼
   - 검색 결과 표시

6. **프로필 및 설정**
   - "프로필" 탭 → 사용자 정보 표시
   - 다크모드 토글 → 테마 변경 확인
   - 사용 통계 표시 (검색 횟수 등)
   - "로그아웃" → 토큰 삭제 → 로그인 화면 이동

7. **오프라인 지원**
   - 네트워크 끊기
   - 검색 기록 탭 → 로컬 DB에서 로드 확인
   - 즐겨찾기 탭 → 로컬 데이터 표시

8. **앱 재시작**
   - 앱 종료 후 재실행
   - 토큰 유효하면 자동 로그인 확인
   - 검색 기록 유지 확인

---

## 성공 기준

### 기능 요구사항
- ✅ 회원가입, 로그인, 자동 로그인 작동
- ✅ 도로명/지번/지도 검색 모두 작동
- ✅ 검색 결과에 건축물 정보 정확히 표시
- ✅ 검색 기록 저장 및 목록 표시
- ✅ 즐겨찾기 추가/삭제
- ✅ 지도에 좌표 표시 및 필지 경계 표시
- ✅ 다크모드 지원
- ✅ 오프라인에서 기록 조회 가능

### 성능 요구사항
- ✅ API 응답 시간 2초 이내
- ✅ 지도 로딩 3초 이내
- ✅ 60fps 부드러운 스크롤

### 품질 요구사항
- ✅ 유닛 테스트 커버리지 70% 이상
- ✅ 위젯 테스트 주요 화면 모두 통과
- ✅ 통합 테스트 사용자 시나리오 통과
- ✅ 에러 핸들링 완료 (네트워크, 인증, 서버 오류)

### 배포 요구사항
- ✅ Android APK/AAB 빌드 성공
- ✅ iOS IPA 빌드 성공
- ✅ Flutter Web 빌드 및 Nginx 배포 성공
- ✅ 각 플랫폼에서 정상 실행

---

## 예상 타임라인 (14주)

| Phase | 내용 | 기간 | 누적 |
|-------|------|------|------|
| 1 | 프로젝트 초기화 | 1주 | 1주 |
| 2 | 인증 시스템 | 1주 | 2주 |
| 3 | 건축물 검색 (도로명/지번) | 2주 | 4주 |
| 4 | 지도 검색 | 2주 | 6주 |
| 5 | 검색 기록/즐겨찾기 | 1주 | 7주 |
| 6 | 프로필/설정 | 1주 | 8주 |
| 7 | 매물 정보 조회 | 2주 | 10주 |
| 8 | 매물 지도 표시 | 1주 | 11주 |
| 9 | Flutter Web 배포 | 1주 | 12주 |
| 10 | 모바일 앱 배포 | 2주 | 14주 |

**Phase 11 (테스트/버그 수정)**은 각 Phase 중간에 수행하여 품질 확보

---

## 주의사항

### 카카오맵 Native App Key
- 환경 설정 파일 (`/home/webapp/goldenrabbit/backend/.env`)에서 `VWORLD_APIKEY` 확인
- Native App Key가 별도로 필요한 경우 카카오 개발자 콘솔에서 발급
- Android: `android/app/src/main/AndroidManifest.xml`에 설정
- iOS: `ios/Runner/AppDelegate.swift`에 설정

### 기존 시스템 호환성
- 백엔드 API는 그대로 사용 (변경 없음)
- JWT 토큰 형식 유지
- Airtable 데이터 구조 유지

### 성능 최적화
- 이미지 캐싱 (`cached_network_image`)
- API 응답 캐싱 (Riverpod `keepAlive`)
- 리스트 가상화 (`ListView.builder`)
- 오프라인 지원 (Isar DB 캐시)

### 보안
- JWT 토큰 암호화 저장 (`flutter_secure_storage`)
- HTTPS 통신 강제
- API 키 환경 변수 관리
- 민감 정보 로깅 제거

---

## 개발 환경 설정 (중요!)

### 로컬 PC에서 개발 (권장)

**Flutter 앱 개발은 반드시 로컬 PC에서 진행**해야 합니다. 서버에서 개발하면 다음과 같은 문제가 발생합니다:

❌ **서버 개발의 문제점**:
1. **리소스 부족**: Flutter 빌드는 메모리 4GB+, CPU 멀티코어 필요 → 서버 부하 발생
2. **에뮬레이터 불가**: Android/iOS 에뮬레이터는 GUI 환경 필요 → 서버(CLI)에서 실행 불가
3. **개발 경험 저하**: Hot Reload, 디버깅 등이 원활하지 않음
4. **용량 문제**: Android SDK, iOS SDK 합치면 10GB+ 차지
5. **서버 다운 위험**: 빌드 시 CPU/메모리 사용량 급증

✅ **권장 개발 환경**:

**로컬 PC (Windows/macOS)**에서 개발 → 완성된 빌드만 서버에 배포

```
로컬 PC                                   서버 (goldenrabbit.biz)
├── Flutter 프로젝트 개발                  ├── 백엔드 API (Flask)
├── Android 에뮬레이터 테스트               ├── Nginx 웹서버
├── iOS 시뮬레이터 테스트 (macOS만)         └── Flutter Web 빌드 배포
├── 코드 작성 및 디버깅                          (build/web/ 복사)
└── Git 커밋
```

### 로컬 PC 개발 환경 설정

**1. Flutter SDK 설치 확인**:
```bash
# 로컬 PC에서
flutter --version
flutter doctor
```

**2. 프로젝트 생성 (로컬 PC)**:
```bash
# 로컬 PC의 작업 디렉토리에서
cd ~/projects  # 또는 원하는 경로
flutter create propedia
cd propedia
```

**3. Git 연동 (선택사항)**:
```bash
# 기존 GoldenRabbit 레포지토리에 propedia/ 폴더 추가
git init
git remote add origin <your-repo-url>
```

**4. 로컬에서 개발 및 테스트**:
```bash
# 개발 모드 실행 (Hot Reload 지원)
flutter run

# 또는 Android 에뮬레이터에서
flutter run -d <device-id>

# 또는 Chrome (Web)에서
flutter run -d chrome
```

**5. Flutter Web 빌드 후 서버 배포**:
```bash
# 로컬 PC에서 Web 빌드
flutter build web --release --web-renderer html

# 빌드 결과물을 서버로 복사 (SCP/SFTP)
scp -r build/web/* webapp@goldenrabbit.biz:/home/webapp/goldenrabbit/frontend/public/flutter-app/

# 또는 Git으로 관리한다면
git add build/web/
git commit -m "Build Flutter Web"
git push
# 서버에서 git pull
```

### Android/iOS 앱 빌드

**Android**:
```bash
# 로컬 PC에서 APK 빌드
flutter build apk --release

# AAB (Play Store용)
flutter build appbundle --release

# 빌드 결과물 위치
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

**iOS** (macOS만 가능):
```bash
# macOS에서 IPA 빌드
flutter build ipa --release

# Xcode에서 서명 후 App Store Connect 업로드
```

### 서버 사용 (배포 전용)

서버는 **오직 배포 목적**으로만 사용:

1. **Flutter Web 호스팅**:
   - 로컬에서 빌드한 `build/web/` 폴더를 서버로 복사
   - Nginx가 정적 파일로 서빙

2. **백엔드 API 유지**:
   - 기존 Flask API는 그대로 유지
   - Flutter 앱은 이 API를 호출

3. **지속적 배포** (선택사항):
   - GitHub Actions로 자동 빌드 및 배포 설정 가능

---

## 다음 단계

1. **로컬 PC에서 프로젝트 생성**:
   ```bash
   # 로컬 PC의 작업 디렉토리에서
   cd ~/projects  # Windows: C:\Users\yourname\projects
   flutter create propedia
   cd propedia
   ```

2. **pubspec.yaml 설정**: 위의 필수 패키지 추가

3. **폴더 구조 생성**: `lib/` 디렉토리 구조화

4. **Phase 1부터 순차적으로 진행** (로컬 PC에서)

5. **각 Phase 완료 후 검증 시나리오 수행** (로컬 에뮬레이터/시뮬레이터)

6. **완성 후 서버 배포**:
   - Flutter Web: `build/web/` → 서버로 복사
   - Android: Play Store 업로드
   - iOS: App Store 업로드

이 계획대로 진행하면 약 14주 내에 완전한 Flutter 앱을 구축할 수 있습니다.


● 2️⃣ 진행 현황 요약 (2026-02-10 업데이트)

  ## Phase 1: 프로젝트 초기화 ✅ 완료
  - ✅ Flutter 프로젝트 생성
  - ✅ pubspec.yaml 패키지 설정
  - ✅ Clean Architecture 폴더 구조 생성
  - ✅ 테마 설정 (app_colors.dart, app_text_styles.dart, app_theme.dart)
  - ✅ app.dart, main.dart 구현
  - ✅ 앱 실행 테스트 성공 (Chrome)
  - ✅ Flutter Web 빌드 성공

  ## Phase 2: 인증 시스템 ✅ 완료

  ### 구현된 파일 목록:

  **모델/DTO (Freezed)**
  - lib/domain/entities/user.dart - User 엔티티
  - lib/data/dto/auth_dto.dart - LoginRequest, RegisterRequest, AuthResponse 등

  **네트워크 (Dio)**
  - lib/core/network/api_client.dart - Dio HTTP 클라이언트 (baseUrl: https://goldenrabbit.biz)
  - lib/core/network/auth_interceptor.dart - JWT 토큰 자동 추가/갱신 인터셉터
  - lib/data/datasources/remote/auth_api.dart - 인증 API 호출 클래스

  **토큰 저장 (SecureStorage)**
  - lib/core/storage/token_storage.dart - 암호화된 토큰 저장/관리

  **Repository & Provider (Riverpod)**
  - lib/data/repositories/auth_repository.dart - 인증 비즈니스 로직
  - lib/presentation/providers/auth_provider.dart - 인증 상태 관리 (AuthNotifier, AuthState)

  **라우팅 (go_router)**
  - lib/core/router/app_router.dart - 인증 상태 기반 라우팅 (/, /login, /register, /home)

  **화면 UI**
  - lib/presentation/screens/splash/splash_screen.dart - 스플래시 화면 (자동 로그인 체크)
  - lib/presentation/screens/auth/login_screen.dart - 로그인 화면
  - lib/presentation/screens/auth/register_screen.dart - 회원가입 화면
  - lib/presentation/screens/home/home_screen.dart - 홈 화면 (검색 방식 선택)

  ### 연동된 API 엔드포인트:
  - POST /app/api/auth/register - 회원가입
  - POST /app/api/auth/login - 로그인
  - POST /app/api/auth/refresh - 토큰 갱신
  - GET /app/api/auth/me - 내 정보 조회
  - POST /app/api/auth/logout - 로그아웃

  ### 패키지 변경사항:
  - Retrofit 제거 → Dio 직접 사용 (패키지 호환성 문제)
  - Isar 제거 → Hive 사용 예정 (Phase 5에서 구현)

  ### 테스트 결과:
  - flutter analyze: No issues found
  - flutter test: All tests passed
  - flutter build web: 빌드 성공
  - flutter run -d chrome: 실행 성공

  ---

  ## Phase 3: 건축물 검색 기능 ✅ 완료 (2026-02-10)

  ### 구현된 파일 목록:

  **DTO (Freezed)**
  - lib/data/dto/building_dto.dart - 건축물/토지 관련 모든 DTO
    - RoadSearchRequest, RoadSearchResponse, RoadSearchResultItem
    - JibunSearchRequest, BuildingSearchResponse
    - BdMgtSnSearchRequest
    - CodeInfo, AddressInfo, BuildingInfo, BuildingBasicInfo, FloorInfo
    - LandInfo, BjdongSearchItem, BjdongSearchResponse
    - AreaInfoRequest, AreaInfo, AreaInfoResponse
    - _intFromDynamic, _stringFromDynamic 컨버터 함수 (혼합 타입 처리)

  **API & Repository**
  - lib/data/datasources/remote/building_api.dart - 건축물 검색 API 호출
  - lib/data/repositories/building_repository.dart - 건축물 검색 비즈니스 로직

  **Provider (Riverpod)**
  - lib/presentation/providers/building_provider.dart
    - RoadSearchNotifier, RoadSearchState - 도로명 검색 상태 관리
    - BuildingSearchNotifier, BuildingSearchState - 지번/건물관리번호 검색 상태 관리
    - AreaInfoNotifier, AreaInfoState - 공동주택 동/호 상세 정보 상태 관리
    - bjdongSearchProvider - 법정동 자동완성

  **화면 UI**
  - lib/presentation/screens/search/search_road_screen.dart - 도로명 검색 화면
  - lib/presentation/screens/search/search_jibun_screen.dart - 지번 검색 화면
    - Overlay 기반 법정동 자동완성 드롭다운 (CompositedTransformTarget/Follower)
    - 토지구분 선택 (대지/임야)
  - lib/presentation/screens/search/result_screen.dart - 검색 결과 상세 표시
    - 주소 정보 (도로명/지번)
    - 토지 정보 (면적, 지목, 공시지가, 용도지역 등)
    - 건축물 정보 (용도, 구조, 층수, 면적, 건폐율/용적률 등)
    - 층별 정보 테이블
    - 공동주택 동/호 선택 드롭다운 및 상세 정보 조회

  **토큰 저장 (플랫폼별 분기)**
  - lib/core/storage/token_storage.dart
    - Web: SharedPreferences 사용 (FlutterSecureStorage 미지원)
    - Mobile: FlutterSecureStorage 사용 (암호화)

  **라우팅 업데이트**
  - lib/core/router/app_router.dart - /search/road, /search/jibun, /result 라우트 추가
  - lib/presentation/screens/home/home_screen.dart - 검색 버튼 연결

  ### 연동된 API 엔드포인트:
  - POST /app/api/search/road - 도로명 검색
  - POST /app/api/search/jibun - 지번 검색
  - POST /app/api/search/bdmgtsn - 건물관리번호 검색
  - GET /app/api/bjdong/search?query=... - 법정동 자동완성
  - POST /app/api/area - 공동주택 동/호별 상세 정보

  ### 해결된 이슈:
  1. **로그인 JSON 파싱 오류**: 서버 응답 snake_case와 DTO camelCase 불일치 → @JsonKey 어노테이션 추가
  2. **Web FlutterSecureStorage 오류**: OperationError 발생 → SharedPreferences로 대체 (Web만)
  3. **법정동 드롭다운 클릭 안됨**: GestureDetector가 이벤트 가로챔 → Overlay 방식으로 변경
  4. **공동주택 조회 실패**: total_parking 등 필드가 int 또는 String("-") 혼합 → fromJson 컨버터 추가
  5. **서버 bjdong/search 500 에러**: systemd 서비스 Python venv 경로 문제 → 서버에서 수정

  ### 테스트 결과:
  - flutter build web: 빌드 성공
  - flutter analyze: 경고만 있음 (에러 없음)
  - 단독주택/공동주택 검색 테스트 성공

  ---

  ## Phase 4: 지도 검색 기능 ✅ 완료 (2026-02-11)

  구현 완료:
  - ✅ 카카오맵 SDK 설정 (Android/iOS)
  - ✅ SearchMapScreen 구현
  - ✅ 좌표 클릭 → 지번 변환
  - ✅ 필지 경계 표시 (Polygon)
  - ✅ 마커 업데이트 버그 수정
  - ✅ GitHub 저장소 연동
  - ✅ API 키 환경변수 관리

  연동된 API:
  - POST /app/api/map/click-jibun - 좌표 → 지번 변환
  - GET /app/api/map/parcel-boundary?pnu=... - 필지 경계

  ---

  ## 다음 단계: Phase 5 (검색 기록 및 즐겨찾기)

  구현 예정:
  - Hive 데이터베이스 초기화 (Isar 대체)
  - SearchHistory, Favorite 스키마 정의
  - DatabaseService 구현
  - HistoryScreen (검색 기록 목록)
  - FavoritesScreen (즐겨찾기 목록)
  - 서버 동기화 (선택적)

  연동할 API:
  - GET /app/api/user/search-history
  - POST /app/api/user/favorites
  - DELETE /app/api/user/favorites/{id}

  ---

  ## 알려진 제한사항 (2026-02-10)

  1. **Hot Reload 제한**: Windows 환경에서 Dart code 수정 시 Hot Reload 불가, 앱 재시작 필요
  2. **analyzer 경고**: json_annotation, analyzer 버전 경고 (기능에는 영향 없음)
  3. **WASM 빌드 불가**: flutter_secure_storage_web, geolocator_web이 dart:html 사용 → JS 빌드만 지원

---

## 업데이트 이력

### 2026-02-11: Phase 4 지도 검색 기능 완료 및 보안 설정

#### 1. 지도 검색 기능 (Phase 4) 완료

**구현된 파일**:
- `lib/data/dto/map_dto.dart` - 지도 관련 DTO (MapClickJibunRequest, JibunInfo 등)
- `lib/data/datasources/remote/map_api.dart` - 지도 API 호출
- `lib/data/repositories/map_repository.dart` - 지도 비즈니스 로직
- `lib/presentation/providers/map_provider.dart` - 지도 상태 관리
- `lib/presentation/screens/search/search_map_screen.dart` - 지도 검색 화면

**연동된 API**:
- POST /app/api/map/click-jibun - 좌표 → 지번 변환
- GET /app/api/map/parcel-boundary - 필지 경계 조회

**주요 기능**:
- 카카오맵 표시 (kakao_map_plugin)
- 지도 탭 → 마커 표시 → 지번 정보 조회
- 필지 경계 폴리곤 표시
- 현재 위치 버튼 (Geolocator)
- "조회하기" 버튼 → 건물 검색 → 결과 화면 이동

#### 2. 마커 업데이트 버그 수정

**문제**: 지도에서 위치 클릭 후 다른 위치 클릭 시 마커가 업데이트되지 않음

**해결**: KakaoMap 위젯의 `markers` 파라미터 대신 컨트롤러 메서드 사용
```dart
// 변경 전: _markers 상태 변수 사용
// 변경 후: 컨트롤러 직접 호출
await _mapController!.clearMarker();
await _mapController!.addMarker(markers: [Marker(...)]);
```

#### 3. GitHub 저장소 설정

**저장소**: https://github.com/cs21jeon/Proppedia
- SSH 인증 설정 (ed25519 키)
- 초기 커밋 및 푸시 완료

#### 4. 보안 설정 - API 키 환경변수 관리

**문제**: 카카오 API 키가 코드에 하드코딩되어 공개 저장소에 노출

**해결**: 환경변수 파일로 분리

**생성된 파일**:
- `.env` - 실제 API 키 (git 제외)
- `.env.example` - 템플릿 (git 포함)
- `android/local.properties` - Android API 키 (git 제외)
- `android/local.properties.example` - 템플릿
- `ios/Flutter/Secrets.xcconfig` - iOS API 키 (git 제외)
- `ios/Flutter/Secrets.xcconfig.example` - 템플릿

**수정된 파일**:
- `pubspec.yaml` - flutter_dotenv 패키지 추가
- `lib/main.dart` - dotenv.load() 및 환경변수에서 키 로드
- `android/app/build.gradle.kts` - local.properties에서 키 읽어 manifestPlaceholders 전달
- `android/app/src/main/AndroidManifest.xml` - ${KAKAO_NATIVE_APP_KEY} 플레이스홀더
- `ios/Flutter/Debug.xcconfig` - Secrets.xcconfig include
- `ios/Flutter/Release.xcconfig` - Secrets.xcconfig include
- `ios/Runner/Info.plist` - $(KAKAO_NATIVE_APP_KEY) 변수
- `.gitignore` - .env, Secrets.xcconfig 등 제외

**환경변수 구조**:
```
.env (Flutter 런타임)
├── KAKAO_NATIVE_APP_KEY=xxx
└── KAKAO_JAVASCRIPT_KEY=xxx

android/local.properties (Android 빌드)
└── KAKAO_NATIVE_APP_KEY=xxx

ios/Flutter/Secrets.xcconfig (iOS 빌드)
└── KAKAO_NATIVE_APP_KEY=xxx
```

---

### 2026-02-11: 주택공시가격 표시 및 층별개요 복원

#### 1. 주택공시가격(VWorld API) 연동 완료

**수정된 백엔드 파일**:
- `/home/webapp/goldenrabbit/backend/property-manager/routes/app_api.py`
  - `search_by_jibun()`: 단독주택 공시가격 조회 로직 추가
  - `search_by_bdmgtsn()`: 단독주택 공시가격 조회 로직 추가

**연동 API**: VWorld `getIndvdHousingPriceAttr`
- 반환 필드: `house_price`, `house_price_year`, `house_price_month`
- 대상: 일반건축물 또는 건물없는 토지

#### 2. 웹앱 주택공시가격 표시 수정

**수정된 파일**: `/home/webapp/goldenrabbit/backend/property-manager/static/app.js`
- `displayGeneralBuilding()`: 건물정보 섹션 내에 주택공시가격 표시
- 포맷 변경: `xxxx원 (2025년)` → `xxxx원(2025년)` (공백 제거)

#### 3. 플러터앱 층별개요 복원

**수정된 파일**: `lib/presentation/screens/search/result_screen.dart`
- `_buildFloorInfoCard()` 함수 추가: 층별개요 테이블 표시
- 컬럼: 층 | 구조 | 용도 | 면적
- 정렬: 지상층(높은층→낮은층) → 지하층
- 조건: 일반건축물(`type == 'general'`) && `floorInfo` 존재 시에만 표시

#### 적용 방법

```bash
# 웹앱: property-manager 재시작
sudo systemctl restart property-manager

# 플러터앱: 앱 재빌드
flutter run -d windows
```

---

### 2026-02-11: 웹앱/Flutter 앱 조회결과 비교 검토 및 표시 일관성 수정

#### 1. 8개 테스트 케이스 정의

웹앱과 Flutter 앱의 조회화면/PDF 출력 일관성 검증을 위한 테스트 케이스:

| # | 주소 | 케이스 유형 | 검증 포인트 |
|---|------|-----------|------------|
| 1 | 사당동 산 32-77 | 토지만 (임야) | 건물 없을 때 토지정보 상세표시, 산 표시 |
| 2 | 사당동 318-107 | 토지만 (대지) | 건물 없을 때 처리 |
| 3 | 사당동 1044-23 | 일반건축물 | 주용도, 층별정보 표시 |
| 4 | 사당동 314-12 동없음 201호 | 공동주택 | 세대/가구/호, 공시가격 년도 |
| 5 | 사당동 280-1 101동 201호 | 다필지 공동주택 | 필지수 표시 (9필지) |
| 6 | 사당동 1154 101동 201호 | 대규모 아파트 | 해당동 정보, 전유부 정보 |
| 7 | 사당동 147-29 이수자이동 101-1402호 | 복잡한 동/호명 | 특수 동명/호명 처리 |
| 8 | 사당동 86-6 동없음 101호 | 비주거 건물 | 주택 아닌 multi_unit 처리 |

#### 2. 웹앱 버그 수정 (SSH로 result.html 수정)

**서버 파일**: `/home/webapp/goldenrabbit/frontend/public/app/result.html`

| 이슈 | 원인 | 수정 내용 |
|------|------|----------|
| `fmly` 변수 미정의 | 변수명 오타 | `fmly` → `family` |
| 세대/가구/호 기본값 | 잘못된 기본값 | `-/-/-` → `0/0/0` |
| 필지수 표시 형식 | 형식 불일치 | `(합계)` → `[n필지]` |
| 대지면적 필지수 누락 | 건물정보에 필지수 미표시 | 필지수 추가 |

**수정된 코드 위치**:
- Line 521: 토지정보 섹션 필지수 형식
- Line 609: 일반건축물 대지면적 필지수 추가
- Line 733: 공동주택 대지면적 필지수 추가

#### 3. Flutter 앱 수정

**수정된 파일**: `lib/presentation/screens/search/result_screen.dart`

| 항목 | 수정 전 | 수정 후 |
|------|--------|--------|
| `_formatTotalUnits()` | 0을 '-'로 표시 | 0을 그대로 표시 |
| 세대/가구/호 라벨 | "총 세대/가구/호" | "세대/가구/호" |
| 대지면적 | 필지수 미표시 | `[n필지]` 표시 (2필지 이상) |
| 층수 표시 | 일반건축물만 표시 | 모든 건물 타입에서 표시 |
| 높이 | 미표시 | 높이 표시 추가 |
| 승강기수 | 미표시 | 승강기수 표시 추가 |

**함수 시그니처 변경**:
```dart
// 변경 전
Widget _buildBuildingInfoCard(BuildContext context, BuildingInfo building)

// 변경 후 (필지수 조회를 위해 LandInfo 추가)
Widget _buildBuildingInfoCard(BuildContext context, BuildingInfo building, LandInfo? land)
```

#### 4. 테스트 케이스 검토 가이드 문서 생성

**생성된 파일**: `docs/test-case-review-guide.md`

문서 내용:
- 8개 테스트 케이스 목록
- API 데이터 조회 방법 (curl 예시)
- 검토 대상 파일 위치 (웹앱/Flutter)
- 검증 항목 체크리스트 (기본정보, 토지정보, 건물정보, 전유부정보)
- 테스트 실행 절차
- 주요 코드 위치
- 발견된 이슈 및 수정 이력

#### 5. 검증 결과

**웹앱/Flutter 앱 표시 일관성**:
- ✅ 지번주소 (시도 포함)
- ✅ 도로명주소 (시도 포함)
- ✅ 세대/가구/호 라벨 및 값 (0 표시)
- ✅ 대지면적 + 평 + 필지수
- ✅ 연면적/건축면적 + 평
- ✅ 층수 (모든 건물 타입)
- ✅ 높이
- ✅ 승강기수
- ✅ 공시지가/공동주택가격 + 년도

**MCP 연결 활용**:
- `.mcp.json` 설정으로 SSH 서버 접속
- 서버: `root@175.119.224.71`
- 웹앱 파일 직접 편집 가능

---

### 2026-02-12: UI 브랜딩 및 Footer 적용

#### 1. 로그인 화면 브랜딩 수정

**수정된 파일**: `lib/presentation/screens/auth/login_screen.dart`

**변경 내용**:
- 로고 이미지 적용: `proppedia_logo.png` (투명 배경)
- 텍스트 배치: 로고 → "Proppedia" → "부동산백과" → "세상 편한 부동산 조회" (세로 배치)
- 로고 크기: 140px

#### 2. 홈 화면 헤더 브랜딩 수정

**수정된 파일**: `lib/presentation/screens/home/home_screen.dart`

**변경 내용**:
- AppBar에 로고+텍스트 가로 배치 (goldenrabbit.biz/app 스타일)
- 구조: `[로고 이미지] + [Proppedia / 부동산백과]` (Row + Column)
- 로고 크기: 56px
- AppBar toolbarHeight: 72px

#### 3. Footer 위젯 구현

**생성된 파일**: `lib/presentation/widgets/common/app_footer.dart`

**위젯 종류**:
- `AppFooterSimple` - 홈/검색 화면용 (로고만)
- `AppFooterWithDisclaimer` - 결과 화면용 (안내문구 + 로고)

**Footer 구성**:
```
[Proppedia 아이콘] Proppedia 제공 | [금토끼 아이콘] 금토끼부동산 제작
```

**WithDisclaimer 추가 내용**:
```
본 자료는 공공데이터포털 및 VWorld를 기반으로 생성되었습니다.
오류가 있을 수 있으니 정확한 정보는 공적장부를 참고하세요.
```

#### 4. Footer 적용 화면

| 화면 | 파일 | Footer 타입 |
|------|------|-------------|
| 홈 화면 | `home_screen.dart` | AppFooterSimple |
| 도로명 검색 | `search_road_screen.dart` | AppFooterSimple |
| 지번 검색 | `search_jibun_screen.dart` | AppFooterSimple |
| 지도 검색 | `search_map_screen.dart` | AppFooterSimple |
| 결과 화면 | `result_screen.dart` | AppFooterWithDisclaimer |

#### 5. 로고 이미지 파일

**다운로드된 파일** (`assets/images/`):
- `proppedia_logo.png` - 메인 로고 (투명 배경, 로그인/홈 헤더용)
- `proppedia_logo_landscape.png` - 가로형 로고 (미사용)
- `proppedia_icon.png` - 아이콘 (Footer용)
- `goldenrabbit_icon.png` - 금토끼부동산 아이콘 (Footer용)

**이미지 소스**:
- 서버 경로: `/home/webapp/goldenrabbit/backend/assets/proppedia/`
- 투명 배경 버전: `logo_proppedia_transparent_logo only.png`

#### 6. 기타 수정사항

- "PropPedia" → "Proppedia" 텍스트 통일
- SafeArea 적용으로 Footer가 시스템 UI에 가려지지 않도록 처리
- errorBuilder 추가로 이미지 로드 실패 시 대체 아이콘 표시

---

### 2026-02-12: UI/UX 개선 및 PDF 기능 고도화

#### 1. 푸터 이중 표시 문제 해결

**수정된 파일**: `result_screen.dart`

**문제**: 결과 화면에서 푸터가 이중으로 표시됨
- 본문 내 `_buildDisclaimerSection()` + `bottomNavigationBar`에 `AppFooterWithDisclaimer`

**해결**: `bottomNavigationBar` 제거, 본문 내 안내문구 섹션만 유지

#### 2. 로그인/회원가입 버튼 높이 조정

**수정된 파일**: `login_screen.dart`, `register_screen.dart`

**문제**: 안드로이드에서 '로그인' 버튼의 '인'자 하단이 잘림

**해결**: 버튼 높이 50px → 54px (한글 폰트 descender 여유 확보)

#### 3. 푸터 영역 개선

**수정된 파일**: `app_footer.dart`, `result_screen.dart`, `pdf_generator.dart`

**변경 내용**:
- SafeArea 적용 (홈바 위로 표시)
- Flexible/Wrap 적용 (overflow 방지)
- 이미지 errorBuilder 추가
- 구분자: `,` → `|` (간격 6px)
- 로고 크기: 14px → 13px (10% 축소)
- 금토끼 로고 모서리 라운드 처리 (ClipRRect)
- 문구 통일: "Proppedia 제공 | 금토끼부동산 제작"
- 주소: "goldenrabbit.biz" → "https://goldenrabbit.biz"

#### 4. 지번검색 입력예시 수정

**수정된 파일**: `search_jibun_screen.dart`

**변경**: "서울시 서초구 사당동 314-21" → "서울시 동작구 사당동 123-45"

#### 5. 조회 결과 화면 안내문구 줄바꿈

**수정된 파일**: `result_screen.dart`

**변경**:
```
본 자료는 공공데이터포털 및
VWorld를 기반으로 생성되었습니다.

오류가 있을 수 있으니
정확한 정보는 공적장부를 참고하세요.
```

#### 6. 홈 화면 헤더 크기 조정

**수정된 파일**: `home_screen.dart`

**변경 내용**:
- AppBar toolbarHeight: 기본 → 72px
- 로고 높이: 46px → 56px
- 제목 폰트: 18px → 20px
- 부제목 폰트: 12px → 13px

#### 7. 홈 화면 overflow 문제 해결

**수정된 파일**: `home_screen.dart`

**문제**: 로그인 후 홈 화면에서 "bottom overflowed by 14 pixels" 오류

**해결**: `Padding` → `SingleChildScrollView`로 변경

#### 8. PDF 파일명 고도화

**수정된 파일**: `pdf_provider.dart`

**파일명 형식**:
- 일반건축물: `Proppedia_사당동123-45_20260212_221625.pdf`
- 공동주택: `Proppedia_사당동272-26_101동_302호_20260212_221625.pdf`
- 동/호 없는 경우: `Proppedia_사당동272-26_동없음_302호_20260212_221625.pdf`

**추출 로직**:
1. PNU 코드에서 번지 추출
2. recapTitleInfo에서 번지 추출
3. platPlc에서 정규식으로 동/번지 추출
4. areaInfo에서 동/호 정보 추출 (공동주택)

#### 9. PDF 미리보기 파일명 통일

**수정된 파일**: `result_screen.dart`

**문제**: 미리보기 후 저장 시 "부동산정보.pdf"로 저장됨

**해결**:
- 하드코딩된 `name: '부동산정보.pdf'` 제거
- `notifier.previewPdf()` 호출로 동적 파일명 사용

#### 10. PDF 푸터 간격 조정

**수정된 파일**: `pdf_generator.dart`

**변경**: "금토끼부동산 제작"과 "https://goldenrabbit.biz" 사이 공백 3칸 추가

#### 11. PDF 저장 완료 SnackBar 개선

**수정된 파일**: `result_screen.dart`

**변경**:
- "확인" 버튼 제거
- `duration: 3초` 추가 (자동 닫힘)

#### 12. 스플래시 스크린 이미지 설정

**수정된 파일**:
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`

**추가된 파일**:
- `android/app/src/main/res/drawable/launch_image.png`

**이미지 소스**: 서버 `/home/webapp/goldenrabbit/backend/assets/proppedia/logo_proppedia_portrait_transparent_logo only.png`

---

### 수정 파일 요약 (2026-02-12)

| 파일 | 주요 변경 |
|------|----------|
| `login_screen.dart` | 버튼 높이 54px |
| `register_screen.dart` | 버튼 높이 54px |
| `home_screen.dart` | 헤더 크기 확대, SingleChildScrollView |
| `result_screen.dart` | 푸터 이중 제거, 안내문구 줄바꿈, SnackBar 3초 |
| `app_footer.dart` | SafeArea, 구분자 |, 로고 라운드 |
| `search_jibun_screen.dart` | 입력예시 수정 |
| `pdf_generator.dart` | 푸터 문구/간격/로고 |
| `pdf_provider.dart` | 파일명 형식 (지번+동호+타임스탬프) |
| `launch_background.xml` | 스플래시 이미지 활성화 |