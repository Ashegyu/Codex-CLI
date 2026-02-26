# CLI Chat 폴더 분석 및 사용법

## 1) 폴더 한눈에 보기

기준 경로: `C:\Users\GC\Desktop\업무\JGKim\Claude CLI`

현재 폴더는 **Electron 기반 데스크톱 CLI 채팅 앱** 프로젝트입니다.  
핵심 구조는 `main.js`(메인 프로세스) + `preload.js`(보안 브리지) + `renderer/`(UI)입니다.

상위 폴더 주요 항목:

- `.claude/`: 로컬 에이전트 권한/설정 (`settings.local.json`)
- `assets/`: 정적 리소스 폴더 (현재 파일 없음)
- `renderer/`: 프론트엔드 UI (`index.html`, `app.js`, `styles.css`)
- `main.js`: Electron 메인 프로세스, PTY/IPC/윈도우/스토리지 처리
- `preload.js`: renderer에 노출할 안전한 API(`window.electronAPI`) 정의
- `package.json`: 실행/빌드 스크립트, 의존성, electron-builder 설정
- `context-menu-install.reg`, `context-menu-uninstall.reg`: Windows 우클릭 메뉴 등록/해제
- `dist-temp8/`: 최근 빌드 산출물 (설치 파일 + unpacked 앱)
- `node_modules/`: 의존성 모듈

파일 통계 요약:

- 전체 추적 파일: 약 82개
- `renderer/`: 3개 파일, 약 158KB
- `dist-temp8/`: 311개 파일, 약 389MB

참고:

- `README.md` 없음
- `scripts/verify.ps1` 없음 (문서상 언급 대비 실제 파일 미존재)

---

## 2) 아키텍처 분석

### 실행 구조

1. `npm run start` 실행
2. Electron이 `main.js` 진입
3. `BrowserWindow` 생성 후 `renderer/index.html` 로드
4. Renderer(`renderer/app.js`)가 `window.electronAPI`를 통해 메인 프로세스 IPC 호출
5. `node-pty`로 `codex` CLI를 실행하고 스트림을 UI에 반영

### 역할 분리

- `main.js`
  - 앱/창 라이프사이클
  - CLI(PTY) 실행/중지/입력 전달
  - CWD 설정, 파일 읽기, Codex rate limit 조회
  - 대화 저장/로드(`conversations.json`)
- `preload.js`
  - IPC 채널을 안전하게 브리지
  - `cli`, `cwd`, `file`, `window`, `codex`, `store`, `system` API 노출
- `renderer/app.js`
  - 대화 렌더링, 스트리밍 UI
  - 히스토리/프로필/런타임 옵션 관리
  - 슬래시 명령어, 파일 불러오기, 단축키 처리

### IPC 핵심 채널

- `cli:run`, `cli:write`, `cli:stop`
- `cli:stream`, `cli:done` (메인 → 렌더러 이벤트)
- `cwd:get`, `cwd:set`, `cwd:select`
- `file:pickAndRead`, `file:read`
- `window:minimize`, `window:maximize`, `window:close`, `window:maximized`
- `codex:rateLimits`
- `store:loadConversations`, `store:saveConversations`, `store:saveConversationsSync`
- `system:info`

---

## 3) 실행/빌드 방법

## 사전 조건

- Windows 환경 (현재 구현은 Windows 실행 가정)
- Node.js + npm 설치
- `codex` CLI 설치 및 PATH 등록

## 로컬 실행

```bash
npm install
npm run start
```

## 빌드

```bash
npm run build
npm run build:portable
```

- `build`: NSIS 설치형(기본 `dist/`)
- `build:portable`: 포터블 빌드

현재 폴더에는 `dist-temp8/`에 최근 빌드 결과가 있으며, 예시 설치 파일:

- `dist-temp8/CLI Chat Setup 1.0.0.exe`

---

## 4) 앱 사용법 (사용자 기준)

## 기본 사용 흐름

1. 앱 실행 후 좌측에서 새 대화 생성 또는 기존 기록 선택
2. 작업 폴더(CWD) 지정 (`작업 폴더 버튼` 또는 `/cwd`)
3. 입력창에 질문 작성 후 `Enter` 전송
4. 답변 스트리밍 중 추가 입력은 프로세스 stdin으로 전달
5. 필요 시 `중지 버튼` 또는 `Esc`로 중단

## 입력 규칙

- 일반 텍스트: 바로 질문 전송
- `/...`: 슬래시 명령어 처리
- `@경로`: 파일 내용을 읽어 입력창 프롬프트로 가져오기
- `·`(중점)는 입력 프리픽스가 아니라 UI 안내 구분자

## 단축키

- `Enter`: 전송
- `Shift+Enter`: 줄바꿈
- `Esc`: 메뉴 닫기 또는 실행 중 스트림 중지
- `Ctrl+N`: 새 대화
- `Ctrl+L`: 입력창 포커스
- `/` 입력 중 슬래시 메뉴:
  - `ArrowUp/ArrowDown`: 항목 이동
  - `Tab`: 선택 명령어 자동 입력

## 런타임 옵션

- 모델(`model`)
  - `GPT-5.3-Codex` (기본)
  - `GPT-5.2-Codex`
  - `GPT-5.1-Codex-Max`
  - `GPT-5.2`
  - `GPT-5.1.Codex-Mini`
- Reasoning effort
  - `low`, `medium`, `high`, `extra high` (기본: `extra high`)
- Sandbox
  - `workspace-write` (기본)
  - `read-only`
  - `danger-full-access`

## 슬래시 명령어

로컬 처리 명령:

- `/help` 명령 목록 표시
- `/status` 5h/weekly limit 갱신
- `/file [경로]` 파일 불러오기 (인자 없으면 파일 선택창)
- `/cwd [경로]` 작업 폴더 변경
- `/model [모델명]` 모델 변경
- `/reasoning [값]` reasoning effort 변경
- `/sandbox [모드]` sandbox 변경
- `/clear` 현재 대화 초기화

Codex 서브커맨드 실행 명령:

- `/search [질문]`
- `/review [지시]`
- `/review-base [브랜치] [지시]`
- `/review-commit [SHA]`
- `/apply [task-id]`
- `/resume [session-id]`
- `/fork [session-id]`
- `/mcp-list`
- `/mcp-add [이름] [--url URL | -- 명령어]`
- `/mcp-remove [이름]`
- `/cloud-exec --env [ENV] [질문]`
- `/cloud-list [--env ENV]`
- `/cloud-status [task-id]`
- `/cloud-diff [task-id]`
- `/cloud-apply [task-id]`
- `/features`
- `/version`
- `/login`
- `/logout`

참고: 인식되지 않은 `/명령`은 로컬에서 소비하지 않고 일반 메시지 경로로 처리될 수 있습니다.

---

## 5) 데이터 저장 위치

- 대화 기록: Electron `userData` 경로의 `conversations.json`
- renderer localStorage:
  - 최근 CWD
  - 런타임 옵션(모델/리즈닝/샌드박스)
  - Codex 사용량 스냅샷 관련 값

---

## 6) Windows 컨텍스트 메뉴 연동

등록:

1. `context-menu-install.reg` 실행
2. 폴더 우클릭 메뉴에서 `CLI Chat으로 열기` 사용

해제:

1. `context-menu-uninstall.reg` 실행

주의:

- 기본 실행 파일 경로가 `%LOCALAPPDATA%\Programs\cli-chat-app\CLI Chat.exe`로 지정되어 있으므로, 실제 설치 경로가 다르면 `.reg` 내용 수정 필요

---

## 7) 현재 폴더 상태에서 주의할 점

- 작업 트리가 이미 변경되어 있음:
  - `.claude/settings.local.json`, `.gitignore`, `main.js`, `preload.js`, `renderer/app.js`, `renderer/styles.css` 수정 상태
  - `dist-temp8/` 미추적
- `.gitignore`에는 `dist-temp/`만 있고 `dist-temp8/`은 제외 규칙이 없음
- `node-pty`는 Electron 버전에 따라 재빌드가 필요할 수 있음
- Codex rate limit 표시는 `~/.codex/sessions` 로그가 있어야 정상 동작

---

## 8) 권장 정리 작업

1. 문서 표준화: `README.md` 신설 또는 본 문서 링크
2. 산출물 정리: `dist-temp*` 패턴 `.gitignore` 반영
3. 검증 스크립트 정리: 실제 `scripts/verify.ps1` 도입 또는 문서에서 제거
4. 릴리즈 체크리스트에 `context-menu-install.reg` 경로 검증 추가

