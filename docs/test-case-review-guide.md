# 부동산 정보 조회 앱 - 테스트 케이스 검토 가이드

---

## 1. 개요

웹앱, Flutter 크롬앱, Flutter 모바일앱의 **조회화면**과 **PDF 출력**의 일관성을 검증하는 프로세스입니다.

---

## 2. 테스트 케이스 목록

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

---

## 3. 데이터 조회 방법

### 3.1 건물/토지 기본정보 조회 (jibun API)

```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"86","ji":"6","land_type":"1"}'
```

**파라미터:**
- `bjdong_code`: 법정동코드 (사당동 = 1159010700)
- `bun`: 본번 (86)
- `ji`: 부번 (6)
- `land_type`: 토지구분 (1=대지, 2=임야)

**응답 구조:**
```json
{
  "success": true,
  "address": { "sido_name", "sigungu_name", "eupmyeondong_name", "full_address" },
  "codes": { "bjdong_code", "bun", "ji", "pnu" },
  "land": { "land_area", "parcel_count", "public_land_price", "price_year", ... },
  "building": {
    "type": "general" | "multi_unit" | "land_with_house_price",
    "has_data": true/false,
    "building_info": { ... },
    "recap_title_info": { ... },
    "dong_ho_dict": { "동명": [{ "ho_nm": "101호" }, ...] },
    "floor_info": [ ... ]
  }
}
```

### 3.2 전유부 정보 조회 (area API)

```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/area" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"86","ji":"6","dong_nm":"동 없음","ho_nm":"101호"}'
```

**응답 구조:**
```json
{
  "success": true,
  "dong_nm": "동 없음",
  "ho_nm": "101호",
  "exclusive_area": 84.5,
  "supply_area": 112.3,
  "land_share": 25.5,
  "house_price": 450000000,
  "house_price_year": "2025",
  "dong_title_info": { ... }
}
```

---

## 4. 검토 대상 파일

### 4.1 웹앱 (goldenrabbit.biz/app)

| 파일 | 위치 | 용도 |
|------|------|------|
| result.html | `/home/webapp/goldenrabbit/frontend/public/app/result.html` | 조회화면 + PDF 생성 |

**SSH 접속:**
```bash
ssh root@175.119.224.71
```

**파일 읽기:**
```bash
ssh root@175.119.224.71 "cat /home/webapp/goldenrabbit/frontend/public/app/result.html"
```

**특정 함수 검색:**
```bash
ssh root@175.119.224.71 "grep -n 'displayBasicInfo\|displayLandInfo\|displayGeneralBuilding\|displayMultiUnitBuilding' /home/webapp/goldenrabbit/frontend/public/app/result.html"
```

### 4.2 Flutter 앱

| 파일 | 경로 | 용도 |
|------|------|------|
| result_screen.dart | `lib/presentation/screens/search/result_screen.dart` | 조회화면 |
| pdf_generator.dart | `lib/core/pdf/pdf_generator.dart` | PDF 생성 |
| building_dto.dart | `lib/data/dto/building_dto.dart` | 데이터 모델 |

---

## 5. 검증 항목 체크리스트

### 5.1 기본정보 섹션

| 항목 | 웹앱 조회 | 웹앱 PDF | Flutter 조회 | Flutter PDF |
|------|----------|---------|--------------|-------------|
| 지번주소 (시도 포함) | ☐ | ☐ | ☐ | ☐ |
| 도로명주소 (시도 포함) | ☐ | ☐ | ☐ | ☐ |
| 세대/가구/호 라벨 | ☐ | ☐ | ☐ | ☐ |
| 세대/가구/호 값 (0 표시) | ☐ | ☐ | ☐ | ☐ |
| 주용도 | ☐ | ☐ | ☐ | ☐ |

### 5.2 토지정보 섹션

| 항목 | 웹앱 조회 | 웹앱 PDF | Flutter 조회 | Flutter PDF |
|------|----------|---------|--------------|-------------|
| 토지면적 + 평 | ☐ | ☐ | ☐ | ☐ |
| 필지수 [n필지] | ☐ | ☐ | ☐ | ☐ |
| 공시지가 + 년도 | ☐ | ☐ | ☐ | ☐ |
| 건물없음: 상세표시 | ☐ | ☐ | ☐ | ☐ |

### 5.3 건물정보 섹션

| 항목 | 웹앱 조회 | 웹앱 PDF | Flutter 조회 | Flutter PDF |
|------|----------|---------|--------------|-------------|
| 대지면적 + 평 + 필지수 | ☐ | ☐ | ☐ | ☐ |
| 연면적 + 평 | ☐ | ☐ | ☐ | ☐ |
| 건축면적 + 평 | ☐ | ☐ | ☐ | ☐ |
| 층수 (모든 건물타입) | ☐ | ☐ | ☐ | ☐ |
| 높이 | ☐ | ☐ | ☐ | ☐ |
| 주차대수 + 대 | ☐ | ☐ | ☐ | ☐ |
| 승강기수 + 기 | ☐ | ☐ | ☐ | ☐ |

### 5.4 전유부정보 섹션 (공동주택)

| 항목 | 웹앱 조회 | 웹앱 PDF | Flutter 조회 | Flutter PDF |
|------|----------|---------|--------------|-------------|
| 동/호 | ☐ | ☐ | ☐ | ☐ |
| 전용면적 + 평 | ☐ | ☐ | ☐ | ☐ |
| 공급면적 + 평 | ☐ | ☐ | ☐ | ☐ |
| 대지지분 + 평 | ☐ | ☐ | ☐ | ☐ |
| 공동주택가격 + 년도 | ☐ | ☐ | ☐ | ☐ |

---

## 6. 테스트 실행 절차

### Step 1: API 데이터 조회
```bash
# 케이스별 건물정보 조회
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"86","ji":"6","land_type":"1"}' | jq .
```

### Step 2: 웹앱 확인
1. 브라우저에서 접속: `https://goldenrabbit.biz/app/result.html?bjdong_code=1159010700&bun=86&ji=6`
2. 조회화면 캡처
3. PDF 다운로드 버튼 클릭 → PDF 캡처

### Step 3: Flutter 앱 확인
```bash
# Windows/Chrome에서 실행
flutter run -d windows
flutter run -d chrome

# Android 에뮬레이터
flutter run -d android
```

### Step 4: 비교표 작성
각 항목별로 4개 출력물(웹앱 조회/PDF, Flutter 조회/PDF) 비교

### Step 5: 불일치 수정
- 웹앱: `result.html` 수정 (SSH)
- Flutter: `result_screen.dart`, `pdf_generator.dart` 수정

---

## 7. 주요 코드 위치 (웹앱)

```javascript
// result.html 내 주요 함수
displayBasicInfo(data)              // 기본정보 표시 (~line 470)
displayLandInfo(land, hasBuilding)  // 토지정보 표시 (~line 518)
displayGeneralBuilding(building)    // 일반건축물 표시 (~line 586)
displayMultiUnitBuilding(building, codes)  // 공동주택 표시 (~line 710)
displayAreaInfo(areaInfo)           // 전유부정보 표시
createPDFPreviewHTML()              // PDF 생성 (~line 1360)
```

## 8. 주요 코드 위치 (Flutter)

```dart
// result_screen.dart
_buildBasicInfoCard()           // 기본정보 카드
_buildLandCard()                // 토지정보 카드
_buildBuildingInfoCard()        // 건물정보 카드
_buildDongTitleInfoSection()    // 해당동 정보
_buildExclusiveInfoSection()    // 전유부 정보
_formatTotalUnits()             // 세대/가구/호 포맷

// pdf_generator.dart
_buildBasicInfoSection()        // PDF 기본정보
_buildLandSection()             // PDF 토지정보
_buildBuildingSection()         // PDF 건물정보
_buildAreaInfoSection()         // PDF 전유부정보
```

---

## 9. 발견된 주요 이슈 및 수정 이력

| 날짜 | 이슈 | 영향 범위 | 수정 내용 |
|------|------|----------|----------|
| 2026-02-11 | `fmly` 변수 미정의 버그 | 웹앱 | `fmly` → `family` |
| 2026-02-11 | 세대/가구/호 기본값 | 웹앱 | `-/-/-` → `0/0/0` |
| 2026-02-11 | 필지수 표시 형식 | 전체 | `(합계)` → `[n필지]` |
| 2026-02-11 | 층수/높이/승강기 누락 | Flutter 조회 | 항목 추가 |
| 2026-02-11 | 세대/가구/호 라벨 | Flutter 조회 | `총 세대/가구/호` → `세대/가구/호` |

---

## 10. 참고 사항

- **MCP 설정 파일**: `C:\Users\ant19\projects\propedia\.mcp.json`
- **서버 접속**: `ssh root@175.119.224.71`
- **법정동코드 (사당동)**: `1159010700`
- **Flutter 분석**: `flutter analyze lib/presentation/screens/search/result_screen.dart`

---

## 11. 케이스별 API 호출 예시

### Case 1: 토지만 (임야)
```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"32","ji":"77","land_type":"2"}'
```

### Case 3: 일반건축물
```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"1044","ji":"23","land_type":"1"}'
```

### Case 4: 공동주택
```bash
# 건물 조회
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"314","ji":"12","land_type":"1"}'

# 전유부 조회
curl -s -X POST "https://goldenrabbit.biz/app/api/area" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"314","ji":"12","dong_nm":"동 없음","ho_nm":"201호"}'
```

### Case 5: 다필지 공동주택
```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"280","ji":"1","land_type":"1"}'
```

### Case 6: 대규모 아파트
```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"1154","ji":"0","land_type":"1"}'
```

### Case 7: 복잡한 동/호명
```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"147","ji":"29","land_type":"1"}'
```

### Case 8: 비주거 건물
```bash
curl -s -X POST "https://goldenrabbit.biz/app/api/search/jibun" \
  -H "Content-Type: application/json" \
  -d '{"bjdong_code":"1159010700","bun":"86","ji":"6","land_type":"1"}'
```
