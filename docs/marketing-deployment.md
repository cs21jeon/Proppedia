# 마케팅 파일 배포 가이드

## 배포 현황 (2026-02-22 업데이트)

| URL | 설명 | 상태 |
|-----|------|------|
| https://goldenrabbit.biz/proppedia/ | 앱 소개 랜딩 페이지 | ✅ 완료 |
| https://goldenrabbit.biz/proppedia-app/ | Flutter Web 앱 | ✅ 완료 |
| https://goldenrabbit.biz/robots.txt | 크롤링 규칙 | ✅ 완료 |
| https://goldenrabbit.biz/sitemap.xml | 사이트맵 | ✅ 완료 |

### 랜딩 페이지 업데이트 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-02-20 | 최초 배포 (앱 미리보기, 기능 소개) |
| 2026-02-22 | 섹션 분리 및 PDF 기능 추가 |

### 2026-02-22 업데이트 내용
- **앱 미리보기 섹션** (6개 이미지): 홈, 도로명/지번/지도 검색, 검색 결과
- **편리한 부가 기능 섹션** (5개 이미지): 검색기록, 즐겨찾기, 카카오톡 공유, PDF 결과물 미리보기, PDF 인쇄/저장
- PDF 이미지 높이 통일 (280px)
- 회원가입/로그인 유도 문구 추가

## 파일 구조

```
marketing/
├── proppedia/
│   └── index.html          # 앱 소개 랜딩 페이지
├── blog-content/
│   ├── 01-건축물대장-보는-법.md
│   └── 02-공시지가-조회하기.md
├── robots.txt              # 검색 엔진 크롤링 규칙
├── sitemap.xml             # 사이트맵
├── deploy.ps1              # PowerShell 배포 스크립트
└── deploy.sh               # Bash 배포 스크립트

screenshots/                 # 랜딩 페이지 이미지
├── 01_home.png             # 홈 화면
├── 02_road_search.png      # 도로명 검색
├── 03_jibun_search.png     # 지번 검색
├── 04_result_1.png         # 검색 결과 1
├── 05_result_2.png         # 검색 결과 2
├── 06_map_search.png       # 지도 검색
├── 07_history.png          # 검색기록
├── 08_favorites.png        # 즐겨찾기
├── KakaoTalk_20260221_232554552.jpg  # 카카오톡 공유
├── print pdf 001.png       # PDF 결과물 미리보기
└── print pdf 002.png       # PDF 인쇄/저장
```

## 서버 배포

### 1. SSH 접속

```bash
ssh root@175.119.224.71
# 또는
ssh -i ~/.ssh/id_rsa root@175.119.224.71
```

### 2. 디렉토리 생성

```bash
# 프로필 디렉토리 생성
mkdir -p /home/webapp/goldenrabbit/frontend/public/proppedia
mkdir -p /home/webapp/goldenrabbit/frontend/public/proppedia/screenshots
```

### 3. 파일 업로드

로컬에서 실행:

```bash
# 랜딩 페이지 업로드
scp marketing/proppedia/index.html root@175.119.224.71:/home/webapp/goldenrabbit/frontend/public/proppedia/

# robots.txt 업로드
scp marketing/robots.txt root@175.119.224.71:/home/webapp/goldenrabbit/frontend/public/

# sitemap.xml 업로드
scp marketing/sitemap.xml root@175.119.224.71:/home/webapp/goldenrabbit/frontend/public/

# 스크린샷 업로드
scp screenshots/*.png root@175.119.224.71:/home/webapp/goldenrabbit/frontend/public/proppedia/screenshots/

# 로고 업로드
scp assets/images/proppedia_logo.png root@175.119.224.71:/home/webapp/goldenrabbit/frontend/public/proppedia/logo.png
```

### 4. OG 이미지 생성 및 업로드

OG 이미지는 1200x630 크기가 권장됩니다. Feature Graphic을 기반으로 생성하거나:

```bash
# Feature Graphic 업로드 (임시 OG 이미지로 사용)
scp "screenshots/Feature Graphic_proppedia.png" root@175.119.224.71:/home/webapp/goldenrabbit/frontend/public/proppedia/og-image.png
```

### 5. 권한 설정

```bash
# 서버에서 실행
chown -R www-data:www-data /home/webapp/goldenrabbit/frontend/public/proppedia
chmod -R 755 /home/webapp/goldenrabbit/frontend/public/proppedia
```

### 6. Nginx 설정 확인

```bash
# nginx 설정 확인
cat /etc/nginx/sites-available/goldenrabbit.conf

# 필요시 설정 추가
# location /proppedia/ {
#     try_files $uri $uri/ /proppedia/index.html;
# }

# nginx 재시작
systemctl reload nginx
```

## Flutter Web 배포

### 1. 빌드

```bash
cd C:\Users\ant19\projects\propedia
flutter build web --base-href "/proppedia-app/"
```

### 2. 업로드

```bash
# 빌드 폴더 업로드
scp -r build/web/* root@175.119.224.71:/home/webapp/goldenrabbit/frontend/public/proppedia-app/
```

## 검증 체크리스트

- [x] https://goldenrabbit.biz/proppedia/ 접속 확인 ✅
- [x] https://goldenrabbit.biz/proppedia-app/ 접속 확인 ✅
- [x] https://goldenrabbit.biz/robots.txt 확인 ✅
- [x] https://goldenrabbit.biz/sitemap.xml 확인 ✅
- [ ] [Google Mobile-Friendly Test](https://search.google.com/test/mobile-friendly)
- [ ] [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)
- [ ] [Google Rich Results Test](https://search.google.com/test/rich-results)
- [x] Google Search Console 소유권 확인 ✅
- [x] Google Search Console sitemap 제출 ✅
- [x] /proppedia/ 색인 생성 요청 ✅
- [x] 네이버 서치어드바이저 소유 확인 ✅
- [x] 네이버 사이트맵 제출 ✅

## Google Search Console 설정

### 소유권 확인 (2026-02-21 완료)

**중요**: 도메인은 가비아에서 구매했지만, 네임서버가 **Cafe24**로 설정되어 있음
- 가비아 DNS 설정이 아닌 **Cafe24 DNS 관리**에서 TXT 레코드 추가해야 함

| 항목 | 값 |
|-----|-----|
| 타입 | TXT |
| 호스트 | @ |
| 값 | google-site-verification=XXXXX... |
| TTL | 600 |

### 설정 단계

1. https://search.google.com/search-console 접속
2. 속성 추가: https://goldenrabbit.biz (도메인 방식)
3. DNS TXT 레코드 추가 (Cafe24에서)
4. 소유권 확인
5. sitemap.xml 제출
6. URL 검사로 /proppedia/ 색인 요청

## 네이버 서치어드바이저 설정

### 소유권 확인 (2026-02-21 완료)

**방법**: 메타 태그 방식
- 메인 사이트 index.html `<head>`에 추가:
```html
<meta name="naver-site-verification" content="f6c69bda05f863b019372bd73f7634bd863df399" />
```

**대시보드**: https://searchadvisor.naver.com/console/board

### 사이트맵 제출 완료
- 요청 → 사이트맵 제출 → `https://goldenrabbit.biz/sitemap.xml`

### 웹페이지 수집 요청 완료
- `https://goldenrabbit.biz`
- `https://goldenrabbit.biz/proppedia/`

---

## 문제 해결

### 404 에러
- nginx 설정에서 location 블록 확인
- 파일 권한 확인

### OG 태그가 표시되지 않음
- Facebook Debugger에서 캐시 삭제
- og:image URL이 절대 경로인지 확인

### 이미지가 표시되지 않음
- 이미지 파일 권한 확인
- 경로가 올바른지 확인
