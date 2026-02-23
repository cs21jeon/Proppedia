# GoldenRabbit 서비스 아키텍처 정리

> 작성일: 2026-02-11
> 최종 업데이트: 2026-02-23

## 개요

GoldenRabbit는 부동산 정보 관리 및 조회를 위한 통합 플랫폼입니다. 총 5개의 주요 서비스로 구성되어 있으며, 각 서비스는 독립적으로 운영되면서도 데이터와 인프라를 공유합니다.

### 서비스 목록

1. **금토끼부동산 웹페이지** - 메인 공개 홈페이지
2. **부동산정보조회 웹서비스** - 관리자용 Property Manager
3. **부동산정보조회 웹앱서비스** - 일반 사용자용 PWA 앱
4. **부동산데이터관리 시스템 (PropSheet)** - 워크스페이스 기반 데이터베이스 관리
5. **Threads 뉴스레터 발행** - 자동화된 부동산 뉴스 큐레이션

---

## 1. 금토끼부동산 웹페이지

### 개요
- **URL**: `https://goldenrabbit.biz/`
- **목적**: 공개 메인 홈페이지 (브랜딩, 매물 소개, 상담 문의)
- **기술**: 정적 HTML/CSS/JavaScript, Nginx

### 주요 참조 파일

#### 프론트엔드
```
frontend/public/
├── index.html                    # 메인 홈페이지
├── about.html                    # 회사 소개
├── inquiry.html                  # 상담 문의 페이지
├── property-detail.html          # 매물 상세보기
├── privacy-policy.html           # 개인정보처리방침
├── terms-of-service.html         # 이용약관
├── data-deletion.html            # 데이터 삭제 정책
├── airtable_map.html            # 매물 지도 (cron 자동 생성)
├── css/
│   └── styles.css                # 메인 스타일시트
├── js/
│   └── main.js                   # 메인 JavaScript
├── images/
│   ├── logo_goldenrabbit.jpg     # 로고
│   └── favicon_goldenrabbit_01.png # 파비콘
├── blog_thumbs/                  # 블로그 썸네일 (자동 생성)
└── data/
    └── latest_news.json          # 최신 뉴스 (뉴스레터 시스템이 생성)
```

#### 백엔드 API (Port 8000)
```
backend/api/
├── app.py                        # Flask API 서버 메인
└── utils/
    ├── backup_loader.py          # 백업 데이터 로더
    ├── instagram_auth.py         # Instagram 인증
    ├── threads_auth.py           # Threads 인증
    └── token_manager.py          # 토큰 관리
```

#### 주요 API 엔드포인트
- `/api/property-list` - 매물 목록
- `/api/property-detail` - 매물 상세 조회
- `/api/category-properties` - 카테고리별 매물
- `/api/search-map` - 지도 검색
- `/api/submit-inquiry` - 상담 문의 접수
- `/api/blog-feed` - 블로그 RSS 피드
- `/data/latest_news.json` - 최신 뉴스
- `/property/{record_id}` - SNS 공유용 메타 태그 생성

#### Nginx 설정
```
config/nginx/goldenrabbit.conf    # Nginx 메인 설정 파일
```

### 데이터 흐름
1. 정적 HTML/CSS/JS → Nginx → 사용자
2. API 요청 → Nginx → Port 8000 (API Server) → Airtable 백업 데이터
3. 이미지 → `/airtable_backup/images/` → Nginx 정적 파일

---

## 2. 부동산정보조회 웹서비스 (Property Manager)

### 개요
- **URL**: `https://goldenrabbit.biz/property-manager/`
- **목적**: 관리자용 건축물 정보 조회 및 Airtable 저장
- **기술**: Flask (Python), 공공데이터 API, VWorld API
- **인증**: 세션 기반 로그인 (`@login_required`)

### 주요 참조 파일

#### 백엔드 (Port 5000)
```
backend/property-manager/
├── app.py                        # Flask 앱 메인 (Property Manager + PropSheet)
├── routes/
│   ├── address_finder.py         # 주소 찾기
│   ├── airtable.py               # Airtable 저장
│   ├── app_api.py                # 앱 API (건물 검색, PDF 생성)
│   ├── app_auth.py               # 앱 사용자 인증
│   ├── app_user_data.py          # 사용자 데이터 (즐겨찾기, 히스토리)
│   ├── auth.py                   # 로그인 인증 (@login_required)
│   ├── blog.py                   # 블로그 관리
│   ├── database.py               # 데이터베이스 관리
│   ├── geocoding.py              # 지오코딩
│   ├── instagram.py              # Instagram 연동
│   ├── property.py               # 건축물 정보 조회
│   ├── propsheet.py              # PropSheet 라우트
│   ├── search.py                 # 건물 검색
│   ├── search_map.py             # 지도 검색
│   └── workspace.py              # 워크스페이스 관리
├── services/
│   ├── address_finder_service.py    # 주소 검색 서비스
│   ├── airtable_service.py          # Airtable CRUD
│   ├── app_favorite_service.py      # 앱 즐겨찾기 서비스
│   ├── app_history_service.py       # 앱 검색기록 서비스
│   ├── app_usage_stats_service.py   # 앱 사용 통계 서비스
│   ├── app_user_service.py          # 앱 사용자 서비스
│   ├── bjdong_service.py            # 법정동 코드 변환
│   ├── blog_service.py              # 블로그 서비스
│   ├── building_unified_service.py  # 통합 건축물 조회 (일반/다세대 자동 라우팅)
│   ├── cadastral_service.py         # 지적도 서비스
│   ├── database_service.py          # 데이터베이스 서비스
│   ├── instagram_service.py         # Instagram 서비스
│   ├── pdf_service.py               # PDF 생성 서비스
│   ├── pdf_service_v2.py            # PDF 생성 서비스 v2
│   ├── record_id_service.py         # 레코드 ID 서비스
│   ├── schema_service.py            # 스키마 서비스
│   ├── vworld_service.py            # VWorld API (토지 정보, 대지지분)
│   └── workspace_service.py         # 워크스페이스 서비스
├── templates/
│   ├── index.html                # Property Manager 메인
│   ├── public.html               # 공개 조회 페이지 (로그인 불필요)
│   └── address_finder.html       # 주소 찾기 페이지
└── static/
    ├── app.js                    # Property Manager JavaScript
    └── styles.css                # Property Manager 스타일
```

#### 주요 API 엔드포인트
- `/property-manager/` - 메인 페이지 (로그인 필요)
- `/property-manager/public/` - 공개 조회 페이지
- `/property-manager/address-finder` - 주소 찾기
- `/property-manager/api/property/area` - 건축물 면적 조회
- `/property-manager/api/property/title` - 건축물 표제부
- `/property-manager/api/airtable/save` - Airtable 저장
- `/property-manager/login` - 로그인
- `/property-manager/logout` - 로그아웃

### 핵심 로직
1. **건축물 통합 조회**: `building_unified_service.py`가 일반건축물/다세대를 자동 판별
2. **대지지분 계산**: VWorld API 우선 → 실패 시 수동 계산
3. **주소 변환**: Google Apps Script로 주소 → 법정동코드 변환
4. **Airtable 저장**: 조회 결과를 Airtable에 저장

---

## 3. 부동산정보조회 웹앱서비스 (PWA App)

### 개요
- **URL**: `https://goldenrabbit.biz/app/`
- **목적**: 일반 사용자용 PWA 앱 (모바일 최적화)
- **기술**: PWA (Service Worker, Manifest), Flask API
- **기능**: 건물 검색, 결과 PDF 저장, 즐겨찾기, 히스토리

### 주요 참조 파일

#### 프론트엔드 (PWA)
```
frontend/public/app/
├── index.html                    # 앱 메인 페이지
├── login.html                    # 로그인
├── profile.html                  # 사용자 프로필
├── search-method.html            # 검색 방법 선택
├── search-jibun.html             # 지번 검색
├── search-road.html              # 도로명 검색
├── search-map.html               # 지도 검색
├── result.html                   # 검색 결과
├── favorites.html                # 즐겨찾기
├── history.html                  # 검색 히스토리
├── about.html                    # 앱 정보
├── manifest.json                 # PWA Manifest
├── sw.js                         # Service Worker
├── ad-consent.js                 # 광고 동의
├── js/
│   ├── app.js                    # 앱 메인 로직
│   ├── search.js                 # 검색 기능
│   ├── map.js                    # 지도 기능
│   └── pdf.js                    # PDF 생성
├── css/
│   └── app.css                   # 앱 스타일
└── images/
    ├── favicon.ico               # 파비콘
    ├── icon-192x192.png          # PWA 아이콘
    ├── icon-512x512.png          # PWA 아이콘
    └── maskable-icon.png         # Maskable 아이콘
```

#### 백엔드 API (Port 5000)
```
backend/property-manager/
├── routes/
│   ├── app_api.py                # 앱 API (건물 검색, PDF 생성)
│   ├── app_auth.py               # 앱 사용자 인증
│   └── app_user_data.py          # 사용자 데이터 (즐겨찾기, 히스토리)
└── services/
    ├── app_favorite_service.py   # 즐겨찾기 서비스
    ├── app_history_service.py    # 검색기록 서비스
    ├── app_usage_stats_service.py # 사용 통계 서비스
    ├── app_user_service.py       # 사용자 서비스
    └── pdf_service_v2.py         # PDF 생성 서비스
```

#### 주요 API 엔드포인트
- `/app/api/search-jibun` - 지번 검색
- `/app/api/search-road` - 도로명 검색
- `/app/api/generate-pdf` - PDF 생성
- `/app/api/auth/register` - 회원가입
- `/app/api/auth/login` - 로그인
- `/app/api/user/favorites` - 즐겨찾기 관리
- `/app/api/user/history` - 검색 히스토리

### Nginx 설정
```nginx
# 앱 정적 파일 (PWA)
location /app/ {
    alias /home/webapp/goldenrabbit/frontend/public/app/;
    try_files $uri $uri/ /app/index.html;
}

# 앱 API (백엔드)
location /app/api/ {
    proxy_pass http://127.0.0.1:5000;
}
```

---

## 4. 부동산데이터관리 시스템 (PropSheet)

### 개요
- **URL**: `https://goldenrabbit.biz/propsheet/`
- **목적**: 워크스페이스 기반 데이터베이스 관리 (Notion 스타일)
- **기술**: Flask, SQLite (workspace.db)
- **인증**: 로그인 필요 (`@login_required`)

### 주요 참조 파일

#### 백엔드 (Port 5000 - Property Manager와 동일 앱)
```
backend/property-manager/
├── app.py                        # Flask 앱 (MultiPrefixMiddleware)
├── routes/
│   ├── propsheet.py              # PropSheet 라우트
│   ├── database.py               # 데이터베이스 관리
│   └── workspace.py              # 워크스페이스 관리
├── services/
│   ├── database_service.py       # 데이터베이스 서비스
│   ├── schema_service.py         # 스키마 서비스
│   └── workspace_service.py      # 워크스페이스/데이터베이스 관리
└── templates/propsheet/
    ├── workspaces.html           # 워크스페이스 목록
    ├── workspace_detail.html     # 워크스페이스 상세
    └── database_list.html        # 데이터베이스 목록
```

#### 데이터베이스
```
backend/property-manager/
└── workspace.db                  # SQLite 데이터베이스
    ├── workspaces                # 워크스페이스 테이블
    ├── databases                 # 데이터베이스 테이블
    └── {table_name}              # 각 데이터베이스별 동적 테이블
```

#### 주요 API 엔드포인트
- `/propsheet/workspaces` - 워크스페이스 목록
- `/propsheet/workspace/{slug}` - 워크스페이스 상세
- `/propsheet/workspace/{ws_slug}/database/{db_slug}` - 데이터베이스 뷰
- `/propsheet/api/workspaces` - 워크스페이스 목록 API
- `/propsheet/api/workspace` - 워크스페이스 생성/수정/삭제
- `/propsheet/api/workspace/{slug}/database` - 데이터베이스 생성

### 핵심 기능
1. **워크스페이스 관리**: Slug 기반 URL 라우팅
2. **데이터베이스 관리**: 동적 테이블 생성, 복제
3. **레거시 리다이렉션**: 기존 `/property-manager/database` → PropSheet로 자동 리다이렉트

---

## 5. Threads 뉴스레터 발행 관련

### 개요
- **목적**: 네이버 부동산 뉴스 크롤링 → Claude 요약 → Threads 발행 + 웹사이트 업데이트
- **실행**: Cron (예정된 시간에 자동 실행)
- **기술**: Python, Anthropic Claude API, Threads API

### 주요 참조 파일

#### 뉴스레터 시스템
```
backend/real-estate-newsletter/
├── main.py                       # 메인 실행 파일
├── publish_scheduled.py          # 스케줄러 (예정 발행)
├── refresh_token.py              # Threads 토큰 갱신
├── requirements.txt              # Python 패키지
├── data/
│   ├── daily_news.json           # 일일 뉴스 데이터
│   └── publish_status.json       # 발행 상태
├── logs/
│   └── newsletter.log            # 로그 파일
└── src/
    ├── config.py                 # 설정 파일
    ├── crawler.py                # 네이버 뉴스 크롤러
    ├── summarizer.py             # Claude AI 요약
    └── threads_publisher.py      # Threads 발행
```

#### 웹사이트 연동
```
frontend/public/data/
└── latest_news.json              # 뉴스레터 시스템이 생성 (오전 업데이트)
```

### 워크플로우
1. **크롤링**: `crawler.py` → 네이버 부동산 뉴스 수집
2. **요약**: `summarizer.py` → Claude API로 뉴스 요약
3. **발행**: `threads_publisher.py` → Threads 게시
4. **웹사이트 업데이트**: `latest_news.json` 생성 (오전 6-12시)

### 실행 방법
```bash
# 수동 실행
cd /home/webapp/goldenrabbit/backend/real-estate-newsletter
python3 main.py run

# 예정 발행 (스케줄러)
python3 publish_scheduled.py

# 토큰 갱신
python3 refresh_token.py
```

### API 엔드포인트
```
# API 서버 (Port 8000)에서 제공
/api/news/refresh    # 뉴스 수동 새로고침
/api/news/status     # 뉴스 상태 확인
/data/latest_news.json  # 최신 뉴스 데이터
```

---

## 통합 인프라

### 공유 리소스

#### 환경 변수
```
backend/.env                      # 모든 서비스가 공유하는 환경 변수
```

**주요 환경 변수**:
- `AIRTABLE_API_KEY` - Airtable API 키
- `PUBLIC_API_KEY` - 공공데이터포털 API 키
- `VWORLD_APIKEY` - VWorld API 키
- `GOOGLE_SCRIPT_URL` - 주소 변환 스크립트 URL
- `FLASK_SECRET_KEY` - Flask 세션 키
- `ADMIN_USERNAME` / `ADMIN_PASSWORD_HASH` - 관리자 인증
- `ANTHROPIC_API_KEY` - Claude API 키
- `KAKAO_REST_API_KEY` - 카카오 지오코딩 API

#### 가상환경
```
backend/venv/                     # 모든 백엔드 서비스가 공유
```

#### 로그 디렉토리
```
logs/
├── api/
│   ├── api_debug.log             # API 서버 로그
│   ├── service.log               # 서비스 로그
│   └── error.log                 # 에러 로그
├── property-manager/
│   ├── app.log                   # Property Manager 로그
│   ├── service.log               # 서비스 로그
│   └── error.log                 # 에러 로그
└── nginx/
    ├── access.log                # Nginx 접근 로그
    └── error.log                 # Nginx 에러 로그
```

### Systemd 서비스

#### 서비스 파일
```
config/systemd/
├── goldenrabbit-api.service      # API 서버 (Port 8000)
└── goldenrabbit-property.service # Property Manager (Port 5000)
```

#### 서비스 관리
```bash
# 시작
sudo systemctl start goldenrabbit-api
sudo systemctl start goldenrabbit-property

# 상태 확인
sudo systemctl status goldenrabbit-api
sudo systemctl status goldenrabbit-property

# 재시작
sudo systemctl restart goldenrabbit-api
sudo systemctl restart goldenrabbit-property

# 로그 확인
journalctl -u goldenrabbit-api -f
journalctl -u goldenrabbit-property -f
```

### Cron Jobs

#### Airtable 백업
```cron
# 매일 오전 2시
0 2 * * * /usr/bin/python3 /home/webapp/goldenrabbit/backend/scripts/airtable_backup.py
```
- **스크립트**: `backend/scripts/airtable_backup.py`
- **출력**: `backups/airtable/all_properties.json`, `coordinates.json`
- **로그**: `/var/log/airtable_backup.log`

#### 지도 생성
```cron
# 매일 오전 3시
0 3 * * * /usr/bin/python3 /home/webapp/goldenrabbit/backend/scripts/generate_map.py
```
- **스크립트**: `backend/scripts/generate_map.py`
- **출력**: `frontend/public/airtable_map.html`
- **로그**: `/var/log/airtable_map.log`

### 스크립트 목록
```
backend/scripts/
├── airtable_backup.py            # Airtable 백업
├── fetch_recomm_images.py        # 추천 이미지 가져오기
├── generate_map.py               # 지도 HTML 생성
├── instagram_auth.py             # Instagram 인증
├── instagram_token_exchange.py   # Instagram 토큰 교환
├── instagram_token_manager.py    # Instagram 토큰 관리
├── quick_token_setup.py          # 빠른 토큰 설정
├── save_blog_thumbnails.py       # 블로그 썸네일 저장
├── setup_threads_token_from_code.py # Threads 토큰 설정
├── test_instagram_token.py       # Instagram 토큰 테스트
├── threads_auth.py               # Threads 인증
├── threads_oauth_helper.py       # Threads OAuth 헬퍼
├── token_manager.py              # 토큰 관리
└── update_bjdong_codes.py        # 법정동 코드 업데이트
```

---

## 포트 및 URL 매핑

| 서비스 | 포트 | URL | 백엔드 위치 |
|--------|------|-----|-------------|
| API Server | 8000 | `/api/*`, `/property/{id}` | `backend/api/` |
| Property Manager | 5000 | `/property-manager/*` | `backend/property-manager/` |
| PropSheet | 5000 | `/propsheet/*` | `backend/property-manager/` |
| App | 5000 | `/app/*` (정적), `/app/api/*` (API) | `frontend/public/app/`, `backend/property-manager/` |
| 메인 웹페이지 | - | `/` | `frontend/public/` (Nginx 정적) |

---

## 배포 및 재시작

### 백엔드 배포
```bash
cd /home/webapp/goldenrabbit/backend
git pull
sudo systemctl restart goldenrabbit-api
sudo systemctl restart goldenrabbit-property
```

### 프론트엔드 배포
```bash
cd /home/webapp/goldenrabbit/frontend
git pull
# Nginx는 정적 파일을 직접 제공하므로 재시작 불필요
# 필요 시에만: sudo systemctl reload nginx
```

### Nginx 설정 변경
```bash
sudo nginx -t  # 설정 테스트
sudo systemctl reload nginx  # 리로드
```

---

## 트러블슈팅

### 서비스가 시작되지 않을 때
```bash
# 로그 확인
journalctl -u goldenrabbit-api -n 50 --no-pager
journalctl -u goldenrabbit-property -n 50 --no-pager

# 포트 확인
lsof -i:8000
lsof -i:5000

# 환경 변수 확인
grep -E "AIRTABLE_API_KEY|PUBLIC_API_KEY" /home/webapp/goldenrabbit/backend/.env
```

### 세션 문제 (Property Manager / PropSheet)
- 쿠키 경로: `/` (property-manager와 propsheet 공유)
- 세션 유지 시간: 24시간
- `FLASK_SECRET_KEY` 확인

### VWorld API 실패
- 자동으로 수동 계산으로 fallback
- 로그에서 "VWorld API 호출 실패 - 수동 계산으로 fallback" 확인

---

## 참고 문서

- [CLAUDE.md](/home/webapp/goldenrabbit/CLAUDE.md) - Claude Code용 프로젝트 가이드
- [Nginx 설정](/home/webapp/goldenrabbit/config/nginx/goldenrabbit.conf) - 라우팅 규칙
- [Systemd 서비스](/home/webapp/goldenrabbit/config/systemd/) - 서비스 설정
