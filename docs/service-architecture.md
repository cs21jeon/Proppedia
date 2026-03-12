# GoldenRabbit 서비스 아키텍처 정리

> 작성일: 2026-02-11
> 최종 업데이트: 2026-03-12

## 개요

GoldenRabbit는 부동산 정보 관리 및 조회를 위한 통합 플랫폼입니다.
단일 서버(`175.119.224.71`, 도메인 `goldenrabbit.biz`)에서 운영되며,
Nginx 리버스 프록시 뒤에 **3개 Systemd 서비스 + 1개 PM2 프로세스**가 동작합니다.

### 서비스 목록

1. **금토끼부동산 웹페이지** - 메인 공개 홈페이지
2. **부동산정보조회 웹서비스 (Property Manager)** - 관리자용
3. **Propedia 앱 (Flutter)** - 일반 사용자용 모바일/웹 앱
4. **부동산데이터관리 (PropSheet)** - 워크스페이스 기반 데이터베이스 관리
5. **쇼츠 자동화** - 부동산 쇼츠 영상 자동 생성
6. **PropTalk / VoiceRoom** - 랜딩페이지, 법적문서, STT 음성인식
7. **Threads 뉴스레터 발행** - 자동화된 부동산 뉴스 큐레이션

---

## 전체 요청 흐름도

```
[사용자/앱]
      │
      ▼
https://goldenrabbit.biz (port 443)
      │
      ▼
   [Nginx 리버스 프록시]
      │
      ├─ /app/api/*  ──────→ [Property Manager :5000]  ──→ PostgreSQL (app_users)
      │                       MultiPrefixMiddleware         공공데이터 API (apis.data.go.kr)
      │                       strips "/app" prefix
      │
      ├─ /api/*  ───────────→ [API Server :8000]  ──────→ Airtable
      │                                                     VWorld API
      │
      ├─ /shorts/*  ────────→ [Shorts Automation :5002]
      │
      ├─ /proptalk/*  ──────→ [PropTalk/VoiceRoom :5060]
      │   /voiceroom/*
      │
      ├─ /app/*  ───────────→ [정적 파일] frontend/public/app/ (Flutter 웹 빌드)
      └─ /*  ───────────────→ [정적 파일] frontend/public/ (메인 웹페이지)
```

---

## 포트 및 서비스 매핑

| 포트 | 서비스 | 프로세스 관리 | WorkingDirectory | 역할 |
|------|--------|--------------|------------------|------|
| 80/443 | Nginx | systemd | - | 리버스 프록시 + 정적 파일 |
| 5000 | Property Manager | systemd (`property-manager.service`) | `/backend/property-manager/` | 건축물 조회 + PropSheet + 앱 API |
| 8000 | API Server | systemd (`goldenrabbit-api.service`) | `/backend/api/` | VWorld/Airtable 프록시, 매물정보 |
| 5002 | Shorts Automation | systemd (`shorts-automation.service`) | `/backend/shorts_automation/` | 쇼츠 자동 생성 |
| 5060 | VoiceRoom | PM2 (`voiceroom`) | `/chat_stt/server/` | STT 음성인식 |

---

## Nginx URL 라우팅 맵

설정 파일: `/etc/nginx/sites-enabled/goldenrabbit`
(원본: `/home/webapp/goldenrabbit/config/nginx/goldenrabbit.conf`)

```
요청 URL                        → 프록시 대상         → 서비스
──────────────────────────────────────────────────────────────────
/app/api/auth/*                 → port 5000          → Property Manager (Flask)
/app/api/admin/*                → port 5000          → Property Manager
/app/api/*                      → port 5000          → Property Manager
/app/dashboard                  → port 5000          → Property Manager (관리자 대시보드)
/app/*                          → 정적 파일           → frontend/public/app/ (PWA)

/property-manager/*             → port 5000          → Property Manager
/propsheet/*                    → port 5000          → Property Manager

/api/vworld                     → port 8000          → API Server (Flask)
/api/vtile                      → port 8000          → API Server
/api/wms                        → port 8000          → API Server
/api/shorts                     → port 5002          → Shorts Automation
/api/*                          → port 8000          → API Server
/property/{id}                  → port 8000          → API Server (SNS 메타태그)
/(auth|webhook|deauth)/threads  → port 8000          → API Server
/services                       → port 8000          → API Server

/shorts/*                       → port 5002          → Shorts Automation (Flask)

/proptalk/*                     → port 5060          → PropTalk (Flask+PM2)
/voiceroom/api/*                → port 5060          → VoiceRoom STT
/voiceroom/socket.io/*          → port 5060          → VoiceRoom WebSocket

/                               → 정적 파일           → frontend/public/
/proppedia/                     → 정적 파일           → frontend/public/proppedia/
/airtable_backup/*              → 정적 파일           → backups/airtable/
/blog_thumbs/*                  → 정적 파일           → frontend/public/blog_thumbs/
/uploads/airtable/*             → 정적 파일           → backups/airtable/images/
/uploads/blog/*                 → 정적 파일           → backend/uploads/blog/
```

### 보안 규칙
- `location ~ /\.` → 모든 dot파일 차단 (`.env`, `.htaccess` 등)
- HTTP → HTTPS 강제 리다이렉트
- SSL: Let's Encrypt (`/etc/letsencrypt/live/goldenrabbit.biz/`)

### 캐싱 정책
- HTML: 캐시 없음 (항상 최신)
- CSS/JS: 7일
- 이미지: 30일
- PWA manifest/service worker: 캐시 없음

---

## Systemd 서비스 상세

### property-manager.service (포트 5000)

```ini
# /etc/systemd/system/property-manager.service
[Service]
WorkingDirectory=/home/webapp/goldenrabbit/backend/property-manager
Environment="PYTHONPATH=/home/webapp/goldenrabbit/backend"
ExecStart=/home/webapp/goldenrabbit/backend/venv/bin/python app.py
Restart=always
```

**MultiPrefixMiddleware**로 3개 URL 접두사를 하나의 Flask 앱에서 처리:
- `/property-manager` → 관리자 건축물 조회
- `/propsheet` → 워크스페이스 데이터베이스 관리
- `/app` → Propedia 앱 API (auth, search, favorites, history 등)

주요 블루프린트:
```
app_api.bp         → /api          (→ 실제: /app/api/*)          건축물 검색
app_auth.bp        → /api/auth     (→ 실제: /app/api/auth/*)     Google 인증
app_user_data.bp   → /api/user     (→ 실제: /app/api/user/*)     즐겨찾기, 검색기록
admin_dashboard.bp → /              (→ 실제: /app/dashboard)      관리자 대시보드
search.bp          → /api          (→ 실제: /property-manager/api/*)  건물 검색
property.bp        → /api          (→ 실제: /property-manager/api/*)  건축물 정보
airtable.bp        → /api          (→ 실제: /property-manager/api/*)  Airtable 저장
propsheet.bp       → (no prefix)   (→ 실제: /propsheet/*)        PropSheet
```

### goldenrabbit-api.service (포트 8000)

```ini
# /etc/systemd/system/goldenrabbit-api.service
[Service]
WorkingDirectory=/home/webapp/goldenrabbit/backend/api
Environment="PYTHONPATH=/home/webapp/goldenrabbit/backend"
ExecStart=/home/webapp/goldenrabbit/backend/venv/bin/python app.py
Restart=always
```

### shorts-automation.service (포트 5002)

```ini
# /etc/systemd/system/shorts-automation.service
[Service]
WorkingDirectory=/home/webapp/goldenrabbit/backend/shorts_automation
ExecStart=/home/webapp/goldenrabbit/backend/venv/bin/python app.py
Restart=always
```

---

## PM2 프로세스

| 이름 | 포트 | 경로 | 역할 |
|------|------|------|------|
| `voiceroom` | 5060 | `/home/webapp/goldenrabbit/chat_stt/server/app.py` | STT 음성인식 |
| `pm2-logrotate` | - | PM2 모듈 | 로그 로테이션 |

---

## Propedia Flutter 앱의 API 연결

### Base URL
```dart
// lib/core/network/api_client.dart
static const String baseUrl = 'https://goldenrabbit.biz';
```

### 앱이 사용하는 엔드포인트

| 카테고리 | 메서드 | 경로 | 서버 |
|----------|--------|------|------|
| **인증** | POST | `/app/api/auth/google` | port 5000 |
| | GET | `/app/api/auth/me` | port 5000 |
| | POST | `/app/api/auth/refresh` | port 5000 |
| | POST | `/app/api/auth/logout` | port 5000 |
| **건축물 검색** | POST | `/app/api/search/road` | port 5000 |
| | POST | `/app/api/search/jibun` | port 5000 |
| | POST | `/app/api/search/bdmgtsn` | port 5000 |
| | GET | `/app/api/bjdong/search` | port 5000 |
| | POST | `/app/api/area` | port 5000 |
| **사용자 데이터** | GET/POST/DELETE | `/app/api/user/favorites` | port 5000 |
| | GET/POST/DELETE | `/app/api/user/history` | port 5000 |
| | GET | `/app/api/user/usage-stats` | port 5000 |
| **매물 정보** | GET | `/api/property-list` | port 8000 |
| | GET | `/api/category-properties` | port 8000 |
| | GET | `/api/property-detail` | port 8000 |
| | GET | `/api/coordinates` | port 8000 |
| | POST | `/api/search-map` | port 8000 |

### 인증 흐름
1. Google Sign-In SDK → `idToken` 획득
2. `POST /app/api/auth/google` → JWT `access_token` + `refresh_token` 발급
3. `AuthInterceptor`가 모든 요청에 `Authorization: Bearer {token}` 자동 추가
4. 401 응답 시 → `/app/api/auth/refresh`로 토큰 갱신 → 실패 시 로그아웃

### 토큰 저장
- **모바일**: FlutterSecureStorage (암호화)
- **웹**: SharedPreferences (localStorage)

### Google OAuth Client IDs
- **serverClientId (모바일)**: `846392940969-a7k37gkon1p451mlnhp0oj9qaok1d8o1.apps.googleusercontent.com`
- **Web Client ID**: `846392940969-sv2936v0tm85j8hvdn3srcmtei1kk25e.apps.googleusercontent.com`
- Android Debug: `846392940969-g2afoiuc6m7kp64vp4fdo48rp2iqkt30.apps.googleusercontent.com`
- Android Release: `846392940969-1sdp4mc01gbsq2dgne4h8mnuvobi5644.apps.googleusercontent.com`

---

## 공유 리소스

### 환경 변수
```
/home/webapp/goldenrabbit/backend/.env    # 모든 서비스 공유
```

주요 변수: `AIRTABLE_API_KEY`, `PUBLIC_API_KEY`, `VWORLD_APIKEY`, `GOOGLE_SCRIPT_URL`, `FLASK_SECRET_KEY`, `ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`, `ANTHROPIC_API_KEY`, `KAKAO_REST_API_KEY`, `JWT_SECRET_KEY`, `DB_*` (PostgreSQL)

### 가상환경
```
/home/webapp/goldenrabbit/backend/venv/   # 모든 Python 서비스 공유
```

### 로그 디렉토리
```
logs/
├── api/                 # API Server (port 8000)
│   ├── service.log
│   └── error.log
├── property-manager/    # Property Manager (port 5000)
│   ├── app.log          # RotatingFileHandler (10MB x 5)
│   ├── service.log
│   └── error.log
└── nginx/
    ├── access.log
    └── error.log
```

### 데이터베이스
- **PostgreSQL**: `goldenrabbit_db` (user: `goldenrabbit_user`) — app_users, app_notices 등
- **SQLite**: `/backend/property-manager/workspace.db` — PropSheet 워크스페이스/데이터베이스

---

## Cron Jobs

```bash
# Airtable 백업 (매일 오전 2시)
0 2 * * * /usr/bin/python3 /home/webapp/goldenrabbit/backend/scripts/airtable_backup.py
# → 출력: backups/airtable/all_properties.json, coordinates.json

# 지도 생성 (매일 오전 3시)
0 3 * * * /usr/bin/python3 /home/webapp/goldenrabbit/backend/scripts/generate_map.py
# → 출력: frontend/public/airtable_map.html
```

---

## 서비스 관리 명령어

```bash
# Property Manager (앱 API)
sudo systemctl start|stop|restart|status property-manager
journalctl -u property-manager -f

# API Server
sudo systemctl start|stop|restart|status goldenrabbit-api
journalctl -u goldenrabbit-api -f

# Shorts Automation
sudo systemctl start|stop|restart|status shorts-automation

# VoiceRoom (PM2)
pm2 restart voiceroom
pm2 logs voiceroom

# Nginx
sudo nginx -t          # 설정 테스트
sudo systemctl reload nginx

# 포트 확인
ss -tlnp | grep -E '5000|5002|5060|8000|80|443'
```

---

## 주요 파일 경로

```
/home/webapp/goldenrabbit/
├── backend/
│   ├── .env                              # 공유 환경 변수
│   ├── venv/                             # 공유 가상환경
│   ├── api/app.py                        # API Server (port 8000)
│   ├── property-manager/
│   │   ├── app.py                        # Property Manager (port 5000)
│   │   ├── routes/
│   │   │   ├── app_api.py                # 앱 건축물 검색 API
│   │   │   ├── app_auth.py               # 앱 Google 인증
│   │   │   ├── app_user_data.py          # 앱 사용자 데이터
│   │   │   ├── admin_dashboard.py        # 관리자 대시보드
│   │   │   ├── search.py                 # Property Manager 검색
│   │   │   ├── property.py               # 건축물 정보
│   │   │   ├── propsheet.py              # PropSheet
│   │   │   └── ...
│   │   ├── services/
│   │   │   ├── app_user_service.py       # 앱 사용자/JWT 서비스
│   │   │   ├── building_unified_service.py # 통합 건축물 조회
│   │   │   ├── pdf_service_v2.py         # PDF 생성
│   │   │   └── ...
│   │   └── workspace.db                  # PropSheet SQLite DB
│   ├── shorts_automation/app.py          # Shorts (port 5002)
│   ├── real-estate-newsletter/           # Threads 뉴스레터
│   └── scripts/                          # 유틸리티 스크립트
├── chat_stt/server/app.py                # VoiceRoom (port 5060)
├── config/
│   ├── nginx/goldenrabbit.conf           # Nginx 설정 원본
│   └── systemd/                          # Systemd 서비스 파일
├── frontend/public/
│   ├── index.html                        # 메인 웹페이지
│   ├── app/                              # Flutter 웹 빌드 (PWA)
│   └── proppedia/                        # Proppedia 랜딩 페이지
├── backups/airtable/                     # Airtable 백업 데이터/이미지
└── logs/                                 # 로그 디렉토리
```

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-11 | PM2 좀비 프로세스 정리 (building-service, multi-unit-building-service 삭제), goldenrabbit-property.service 삭제 (property-manager.service와 중복), Shorts/VoiceRoom/PropTalk 서비스 추가, Flutter 앱 API 엔드포인트 추가, Google OAuth 설정 추가 |
| 2026-02-23 | 초기 작성 |
