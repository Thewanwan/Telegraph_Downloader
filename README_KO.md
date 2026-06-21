# Telegraph Downloader

[中文](README.md) | [English](README_EN.md) | [日本語](README_JA.md)

`telegra.ph`에 게시된 이미지 앨범을 일괄 다운로드하는 크로스 플랫폼 도구입니다. Android, iOS, macOS, Windows, Linux를 지원하며 앱 내 자동 업데이트 기능을 제공합니다.

## 기능

- **멀티스레드 일괄 다운로드** — 여러 URL 입력, 2~20개 동시 스레드 설정
- **실시간 진행 상황 추적** — 앨범별 프로그레스 바, 다운로드/실패/완료 상태 표시
- **다운로드 로그** — 터미널 스타일 로그 패널, 자동 스크롤
- **다크/라이트 테마** — 원클릭 전환, 설정 자동 저장
- **다운로드 기록** — 최근 30건 저장, 원클릭 재다운로드
- **사용자 지정 저장 경로** — 폴더 선택기로 자유롭게 설정
- **자동 재시도** — 지수 백오프 기반 자동 재시도
- **앱 내 업데이트** — GitHub Releases 새 버전 자동 감지, 원클릭 다운로드 및 설치
- **클립보드 감지** — 브라우저에서 링크 복사 후 앱 실행 시 자동 붙여넣기 제안
- **설정 영속화** — 모든 설정 자동 저장, 다음 실행 시 자동 복원

## 지원 플랫폼

| 플랫폼 | 형식 | CI/CD | 상태 |
|--------|------|-------|------|
| Android | APK | GitHub Actions | ✅ 완료 |
| iOS | IPA | GitHub Actions | ✅ 완료 |
| macOS | DMG | GitHub Actions | ✅ 완료 |
| Windows | EXE | GitHub Actions | ✅ 완료 |
| Linux | DEB | GitHub Actions | ✅ 완료 |

## 다운로드

[Releases](https://github.com/Thewanwan/Telegraph_Downloader)에서 다운로드하세요.

### Android
`telegraph_x.x.x.apk` 파일을 다운로드하세요. 설치 시 "출처 불명" 허용이 필요합니다.

### Windows
`telegraph_downloader.exe`를 다운로드하여 더블 클릭으로 실행합니다.

### macOS
`.dmg` 파일을 다운로드하여 Applications로 드래그하세요. 첫 실행 시 시스템 설정 → 개인 정보 보호 및 보안에서 허용이 필요합니다.

### Linux
```bash
sudo dpkg -i telegraph-downloader_x.x.x_amd64.deb
```

## 사용 방법

### 기본 흐름
1. 입력 필드에 `telegra.ph` 링크를 붙여넣기 (줄당 하나)
2. "다운로드 시작" 탭
3. 완료 대기 — 이미지가 지정된 디렉토리에 저장

### 빠른 작업
- **클립보드 감지**: 브라우저에서 telegra.ph 링크 복사 후 앱 열면 자동 제안
- **재다운로드**: 기록의 다운로드 아이콘 탭 — 링크가 자동 입력
- **취소**: 다운로드 중 "취소" 버튼 탭

### 설정 옵션
| 옵션 | 설명 | 기본값 |
|------|------|--------|
| 저장 경로 | 이미지 저장 위치 | 외부 저장소/Downloads/TelegraphDownloader |
| 스레드 수 | 동시 다운로드 스레드 | 8 |
| 타임아웃 | 요청 타임아웃 | 15초 |
| 저장 형식 | 이미지 내보내기 형식 | 원본 |
| 품질 | JPG/WebP 압축 품질 | 95 |

## 소스에서 빌드

### 요구 사항
- Flutter SDK 3.24+
- Dart SDK 3.5+

### 설정
```bash
git clone https://github.com/Thewanwan/Telegraph_Downloader.git
cd Telegraph_Downloader
flutter pub get
flutter run
```

### 빌드 명령어
```bash
# Android (범용 APK)
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

## 프로젝트 구조

```
lib/
├── main.dart                          # 진입점 + 버전 확인
├── app/
│   ├── models/
│   │   ├── download_config.dart       # 설정 (스레드/타임아웃/형식)
│   │   ├── album_progress.dart        # 앨범 다운로드 진행 모델
│   │   └── download_result.dart       # 다운로드 결과 요약
│   └── services/
│       ├── config_service.dart        # 설정 관리 (SharedPreferences)
│       ├── download_service.dart      # 다운로드 코어 (세마포어)
│       ├── network_service.dart       # HTTP 클라이언트 (재시도/타임아웃)
│       ├── page_parser.dart           # Telegraph 페이지 파서
│       └── update_service.dart        # 앱 내 업데이트 (GitHub API)
├── pages/home/
│   └── home_page.dart                 # 메인 화면
└── widgets/                           # UI 컴포넌트
```

## 기술 스택

| 기술 | 용도 |
|------|------|
| Flutter 3.24 | 크로스 플랫폼 UI |
| Provider | 상태 관리 |
| http | HTTP 네트워킹 |
| html | 페이지 파싱 |
| path_provider | 파일 경로 해석 |
| shared_preferences | 로컬 설정 저장 |
| file_picker | 폴더 선택기 |
| open_file | APK 설치 프로그램 실행 |

## 네트워크 참고사항

`telegra.ph`에 접근하려면 프록시가 필요합니다.

| 플랫폼 | 해결 방법 |
|--------|-----------|
| Android | VPN 또는 프록시 지원 Wi-Fi |
| iOS | 프록시 지원 VPN |
| Windows | 전역 프록시 또는 natapp 등의 전달 도구 |
| macOS | 시스템 프록시 활성화 |
| Linux | `http_proxy` 환경 변수 설정 |

## 라이선스

[GNU General Public License v3.0](LICENSE)
