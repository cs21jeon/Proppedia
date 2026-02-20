# Google Play Store 및 AdMob 설정 기록

## 설정 일자: 2026-02-18 ~ 02-20

---

## 1. Google Play Console 설정

### 계정 정보
- **계정 생성**: 완료
- **등록비 결제**: $25 완료
- **앱 이름**: 부동산백과

### 앱 정보
- **패키지 이름**: `com.proppedia.app`
- **버전**: 1.0.1 (버전 코드 2)

### 앱 등록 상태
- [x] Play Console 계정 생성
- [x] 앱 생성 (Proppedia)
- [x] 스토어 등록정보 작성
- [x] 앱 설정 완료
- [x] 비공개 테스트 트랙 생성
- [x] AAB 업로드 완료
- [x] 테스터 20명 모집
- [x] 테스터 초대 및 옵트인
- [ ] 14일간 테스트 진행
- [ ] 프로덕션 출시

---

## 2. AdMob 설정

### 계정 정보
- **AdMob 계정**: 등록 완료
- **앱 이름**: Proppedia

### 광고 단위

| 항목 | 값 |
|------|-----|
| 광고 단위 이름 | Ad_Proppedia |
| 광고 형식 | 배너 |
| 광고 단위 ID | `ca-app-pub-3478991909223100/1393451919` |

### AdMob App ID
- **앱 ID**: `ca-app-pub-3478991909223100~4421163836`

---

## 3. Flutter 앱 연동 상태

- [x] google_mobile_ads 패키지 추가
- [x] AndroidManifest.xml에 AdMob App ID 추가
- [x] 배너 광고 위젯 구현 (`lib/presentation/widgets/ads/banner_ad_widget.dart`)
- [x] 광고 서비스 구현 (`lib/core/ads/ad_service.dart`)
- [x] 홈 화면에 배너 광고 추가
- [x] 결과 화면에 배너 광고 추가
- [x] 즐겨찾기 화면에 배너 광고 추가
- [x] 검색기록 화면에 배너 광고 추가
- [x] 테스트 광고 확인 완료
- [x] 릴리즈 빌드 시 실제 광고 ID 자동 적용

---

## 4. 앱 설정 완료 항목

### 개인정보처리방침
- **URL**: `https://goldenrabbit.biz/privacy-policy.html`

### 앱 액세스 권한 (테스트 계정)
- **이메일**: `review@proppedia.com`
- **비밀번호**: `ReviewTest2026!`
- **이름**: Test User

### 데이터 보안
- 필수 데이터 수집: 예
- 암호화 전송: 예 (HTTPS)
- 계정 생성 방법: 사용자 이름 및 비밀번호
- 계정 삭제 URL: `https://goldenrabbit.biz/privacy-policy.html`

### 콘텐츠 등급
- 설문지 작성 완료

### 타겟층
- 설정 완료

---

## 5. 빌드 파일

### 릴리즈 AAB
- **패키지 이름**: `com.proppedia.app`
- **파일 위치**: `build/app/outputs/bundle/release/app-release.aab`
- **파일 크기**: 61.1MB
- **버전**: 1.0.1 (버전 코드 2)
- **빌드 일자**: 2026-02-20

### 업데이트 내역
| 버전 | 날짜 | 변경사항 |
|-----|------|---------|
| 1.0.0+1 | 2026-02-19 | 최초 업로드 |
| 1.0.1+2 | 2026-02-20 | 앱 아이콘 변경, 앱 이름 "부동산백과"로 변경 |

### 키스토어
- **파일 위치**: `android/app/propedia-release-key.jks`
- **키 설정**: `android/key.properties`

---

## 6. 스토어 등록정보

### 앱 이름
```
부동산백과
```

### 간단한 설명 (80자)
```
건축물대장, 토지대장, 공시지가를 한눈에! 도로명/지번/지도로 부동산 정보를 무료로 조회하세요.
```

### 자세한 설명
```
🏠 Proppedia(부동산백과)는 대한민국 모든 부동산 정보를 한눈에 조회할 수 있는 무료 앱입니다.

📋 주요 기능

▶ 건축물 정보 조회
• 건축물대장 기반의 정확한 건물 정보
• 대지면적, 건축면적, 연면적, 용적률, 건폐율
• 층수, 구조, 주용도, 사용승인일
• 공동주택(아파트, 다세대) 동/호별 전용면적, 공급면적

▶ 토지 정보 조회
• 토지대장 기반의 토지 정보
• 지목, 토지면적, 용도지역
• 공시지가 (기준년도 포함)

▶ 공시가격 조회
• 개별주택가격 (단독주택)
• 공동주택가격 (아파트, 다세대)
• 개별공시지가

▶ 3가지 검색 방식
• 도로명 주소 검색
• 지번 주소 검색
• 지도에서 위치 선택 검색

▶ 편의 기능
• 즐겨찾기 - 관심 부동산 저장
• 검색기록 - 최근 조회 내역 확인
• PDF 저장/공유 - 조회 결과를 PDF로 저장

📍 이런 분들께 추천합니다
• 부동산 투자를 검토하시는 분
• 이사할 집을 알아보시는 분
• 공인중개사, 부동산 관련 종사자
• 건축, 인테리어 관련 업무 종사자
• 부동산 공부를 시작하시는 분

💡 데이터 출처
• 국토교통부 건축물대장
• 국토교통부 토지대장
• 한국부동산원 부동산공시가격
• 공공데이터포털, VWorld

📞 문의
• 이메일: ant1975@hanmail.net
• 제작: 금토끼부동산 (https://goldenrabbit.biz)

※ 본 앱의 정보는 참고용이며, 정확한 내용은 관할 관청의 공적장부를 확인하시기 바랍니다.
```

### 출시노트
```
<ko-KR>
Proppedia 부동산백과 첫 번째 버전입니다.

주요 기능:
• 건축물대장 정보 조회
• 토지대장 정보 조회
• 공시지가/공시가격 조회
• 도로명/지번/지도 검색
• 즐겨찾기 및 검색기록 관리
• PDF 저장 및 공유
</ko-KR>
```

---

## 7. 스크린샷 및 이미지

### 저장 위치
`C:\Users\ant19\projects\propedia\screenshots\`

### 앱 아이콘
- **원본**: `assets/images/proppedia_logo.png`
- **스토어용**: `screenshots/icon_512x512.png`
- **설정 도구**: `flutter_launcher_icons` 패키지
- **배경색**: 흰색 (#FFFFFF)

### 특성 그래픽 (1024x500)
- `Feature Graphic_proppedia.png`

### 휴대전화 스크린샷 (1080x2340)
| 파일 | 화면 |
|-----|------|
| 01_home.png | 홈 화면 |
| 02_road_search.png | 도로명 검색 |
| 03_jibun_search.png | 지번 검색 |
| 04_result_1.png | 검색 결과 (기본/토지) |
| 05_result_2.png | 검색 결과 (동호/지도) |
| 06_map_search.png | 지도 검색 |
| 07_history.png | 검색기록 |
| 08_favorites.png | 즐겨찾기 |

### 7인치 태블릿 스크린샷 (1200x1920)
- `tablet_7inch/01_home.png`
- `tablet_7inch/02_road_search.png`
- `tablet_7inch/04_result_1.png`
- `tablet_7inch/06_map_search.png`

### 10인치 태블릿 스크린샷 (1600x2560)
- `tablet_10inch/01_home.png`
- `tablet_10inch/02_road_search.png`
- `tablet_10inch/04_result_1.png`
- `tablet_10inch/06_map_search.png`

---

## 8. 비공개 테스트 진행 현황

### Google Play 정책 요구사항
| 항목 | 요구사항 | 현황 |
|-----|---------|------|
| 테스트 유형 | 비공개 테스트 (Closed Testing) | ✅ 트랙 생성 완료 |
| AAB 업로드 | app-release.aab | ✅ 업로드 완료 |
| 테스트 기간 | 최소 **14일** 이상 | ⏳ 대기 중 |
| 테스터 수 | 최소 **20명** | ⏳ 모집 필요 |
| 테스터 활동 | 14일 동안 지속적으로 옵트인 | ⏳ 대기 중 |

### 비공개테스트 진행
유료테스트 진행 요청 (개발자 상부상조 카페 통해) : 2026.02.20.

### 다음 단계 (TODO)
1. [x] **테스터 20명 모집** (가족, 친구, 지인, 커뮤니티)
2. [x] **테스터 이메일 목록 등록** (Play Console → 비공개 테스트 → 테스터)
3. [x] **테스터 초대 링크 전송**
4. [ ] **테스터 옵트인 확인** (20명 이상)
5. [ ] **14일간 테스트 진행**
6. [ ] **프로덕션 출시 신청**

---

## 9. 중요 ID 정리

```
# 패키지 이름
com.proppedia.app

# AdMob App ID
ca-app-pub-3478991909223100~4421163836

# AdMob 광고 단위 ID (배너) - 실제
ca-app-pub-3478991909223100/1393451919

# AdMob 테스트용 배너 광고 ID (개발 중 사용)
ca-app-pub-3940256099942544/6300978111
```

---

## 참고 링크

- [Google Play Console](https://play.google.com/console)
- [AdMob Console](https://admob.google.com)
- [google_mobile_ads 패키지](https://pub.dev/packages/google_mobile_ads)
- [개인정보처리방침](https://goldenrabbit.biz/privacy-policy.html)
