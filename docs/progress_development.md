업데이트 현황 (2026-02-10)

&nbsp; ## Phase 1:  ✅ 완료

&nbsp; - ✅ Flutter 프로젝트 생성

&nbsp; - ✅ pubspec.yaml 패키지 설정

&nbsp; - ✅ Clean Architecture 폴더 구조 생성

&nbsp; - ✅ 테마 설정 (app\_colors.dart, app\_text\_styles.dart, app\_theme.dart)

&nbsp; - ✅ app.dart, main.dart 구현

&nbsp; - ✅ 앱 실행 테스트 성공 (Chrome)

&nbsp; - ✅ Flutter Web 빌드 성공



&nbsp; ## Phase 2: 인증 시스템 ✅ 완료



&nbsp; ### 구현된 파일 목록:



&nbsp; \*\*모델/DTO (Freezed)\*\*

&nbsp; - lib/domain/entities/user.dart - User 엔티티

&nbsp; - lib/data/dto/auth\_dto.dart - LoginRequest, RegisterRequest, AuthResponse 등



&nbsp; \*\*네트워크 (Dio)\*\*

&nbsp; - lib/core/network/api\_client.dart - Dio HTTP 클라이언트 (baseUrl: https://goldenrabbit.biz)

&nbsp; - lib/core/network/auth\_interceptor.dart - JWT 토큰 자동 추가/갱신 인터셉터

&nbsp; - lib/data/datasources/remote/auth\_api.dart - 인증 API 호출 클래스



&nbsp; \*\*토큰 저장 (SecureStorage)\*\*

&nbsp; - lib/core/storage/token\_storage.dart - 암호화된 토큰 저장/관리



&nbsp; \*\*Repository \& Provider (Riverpod)\*\*

&nbsp; - lib/data/repositories/auth\_repository.dart - 인증 비즈니스 로직

&nbsp; - lib/presentation/providers/auth\_provider.dart - 인증 상태 관리 (AuthNotifier, AuthState)



&nbsp; \*\*라우팅 (go\_router)\*\*

&nbsp; - lib/core/router/app\_router.dart - 인증 상태 기반 라우팅 (/, /login, /register, /home)



&nbsp; \*\*화면 UI\*\*

&nbsp; - lib/presentation/screens/splash/splash\_screen.dart - 스플래시 화면 (자동 로그인 체크)

&nbsp; - lib/presentation/screens/auth/login\_screen.dart - 로그인 화면

&nbsp; - lib/presentation/screens/auth/register\_screen.dart - 회원가입 화면

&nbsp; - lib/presentation/screens/home/home\_screen.dart - 홈 화면 (검색 방식 선택)



&nbsp; ### 연동된 API 엔드포인트:

&nbsp; - POST /app/api/auth/register - 회원가입

&nbsp; - POST /app/api/auth/login - 로그인

&nbsp; - POST /app/api/auth/refresh - 토큰 갱신

&nbsp; - GET /app/api/auth/me - 내 정보 조회

&nbsp; - POST /app/api/auth/logout - 로그아웃



&nbsp; ### 패키지 변경사항:

&nbsp; - Retrofit 제거 → Dio 직접 사용 (패키지 호환성 문제)

&nbsp; - Isar 제거 → Hive 사용 예정 (Phase 5에서 구현)



&nbsp; ### 테스트 결과:

&nbsp; - flutter analyze: No issues found

&nbsp; - flutter test: All tests passed

&nbsp; - flutter build web: 빌드 성공

&nbsp; - flutter run -d chrome: 실행 성공



&nbsp; ---



&nbsp; ## Phase 3: 건축물 검색 기능 ✅ 완료 (2026-02-10)



&nbsp; ### 구현된 파일 목록:



&nbsp; \*\*DTO (Freezed)\*\*

&nbsp; - lib/data/dto/building\_dto.dart - 건축물/토지 관련 모든 DTO

&nbsp;   - RoadSearchRequest, RoadSearchResponse, RoadSearchResultItem

&nbsp;   - JibunSearchRequest, BuildingSearchResponse

&nbsp;   - BdMgtSnSearchRequest

&nbsp;   - CodeInfo, AddressInfo, BuildingInfo, BuildingBasicInfo, FloorInfo

&nbsp;   - LandInfo, BjdongSearchItem, BjdongSearchResponse

&nbsp;   - AreaInfoRequest, AreaInfo, AreaInfoResponse

&nbsp;   - \_intFromDynamic, \_stringFromDynamic 컨버터 함수 (혼합 타입 처리)



&nbsp; \*\*API \& Repository\*\*

&nbsp; - lib/data/datasources/remote/building\_api.dart - 건축물 검색 API 호출

&nbsp; - lib/data/repositories/building\_repository.dart - 건축물 검색 비즈니스 로직



&nbsp; \*\*Provider (Riverpod)\*\*

&nbsp; - lib/presentation/providers/building\_provider.dart

&nbsp;   - RoadSearchNotifier, RoadSearchState - 도로명 검색 상태 관리

&nbsp;   - BuildingSearchNotifier, BuildingSearchState - 지번/건물관리번호 검색 상태 관리

&nbsp;   - AreaInfoNotifier, AreaInfoState - 공동주택 동/호 상세 정보 상태 관리

&nbsp;   - bjdongSearchProvider - 법정동 자동완성



&nbsp; \*\*화면 UI\*\*

&nbsp; - lib/presentation/screens/search/search\_road\_screen.dart - 도로명 검색 화면

&nbsp; - lib/presentation/screens/search/search\_jibun\_screen.dart - 지번 검색 화면

&nbsp;   - Overlay 기반 법정동 자동완성 드롭다운 (CompositedTransformTarget/Follower)

&nbsp;   - 토지구분 선택 (대지/임야)

&nbsp; - lib/presentation/screens/search/result\_screen.dart - 검색 결과 상세 표시

&nbsp;   - 주소 정보 (도로명/지번)

&nbsp;   - 토지 정보 (면적, 지목, 공시지가, 용도지역 등)

&nbsp;   - 건축물 정보 (용도, 구조, 층수, 면적, 건폐율/용적률 등)

&nbsp;   - 층별 정보 테이블

&nbsp;   - 공동주택 동/호 선택 드롭다운 및 상세 정보 조회



&nbsp; \*\*토큰 저장 (플랫폼별 분기)\*\*

&nbsp; - lib/core/storage/token\_storage.dart

&nbsp;   - Web: SharedPreferences 사용 (FlutterSecureStorage 미지원)

&nbsp;   - Mobile: FlutterSecureStorage 사용 (암호화)



&nbsp; \*\*라우팅 업데이트\*\*

&nbsp; - lib/core/router/app\_router.dart - /search/road, /search/jibun, /result 라우트 추가

&nbsp; - lib/presentation/screens/home/home\_screen.dart - 검색 버튼 연결



&nbsp; ### 연동된 API 엔드포인트:

&nbsp; - POST /app/api/search/road - 도로명 검색

&nbsp; - POST /app/api/search/jibun - 지번 검색

&nbsp; - POST /app/api/search/bdmgtsn - 건물관리번호 검색

&nbsp; - GET /app/api/bjdong/search?query=... - 법정동 자동완성

&nbsp; - POST /app/api/area - 공동주택 동/호별 상세 정보



&nbsp; ### 해결된 이슈:

&nbsp; 1. \*\*로그인 JSON 파싱 오류\*\*: 서버 응답 snake\_case와 DTO camelCase 불일치 → @JsonKey 어노테이션 추가

&nbsp; 2. \*\*Web FlutterSecureStorage 오류\*\*: OperationError 발생 → SharedPreferences로 대체 (Web만)

&nbsp; 3. \*\*법정동 드롭다운 클릭 안됨\*\*: GestureDetector가 이벤트 가로챔 → Overlay 방식으로 변경

&nbsp; 4. \*\*공동주택 조회 실패\*\*: total\_parking 등 필드가 int 또는 String("-") 혼합 → fromJson 컨버터 추가

&nbsp; 5. \*\*서버 bjdong/search 500 에러\*\*: systemd 서비스 Python venv 경로 문제 → 서버에서 수정



&nbsp; ### 테스트 결과:

&nbsp; - flutter build web: 빌드 성공

&nbsp; - flutter analyze: 경고만 있음 (에러 없음)

&nbsp; - 단독주택/공동주택 검색 테스트 성공



&nbsp; ---



&nbsp; ## Phase 4: 지도 검색 기능 ✅ 완료 (2026-02-11)



&nbsp; 구현 완료:

&nbsp; - ✅ 카카오맵 SDK 설정 (Android/iOS)

&nbsp; - ✅ SearchMapScreen 구현

&nbsp; - ✅ 좌표 클릭 → 지번 변환

&nbsp; - ✅ 필지 경계 표시 (Polygon)

&nbsp; - ✅ 마커 업데이트 버그 수정

&nbsp; - ✅ GitHub 저장소 연동

&nbsp; - ✅ API 키 환경변수 관리



&nbsp; 연동된 API:

&nbsp; - POST /app/api/map/click-jibun - 좌표 → 지번 변환

&nbsp; - GET /app/api/map/parcel-boundary?pnu=... - 필지 경계



&nbsp; ---



&nbsp; ## Phase 5: 검색 기록 및 즐겨찾기 ✅ 완료 (2026-02-12)



&nbsp; ### 구현된 파일 목록:



&nbsp; **모델 (Hive)**

&nbsp; - `lib/data/models/search_history.dart` - 검색 기록 모델 (@HiveType)

&nbsp; - `lib/data/models/favorite.dart` - 즐겨찾기 모델 (@HiveType)

&nbsp; - `lib/data/models/search_history.g.dart` - Hive TypeAdapter (자동 생성)

&nbsp; - `lib/data/models/favorite.g.dart` - Hive TypeAdapter (자동 생성)



&nbsp; **데이터베이스 서비스**

&nbsp; - `lib/core/database/database_service.dart` - Hive 초기화 및 CRUD 작업



&nbsp; **API**

&nbsp; - `lib/data/datasources/remote/history_api.dart` - 검색 기록 API

&nbsp; - `lib/data/datasources/remote/favorites_api.dart` - 즐겨찾기 API



&nbsp; **Repository**

&nbsp; - `lib/data/repositories/history_repository.dart` - 검색 기록 비즈니스 로직

&nbsp; - `lib/data/repositories/favorites_repository.dart` - 즐겨찾기 비즈니스 로직



&nbsp; **Provider (Riverpod)**

&nbsp; - `lib/presentation/providers/history_provider.dart` - 검색 기록 상태 관리

&nbsp; - `lib/presentation/providers/favorites_provider.dart` - 즐겨찾기 상태 관리



&nbsp; **화면 UI**

&nbsp; - `lib/presentation/screens/history/history_screen.dart` - 검색 기록 목록

&nbsp; - `lib/presentation/screens/favorites/favorites_screen.dart` - 즐겨찾기 목록

&nbsp; - `lib/presentation/screens/search/result_screen.dart` - 검색 기록 저장 및 즐겨찾기 버튼 추가

&nbsp; - `lib/presentation/screens/search/search_map_screen.dart` - searchType: 'map' 전달



&nbsp; **라우터 업데이트**

&nbsp; - `lib/core/router/app_router.dart` - /history, /favorites 라우트 추가



&nbsp; **홈 화면 업데이트**

&nbsp; - `lib/presentation/screens/home/home_screen.dart` - 하단 네비게이션 바 추가



&nbsp; ### 연동된 API 엔드포인트:

&nbsp; - GET /app/api/user/history?limit=100 - 검색 기록 조회 (날짜별 그룹핑)

&nbsp; - DELETE /app/api/user/history/{id} - 검색 기록 삭제

&nbsp; - DELETE /app/api/user/history/all - 검색 기록 전체 삭제

&nbsp; - GET /app/api/user/favorites?limit=100 - 즐겨찾기 조회

&nbsp; - POST /app/api/user/favorites - 즐겨찾기 추가

&nbsp; - DELETE /app/api/user/favorites/{id} - 즐겨찾기 삭제

&nbsp; - PUT /app/api/user/favorites/{id} - 즐겨찾기 메모/별칭 수정



&nbsp; ### 주요 기능:

&nbsp; - 검색 완료 후 자동 검색 기록 저장 (result_screen.dart initState)

&nbsp; - 검색 결과 화면 AppBar에 즐겨찾기 버튼 (★ 토글)

&nbsp; - 검색 타입 표시 (도로명/지번/지도) - searchType 필드 추가

&nbsp; - 검색 기록 날짜별 그룹핑 표시

&nbsp; - 검색 기록 클릭 → 해당 부동산 결과 화면 이동

&nbsp; - 즐겨찾기 별칭/메모 편집

&nbsp; - 하단 네비게이션 바 (홈, 검색기록, 즐겨찾기)

&nbsp; - 로컬(Hive) + 서버 동기화 지원



&nbsp; ### 패키지 추가:

&nbsp; - `hive_generator: ^2.0.1` (dev_dependencies)



&nbsp; ### 테스트 결과:

&nbsp; - flutter analyze: 에러 없음 (경고만)

&nbsp; - flutter build web: 빌드 성공



&nbsp; ### 버그 수정 (2026-02-13):

&nbsp; **검색 기록 저장 타이밍 문제 수정**

&nbsp; - 문제: `_saveSearchHistory()`가 검색 완료 전(loading 상태)에 호출되어 기록이 저장되지 않음

&nbsp; - 해결: `ref.listenManual()`을 사용하여 검색 완료(success) 상태 감지 후 저장

&nbsp; - 수정 파일: `lib/presentation/screens/search/result_screen.dart`



&nbsp; **검색 기록/즐겨찾기 지번 주소 표시**

&nbsp; - `history_screen.dart` - 로컬 기록에서 jibunAddress 우선 표시, 도로명 주소 함께 표시

&nbsp; - `favorites_screen.dart` - 로컬 즐겨찾기로 변경, jibunAddress 우선 표시



&nbsp; **하단 네비게이션 바 호버/터치 효과 추가**

&nbsp; - `home_screen.dart`, `history_screen.dart`, `favorites_screen.dart`

&nbsp; - GestureDetector → Material + InkWell 변경

&nbsp; - hoverColor, splashColor 추가



&nbsp; **데이터 영구 저장 확인**

&nbsp; - Hive 로컬 저장소: 앱 종료 후에도 데이터 유지

&nbsp; - Android: 앱 데이터 폴더에 영구 저장

&nbsp; - Web: IndexedDB에 영구 저장 (시크릿 모드 제외)



&nbsp; ---



&nbsp; ## Phase 6: 프로필 및 설정 ✅ 완료 (2026-02-13)



&nbsp; ### 구현된 파일 목록:



&nbsp; **Provider**

&nbsp; - `lib/presentation/providers/theme_provider.dart` - 다크모드 상태 관리 (ThemeModeNotifier)

&nbsp; - `lib/presentation/providers/user_provider.dart` - 사용 통계 상태 관리 (UsageStatsNotifier)



&nbsp; **DTO**

&nbsp; - `lib/data/dto/user_stats_dto.dart` - UsageStatsResponse, UsageStats, SearchByType



&nbsp; **API & Repository**

&nbsp; - `lib/data/datasources/remote/user_api.dart` - 사용 통계 API 호출

&nbsp; - `lib/data/repositories/user_repository.dart` - 사용 통계 비즈니스 로직



&nbsp; **화면 UI**

&nbsp; - `lib/presentation/screens/profile/profile_screen.dart` - 프로필 화면

&nbsp;   - 사용자 정보 카드

&nbsp;   - 다크모드 토글 (Switch)

&nbsp;   - 사용 통계 표시 (총 검색, 즐겨찾기, 오늘/이번주 검색, 검색타입별 통계)

&nbsp;   - 로그아웃 버튼



&nbsp; **라우터 업데이트**

&nbsp; - `lib/core/router/app_router.dart` - /profile 라우트 추가



&nbsp; **하단 네비게이션 업데이트**

&nbsp; - `lib/presentation/screens/home/home_screen.dart` - 프로필 탭 추가

&nbsp; - `lib/presentation/screens/history/history_screen.dart` - 프로필 탭 추가

&nbsp; - `lib/presentation/screens/favorites/favorites_screen.dart` - 프로필 탭 추가



&nbsp; **앱 테마 연동**

&nbsp; - `lib/app.dart` - ThemeModeProvider 연동



&nbsp; ### 연동된 API 엔드포인트:

&nbsp; - GET /app/api/user/usage-stats - 사용 통계 조회



&nbsp; ### 주요 기능:

&nbsp; - 다크모드/라이트모드 전환 (SharedPreferences로 영구 저장)

&nbsp; - 사용 통계 표시 (총 검색, 즐겨찾기, 오늘/이번주/이번달 검색)

&nbsp; - 검색 타입별 통계 (도로명/지번/지도)

&nbsp; - 마지막 검색 일시, 가입일 표시

&nbsp; - 로그아웃 기능

&nbsp; - 하단 네비게이션 4탭 (홈, 검색기록, 즐겨찾기, 프로필)



&nbsp; ### 버그 수정 (2026-02-13):

&nbsp; **즐겨찾기 상태 표시 오류**
&nbsp; - 문제: 즐겨찾기 별이 항상 노란색으로 표시됨
&nbsp; - 해결: displayAddress 기반 → PNU 기반 비교로 변경
&nbsp; - 수정 파일: `result_screen.dart`

&nbsp; **사용 통계 로드 실패**
&nbsp; - 문제: 서버 API 미구현으로 통계 로드 불가
&nbsp; - 해결: 서버 API 대신 로컬 데이터(historyProvider, favoritesProvider) 기반 통계로 변경
&nbsp; - 수정 파일: `profile_screen.dart`

&nbsp; **다크모드 색상 문제**
&nbsp; - 지번 검색 법정동 드롭다운 글씨 안보임 → Theme.of(context).cardColor 적용
&nbsp; - 층별개요 테이블 글씨 검은색 → isDark 조건 분기
&nbsp; - 공동주택 동/호 선택 드롭다운 → dropdownColor, fillColor 테마 적용
&nbsp; - 토지구분 버튼 배경색 → isDark 조건 분기
&nbsp; - 수정 파일: `search_jibun_screen.dart`, `result_screen.dart`

&nbsp; **다크모드 네비게이션/푸터 배경 흰색**
&nbsp; - 문제: 하단 네비게이션 바와 푸터가 다크모드에서도 흰색 유지
&nbsp; - 해결: `Colors.white` → `Theme.of(context).scaffoldBackgroundColor` 변경
&nbsp; - 수정 파일: `app_footer.dart`, `home_screen.dart`, `history_screen.dart`, `favorites_screen.dart`

&nbsp; **로고 다크모드 투명 문제**
&nbsp; - 문제: 로고의 책 부분이 투명 처리되어 다크모드에서 안보임
&nbsp; - 해결: "fillbook 01" 버전 로고로 교체 (책 부분 흰색 채움, 사이즈 조정)
&nbsp; - 서버 소스: `/home/webapp/goldenrabbit/backend/assets/proppedia/logo_proppedia_*_fillbook_logo only 01.png`
&nbsp; - 교체된 파일: `assets/images/proppedia_logo.png` (179KB), `assets/images/proppedia_logo_landscape.png` (196KB)
&nbsp; - 영향받는 화면: 로그인, 홈 헤더, PDF

&nbsp; ---



&nbsp; ## Phase 7: 매물 정보 연동 🔄 진행 중 (2026-02-14 ~ 02-18)


### 구현 방향 변경

**기존 계획**: 외부 링크 방식 (딥링크 문제로 보류)

**변경된 방향**: 앱 내에 매물 기능 직접 구현
- goldenrabbit.biz 웹사이트와 동일한 구조로 Flutter 앱 내 구현
- 서버 API 연동 (매물 목록/상세/검색/지도)


### 구현된 파일 목록:

**DTO (Freezed)**
- `lib/data/dto/property_dto.dart` - 매물 관련 DTO
  - PropertyRecord, PropertyFields, PropertyCategory 등
  - `investment` 필드 추가 (실투자금)

**API & Repository**
- `lib/data/datasources/remote/property_api.dart` - 매물 API 호출
- `lib/data/repositories/property_repository.dart` - 매물 비즈니스 로직

**Provider (Riverpod)**
- `lib/presentation/providers/property_provider.dart`
  - PropertyListNotifier, PropertyDetailNotifier
  - selectedCategoryProvider, SearchStatus

**화면 UI**
- `lib/presentation/screens/property/property_list_screen.dart` - 매물 목록
  - 카테고리 탭 (전체/재건축/고수익/저가)
- `lib/presentation/screens/property/property_detail_screen.dart` - 매물 상세
  - 웹사이트와 동일한 구조로 완전 재작성
- `lib/presentation/screens/property/property_map_screen.dart` - 매물 지도
- `lib/presentation/screens/property/property_search_screen.dart` - 매물 검색

**위젯**
- `lib/presentation/widgets/property/property_card.dart` - 매물 카드
  - category 파라미터 추가 (카테고리별 표시 정보 변경)
- `lib/presentation/widgets/property/property_image.dart` - 매물 이미지 (3단 fallback)
- `lib/presentation/widgets/property/property_info_chips.dart` - 카테고리별 정보 칩 (신규)

**라우터**
- `lib/core/router/app_router.dart` - /property/* 라우트 추가


### 연동된 API 엔드포인트:

- `GET /api/property-list` - 전체 매물 목록
- `GET /api/category-properties?view=` - 카테고리별 매물
- `GET /api/property-detail?id=` - 매물 상세
- `GET /api/check-image?record_id=` - 이미지 확인
- `POST /api/search-map` - 조건 검색


### 카테고리별 표시 정보 (웹사이트와 동일):

| 카테고리 | 표시 정보 |
|---------|----------|
| 재건축용 토지 | 대지면적, 용도지역 |
| 고수익률 건물 | 대지면적, 수익률, 사용승인일 |
| 저가단독주택 | 대지면적, 층수, 사용승인일 |


### 매물 상세 화면 구조 (웹사이트와 동일):

1. 이미지
2. 지번/매매가
3. 정보 행 (융자제외실투자금, 수익률, 평단가)
4. 상세정보
5. 금토끼부동산 정보
6. 버튼들 (문의하기, 지도보기+링크복사)


### 주요 수정사항 (2026-02-18):

**1. 카테고리별 정보 칩 위젯 생성**
- `PropertyInfoChips` 위젯으로 재사용 가능한 칩 컴포넌트 분리
- property_card.dart, property_map_screen.dart에서 공통 사용

**2. 상세 화면 웹사이트 구조 반영**
- `_buildDetailContent()` 메서드로 전체 재작성
- `_cleanDescription()` 메서드로 상세정보 텍스트 정리
  - '* 상세정보 *' 마커 이후 내용 추출
  - '-----' 구분선 이전까지만 표시
  - '⚛ 금토끼부동산은' 이전까지만 추출

**3. 버튼 UI 수정**
- 버튼 높이 48px → 52px (글자 잘림 해결)
- padding: EdgeInsets.symmetric(vertical: 14) 추가

**4. 실투자금 필드 추가**
- property_dto.dart에 `investment` 필드 추가
- build_runner 재실행


### 테스트 결과:

- flutter analyze: 에러 없음
- flutter run -d SM-S928N: Android 기기 실행 성공
- 카테고리별 매물 목록 표시 확인
- 매물 상세 화면 표시 확인


### 남은 작업:

- [ ] 매물 지도 화면 마커 표시 고도화
- [ ] 즐겨찾기 기능 연동
- [ ] 홈 화면 매물 섹션 추가



&nbsp; ---



&nbsp; ## 알려진 제한사항 (2026-02-10)



&nbsp; 1. \*\*Hot Reload 제한\*\*: Windows 환경에서 Dart code 수정 시 Hot Reload 불가, 앱 재시작 필요

&nbsp; 2. \*\*analyzer 경고\*\*: json\_annotation, analyzer 버전 경고 (기능에는 영향 없음)

&nbsp; 3. \*\*WASM 빌드 불가\*\*: flutter\_secure\_storage\_web, geolocator\_web이 dart:html 사용 → JS 빌드만 지원



---



\## 업데이트 이력



\### 2026-02-11: Phase 4 지도 검색 기능 완료 및 보안 설정



\#### 1. 지도 검색 기능 (Phase 4) 완료



\*\*구현된 파일\*\*:

\- `lib/data/dto/map\_dto.dart` - 지도 관련 DTO (MapClickJibunRequest, JibunInfo 등)

\- `lib/data/datasources/remote/map\_api.dart` - 지도 API 호출

\- `lib/data/repositories/map\_repository.dart` - 지도 비즈니스 로직

\- `lib/presentation/providers/map\_provider.dart` - 지도 상태 관리

\- `lib/presentation/screens/search/search\_map\_screen.dart` - 지도 검색 화면



\*\*연동된 API\*\*:

\- POST /app/api/map/click-jibun - 좌표 → 지번 변환

\- GET /app/api/map/parcel-boundary - 필지 경계 조회



\*\*주요 기능\*\*:

\- 카카오맵 표시 (kakao\_map\_plugin)

\- 지도 탭 → 마커 표시 → 지번 정보 조회

\- 필지 경계 폴리곤 표시

\- 현재 위치 버튼 (Geolocator)

\- "조회하기" 버튼 → 건물 검색 → 결과 화면 이동



\#### 2. 마커 업데이트 버그 수정



\*\*문제\*\*: 지도에서 위치 클릭 후 다른 위치 클릭 시 마커가 업데이트되지 않음



\*\*해결\*\*: KakaoMap 위젯의 `markers` 파라미터 대신 컨트롤러 메서드 사용

```dart

// 변경 전: \_markers 상태 변수 사용

// 변경 후: 컨트롤러 직접 호출

await \_mapController!.clearMarker();

await \_mapController!.addMarker(markers: \[Marker(...)]);

```



\#### 3. GitHub 저장소 설정



\*\*저장소\*\*: https://github.com/cs21jeon/Proppedia

\- SSH 인증 설정 (ed25519 키)

\- 초기 커밋 및 푸시 완료



\#### 4. 보안 설정 - API 키 환경변수 관리



\*\*문제\*\*: 카카오 API 키가 코드에 하드코딩되어 공개 저장소에 노출



\*\*해결\*\*: 환경변수 파일로 분리



\*\*생성된 파일\*\*:

\- `.env` - 실제 API 키 (git 제외)

\- `.env.example` - 템플릿 (git 포함)

\- `android/local.properties` - Android API 키 (git 제외)

\- `android/local.properties.example` - 템플릿

\- `ios/Flutter/Secrets.xcconfig` - iOS API 키 (git 제외)

\- `ios/Flutter/Secrets.xcconfig.example` - 템플릿



\*\*수정된 파일\*\*:

\- `pubspec.yaml` - flutter\_dotenv 패키지 추가

\- `lib/main.dart` - dotenv.load() 및 환경변수에서 키 로드

\- `android/app/build.gradle.kts` - local.properties에서 키 읽어 manifestPlaceholders 전달

\- `android/app/src/main/AndroidManifest.xml` - ${KAKAO\_NATIVE\_APP\_KEY} 플레이스홀더

\- `ios/Flutter/Debug.xcconfig` - Secrets.xcconfig include

\- `ios/Flutter/Release.xcconfig` - Secrets.xcconfig include

\- `ios/Runner/Info.plist` - $(KAKAO\_NATIVE\_APP\_KEY) 변수

\- `.gitignore` - .env, Secrets.xcconfig 등 제외



\*\*환경변수 구조\*\*:

```

.env (Flutter 런타임)

├── KAKAO\_NATIVE\_APP\_KEY=xxx

└── KAKAO\_JAVASCRIPT\_KEY=xxx



android/local.properties (Android 빌드)

└── KAKAO\_NATIVE\_APP\_KEY=xxx



ios/Flutter/Secrets.xcconfig (iOS 빌드)

└── KAKAO\_NATIVE\_APP\_KEY=xxx

```



---



\### 2026-02-11: 주택공시가격 표시 및 층별개요 복원



\#### 1. 주택공시가격(VWorld API) 연동 완료



\*\*수정된 백엔드 파일\*\*:

\- `/home/webapp/goldenrabbit/backend/property-manager/routes/app\_api.py`

&nbsp; - `search\_by\_jibun()`: 단독주택 공시가격 조회 로직 추가

&nbsp; - `search\_by\_bdmgtsn()`: 단독주택 공시가격 조회 로직 추가



\*\*연동 API\*\*: VWorld `getIndvdHousingPriceAttr`

\- 반환 필드: `house\_price`, `house\_price\_year`, `house\_price\_month`

\- 대상: 일반건축물 또는 건물없는 토지



\#### 2. 웹앱 주택공시가격 표시 수정



\*\*수정된 파일\*\*: `/home/webapp/goldenrabbit/backend/property-manager/static/app.js`

\- `displayGeneralBuilding()`: 건물정보 섹션 내에 주택공시가격 표시

\- 포맷 변경: `xxxx원 (2025년)` → `xxxx원(2025년)` (공백 제거)



\#### 3. 플러터앱 층별개요 복원



\*\*수정된 파일\*\*: `lib/presentation/screens/search/result\_screen.dart`

\- `\_buildFloorInfoCard()` 함수 추가: 층별개요 테이블 표시

\- 컬럼: 층 | 구조 | 용도 | 면적

\- 정렬: 지상층(높은층→낮은층) → 지하층

\- 조건: 일반건축물(`type == 'general'`) \&\& `floorInfo` 존재 시에만 표시



\#### 적용 방법



```bash

\# 웹앱: property-manager 재시작

sudo systemctl restart property-manager



\# 플러터앱: 앱 재빌드

flutter run -d windows

```



---



\### 2026-02-11: 웹앱/Flutter 앱 조회결과 비교 검토 및 표시 일관성 수정



\#### 1. 8개 테스트 케이스 정의



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

| 8 | 사당동 86-6 동없음 101호 | 비주거 건물 | 주택 아닌 multi\_unit 처리 |



\#### 2. 웹앱 버그 수정 (SSH로 result.html 수정)



\*\*서버 파일\*\*: `/home/webapp/goldenrabbit/frontend/public/app/result.html`



| 이슈 | 원인 | 수정 내용 |

|------|------|----------|

| `fmly` 변수 미정의 | 변수명 오타 | `fmly` → `family` |

| 세대/가구/호 기본값 | 잘못된 기본값 | `-/-/-` → `0/0/0` |

| 필지수 표시 형식 | 형식 불일치 | `(합계)` → `\[n필지]` |

| 대지면적 필지수 누락 | 건물정보에 필지수 미표시 | 필지수 추가 |



\*\*수정된 코드 위치\*\*:

\- Line 521: 토지정보 섹션 필지수 형식

\- Line 609: 일반건축물 대지면적 필지수 추가

\- Line 733: 공동주택 대지면적 필지수 추가



\#### 3. Flutter 앱 수정



\*\*수정된 파일\*\*: `lib/presentation/screens/search/result\_screen.dart`



| 항목 | 수정 전 | 수정 후 |

|------|--------|--------|

| `\_formatTotalUnits()` | 0을 '-'로 표시 | 0을 그대로 표시 |

| 세대/가구/호 라벨 | "총 세대/가구/호" | "세대/가구/호" |

| 대지면적 | 필지수 미표시 | `\[n필지]` 표시 (2필지 이상) |

| 층수 표시 | 일반건축물만 표시 | 모든 건물 타입에서 표시 |

| 높이 | 미표시 | 높이 표시 추가 |

| 승강기수 | 미표시 | 승강기수 표시 추가 |



\*\*함수 시그니처 변경\*\*:

```dart

// 변경 전

Widget \_buildBuildingInfoCard(BuildContext context, BuildingInfo building)



// 변경 후 (필지수 조회를 위해 LandInfo 추가)

Widget \_buildBuildingInfoCard(BuildContext context, BuildingInfo building, LandInfo? land)

```



\#### 4. 테스트 케이스 검토 가이드 문서 생성



\*\*생성된 파일\*\*: `docs/test-case-review-guide.md`



문서 내용:

\- 8개 테스트 케이스 목록

\- API 데이터 조회 방법 (curl 예시)

\- 검토 대상 파일 위치 (웹앱/Flutter)

\- 검증 항목 체크리스트 (기본정보, 토지정보, 건물정보, 전유부정보)

\- 테스트 실행 절차

\- 주요 코드 위치

\- 발견된 이슈 및 수정 이력



\#### 5. 검증 결과



\*\*웹앱/Flutter 앱 표시 일관성\*\*:

\- ✅ 지번주소 (시도 포함)

\- ✅ 도로명주소 (시도 포함)

\- ✅ 세대/가구/호 라벨 및 값 (0 표시)

\- ✅ 대지면적 + 평 + 필지수

\- ✅ 연면적/건축면적 + 평

\- ✅ 층수 (모든 건물 타입)

\- ✅ 높이

\- ✅ 승강기수

\- ✅ 공시지가/공동주택가격 + 년도



\*\*MCP 연결 활용\*\*:

\- `.mcp.json` 설정으로 SSH 서버 접속

\- 서버: `root@175.119.224.71`

\- 웹앱 파일 직접 편집 가능



---



\### 2026-02-12: UI 브랜딩 및 Footer 적용



\#### 1. 로그인 화면 브랜딩 수정



\*\*수정된 파일\*\*: `lib/presentation/screens/auth/login\_screen.dart`



\*\*변경 내용\*\*:

\- 로고 이미지 적용: `proppedia\_logo.png` (투명 배경)

\- 텍스트 배치: 로고 → "Proppedia" → "부동산백과" → "세상 편한 부동산 조회" (세로 배치)

\- 로고 크기: 140px



\#### 2. 홈 화면 헤더 브랜딩 수정



\*\*수정된 파일\*\*: `lib/presentation/screens/home/home\_screen.dart`



\*\*변경 내용\*\*:

\- AppBar에 로고+텍스트 가로 배치 (goldenrabbit.biz/app 스타일)

\- 구조: `\[로고 이미지] + \[Proppedia / 부동산백과]` (Row + Column)

\- 로고 크기: 56px

\- AppBar toolbarHeight: 72px



\#### 3. Footer 위젯 구현



\*\*생성된 파일\*\*: `lib/presentation/widgets/common/app\_footer.dart`



\*\*위젯 종류\*\*:

\- `AppFooterSimple` - 홈/검색 화면용 (로고만)

\- `AppFooterWithDisclaimer` - 결과 화면용 (안내문구 + 로고)



\*\*Footer 구성\*\*:

```

\[Proppedia 아이콘] Proppedia 제공 | \[금토끼 아이콘] 금토끼부동산 제작

```



\*\*WithDisclaimer 추가 내용\*\*:

```

본 자료는 공공데이터포털 및 VWorld를 기반으로 생성되었습니다.

오류가 있을 수 있으니 정확한 정보는 공적장부를 참고하세요.

```



\#### 4. Footer 적용 화면



| 화면 | 파일 | Footer 타입 |

|------|------|-------------|

| 홈 화면 | `home\_screen.dart` | AppFooterSimple |

| 도로명 검색 | `search\_road\_screen.dart` | AppFooterSimple |

| 지번 검색 | `search\_jibun\_screen.dart` | AppFooterSimple |

| 지도 검색 | `search\_map\_screen.dart` | AppFooterSimple |

| 결과 화면 | `result\_screen.dart` | AppFooterWithDisclaimer |



\#### 5. 로고 이미지 파일



\*\*다운로드된 파일\*\* (`assets/images/`):

\- `proppedia\_logo.png` - 메인 로고 (투명 배경, 로그인/홈 헤더용)

\- `proppedia\_logo\_landscape.png` - 가로형 로고 (미사용)

\- `proppedia\_icon.png` - 아이콘 (Footer용)

\- `goldenrabbit\_icon.png` - 금토끼부동산 아이콘 (Footer용)



\*\*이미지 소스\*\*:

\- 서버 경로: `/home/webapp/goldenrabbit/backend/assets/proppedia/`

\- 투명 배경 버전: `logo\_proppedia\_transparent\_logo only.png`



\#### 6. 기타 수정사항



\- "PropPedia" → "Proppedia" 텍스트 통일

\- SafeArea 적용으로 Footer가 시스템 UI에 가려지지 않도록 처리

\- errorBuilder 추가로 이미지 로드 실패 시 대체 아이콘 표시



---



\### 2026-02-12: UI/UX 개선 및 PDF 기능 고도화



\#### 1. 푸터 이중 표시 문제 해결



\*\*수정된 파일\*\*: `result\_screen.dart`



\*\*문제\*\*: 결과 화면에서 푸터가 이중으로 표시됨

\- 본문 내 `\_buildDisclaimerSection()` + `bottomNavigationBar`에 `AppFooterWithDisclaimer`



\*\*해결\*\*: `bottomNavigationBar` 제거, 본문 내 안내문구 섹션만 유지



\#### 2. 로그인/회원가입 버튼 높이 조정



\*\*수정된 파일\*\*: `login\_screen.dart`, `register\_screen.dart`



\*\*문제\*\*: 안드로이드에서 '로그인' 버튼의 '인'자 하단이 잘림



\*\*해결\*\*: 버튼 높이 50px → 54px (한글 폰트 descender 여유 확보)



\#### 3. 푸터 영역 개선



\*\*수정된 파일\*\*: `app\_footer.dart`, `result\_screen.dart`, `pdf\_generator.dart`



\*\*변경 내용\*\*:

\- SafeArea 적용 (홈바 위로 표시)

\- Flexible/Wrap 적용 (overflow 방지)

\- 이미지 errorBuilder 추가

\- 구분자: `,` → `|` (간격 6px)

\- 로고 크기: 14px → 13px (10% 축소)

\- 금토끼 로고 모서리 라운드 처리 (ClipRRect)

\- 문구 통일: "Proppedia 제공 | 금토끼부동산 제작"

\- 주소: "goldenrabbit.biz" → "https://goldenrabbit.biz"



\#### 4. 지번검색 입력예시 수정



\*\*수정된 파일\*\*: `search\_jibun\_screen.dart`



\*\*변경\*\*: "서울시 서초구 사당동 314-21" → "서울시 동작구 사당동 123-45"



\#### 5. 조회 결과 화면 안내문구 줄바꿈



\*\*수정된 파일\*\*: `result\_screen.dart`



\*\*변경\*\*:

```

본 자료는 공공데이터포털 및

VWorld를 기반으로 생성되었습니다.



오류가 있을 수 있으니

정확한 정보는 공적장부를 참고하세요.

```



\#### 6. 홈 화면 헤더 크기 조정



\*\*수정된 파일\*\*: `home\_screen.dart`



\*\*변경 내용\*\*:

\- AppBar toolbarHeight: 기본 → 72px

\- 로고 높이: 46px → 56px

\- 제목 폰트: 18px → 20px

\- 부제목 폰트: 12px → 13px



\#### 7. 홈 화면 overflow 문제 해결



\*\*수정된 파일\*\*: `home\_screen.dart`



\*\*문제\*\*: 로그인 후 홈 화면에서 "bottom overflowed by 14 pixels" 오류



\*\*해결\*\*: `Padding` → `SingleChildScrollView`로 변경



\#### 8. PDF 파일명 고도화



\*\*수정된 파일\*\*: `pdf\_provider.dart`



\*\*파일명 형식\*\*:

\- 일반건축물: `Proppedia\_사당동123-45\_20260212\_221625.pdf`

\- 공동주택: `Proppedia\_사당동272-26\_101동\_302호\_20260212\_221625.pdf`

\- 동/호 없는 경우: `Proppedia\_사당동272-26\_동없음\_302호\_20260212\_221625.pdf`



\*\*추출 로직\*\*:

1\. PNU 코드에서 번지 추출

2\. recapTitleInfo에서 번지 추출

3\. platPlc에서 정규식으로 동/번지 추출

4\. areaInfo에서 동/호 정보 추출 (공동주택)



\#### 9. PDF 미리보기 파일명 통일



\*\*수정된 파일\*\*: `result\_screen.dart`



\*\*문제\*\*: 미리보기 후 저장 시 "부동산정보.pdf"로 저장됨



\*\*해결\*\*:

\- 하드코딩된 `name: '부동산정보.pdf'` 제거

\- `notifier.previewPdf()` 호출로 동적 파일명 사용



\#### 10. PDF 푸터 간격 조정



\*\*수정된 파일\*\*: `pdf\_generator.dart`



\*\*변경\*\*: "금토끼부동산 제작"과 "https://goldenrabbit.biz" 사이 공백 3칸 추가



\#### 11. PDF 저장 완료 SnackBar 개선



\*\*수정된 파일\*\*: `result\_screen.dart`



\*\*변경\*\*:

\- "확인" 버튼 제거

\- `duration: 3초` 추가 (자동 닫힘)



\#### 12. 스플래시 스크린 이미지 설정



\*\*수정된 파일\*\*:

\- `android/app/src/main/res/drawable/launch\_background.xml`

\- `android/app/src/main/res/drawable-v21/launch\_background.xml`



\*\*추가된 파일\*\*:

\- `android/app/src/main/res/drawable/launch\_image.png`



\*\*이미지 소스\*\*: 서버 `/home/webapp/goldenrabbit/backend/assets/proppedia/logo\_proppedia\_portrait\_transparent\_logo only.png`



---



\### 수정 파일 요약 (2026-02-12)



| 파일 | 주요 변경 |

|------|----------|

| `login\_screen.dart` | 버튼 높이 54px |

| `register\_screen.dart` | 버튼 높이 54px |

| `home\_screen.dart` | 헤더 크기 확대, SingleChildScrollView |

| `result\_screen.dart` | 푸터 이중 제거, 안내문구 줄바꿈, SnackBar 3초 |

| `app\_footer.dart` | SafeArea, 구분자 |, 로고 라운드 |

| `search\_jibun\_screen.dart` | 입력예시 수정 |

| `pdf\_generator.dart` | 푸터 문구/간격/로고 |

| `pdf\_provider.dart` | 파일명 형식 (지번+동호+타임스탬프) |

| `launch\_background.xml` | 스플래시 이미지 활성

---

### 2026-02-13: 검색기록/즐겨찾기 동기화 및 삭제 기능 개선

#### 1. 검색기록 중복 제거 로직 수정

**문제**: 같은 행정구역(displayAddress)만 같아도 기존 기록을 덮어씀

**해결**: PNU(지번코드) + 동명 + 호명 기준으로 변경

**수정 파일**: `lib/core/database/database_service.dart`

```dart
// 변경 전: displayAddress로 비교
// 변경 후: PNU + dongName + hoName으로 비교
```

#### 2. 서버 동기화 기능 추가

앱 시작 시 서버에서 검색기록/즐겨찾기를 불러와 로컬에 동기화

**수정 파일**:
- `lib/data/datasources/remote/history_api.dart` - API 경로 수정 (`/app/api/user/history`)
- `lib/data/repositories/history_repository.dart` - `syncFromServer()` 메서드 추가
- `lib/data/repositories/favorites_repository.dart` - `syncFromServer()` 메서드 추가
- `lib/presentation/providers/history_provider.dart` - 동기화 호출
- `lib/presentation/providers/favorites_provider.dart` - 동기화 호출
- `lib/presentation/screens/history/history_screen.dart` - 화면 진입 시 자동 동기화
- `lib/presentation/screens/favorites/favorites_screen.dart` - 화면 진입 시 자동 동기화

**동기화 로직**:
- PNU별 최신 기록만 가져오기 (중복 제거)
- 로컬에 없는 기록만 추가
- 당겨서 새로고침 시 서버 재동기화

#### 3. 삭제 시 서버 연동

**문제**: 로컬에서 삭제해도 서버에서 다시 동기화되어 복원됨

**해결**: 삭제 시 같은 PNU를 가진 모든 서버 기록도 함께 삭제

**수정 파일**:
- `lib/presentation/providers/history_provider.dart` - `deleteHistory()` 수정
- `lib/presentation/providers/favorites_provider.dart` - `deleteFavorite()` 수정

#### 4. 저장 기간 확인

| 항목 | 로컬(Hive) | 서버(PostgreSQL) |
|------|-----------|-----------------|
| 검색기록 | 최대 100개, 영구 저장 | 무제한, 영구 저장 |
| 즐겨찾기 | 무제한, 영구 저장 | 무제한, 영구 저장 |

#### 수정 파일 요약

| 파일 | 주요 변경 |
|------|----------|
| `database_service.dart` | 중복 제거 로직 PNU 기준으로 변경 |
| `history_api.dart` | API 경로 `/app/api/user/history`로 수정 |
| `history_repository.dart` | `syncFromServer()` 추가, PNU별 최신 기록만 |
| `favorites_repository.dart` | `syncFromServer()` 추가 |
| `history_provider.dart` | 삭제 시 서버 연동, 동기화 메서드 |
| `favorites_provider.dart` | 삭제 시 서버 연동, 동기화 메서드 |
| `history_screen.dart` | 화면 진입 시 서버 동기화 |
| `favorites_screen.dart` | 화면 진입 시 서버 동기화 |

---

### 2026-02-18: 웹/앱 매물 상세 UI 통일 및 카테고리 UI 개선

#### 1. 웹 공유 페이지 (property-detail.html) 리디자인

**서버 파일**: `/home/webapp/goldenrabbit/frontend/public/property-detail.html`

**변경 사항**:
- Tailwind CSS 적용 (goldenrabbit.biz 디자인과 통일)
- 다크모드 지원 (`darkMode: 'class'`)
- API 엔드포인트 변경: `/api/property/by-id` → `/api/property-detail` (Airtable 필드 직접 사용)
- 이미지 메타데이터 기반 로딩 (`image_metadata.json`)
- 고정 헤더 (로고 + 금토끼부동산)
- 좁은 너비 (`max-w-lg`) - 앱과 동일

**표시 정보**:
1. 이미지
2. 지번 주소 + 매매가
3. 정보 행 (융자제외 실투자금, 수익률, 평단가)
4. 상세정보
5. 금토끼부동산 정보
6. 버튼 (문의하기 + 지도보기)
7. 홈페이지 링크

#### 2. 앱 매물 상세 화면 웹과 동일하게 수정

**수정 파일**: `lib/presentation/screens/property/property_detail_screen.dart`

**변경 사항**:
- 버튼 배치: 문의하기/지도보기 나란히 + 링크복사 별도 행 (웹과 동일)
- 문의하기: 확인 다이얼로그 → 바로 전화 (웹과 동일)
- 지도 연결: 카카오맵 → 네이버 지도 (웹과 동일)
- 버튼 높이: 48px → 52px (글자 잘림 해결)
- 링크복사 버튼: 파란색 테두리 스타일

#### 3. 카테고리 UI 개선 (SegmentedButton)

**수정 파일**: `lib/presentation/screens/property/property_list_screen.dart`

**변경 전**: TabBar (스크롤, 좌측 정렬, 긴 레이블)
**변경 후**: SegmentedButton (균등 분할, 둥근 모서리, 골드 강조)

**레이블 변경**:
- '재건축용 토지' → '재건축토지'
- '고수익률 건물' → '고수익건물'
- '저가단독주택' → '단독주택'

**기타 변경**:
- 헤더 제목: '금토끼부동산 추천매물' → '추천매물' (잘림 방지)
- 체크 아이콘 제거 (`showSelectedIcon: false`)
- TabController 제거 → 단순 상태 관리로 변경

#### 4. 서버 백업 데이터 사용 확인

앱이 이미 서버 백업 데이터를 사용 중임 확인:
- `/api/property-list` → `all_properties.json`
- `/api/property-detail` → `all_properties.json`
- `/api/category-properties` → 카테고리별 JSON 파일
- `/airtable_backup/images/` → 백업 이미지

#### 수정 파일 요약

| 파일 | 주요 변경 |
|------|----------|
| `property-detail.html` (서버) | Tailwind CSS, API 변경, 메타데이터 이미지 |
| `property_detail_screen.dart` | 버튼 배치/동작 웹과 통일, 네이버 지도 |
| `property_list_screen.dart` | SegmentedButton, 짧은 레이블, 체크 제거 |

