# Handoff — pizza-clip.com 모노레포 (인덱스)

> 최종 업데이트: 2026-08-14 · **이 파일 = 모노레포 인덱스 + 공통 컨텍스트.** 개별 스트림 세부는 각 스트림 핸드오프에.

> 🔗 **크로스컷 (2026-07-09): 세 앱 설정창 '일반' 탭 통일 + 정식 배포 3종 동시 진행.** 설정창을 피클 크기(500×420) 기준으로 통일 — 공통 일반 탭(아이콘·이름·버전 헤더 + 언어 세그먼트 + 자동 다운로드 업데이트 토글[기본 ON] + '지금 업데이트 확인'). 피클·핫소스의 자동다운로드 강제코드를 제거해 실효 토글화. 이어서 **피자 1.3.1 · 피클 1.3.3 · 핫소스 1.1.2 정식 공증 배포**까지 완료(아래 각 스트림 상태). 계획서: `.omc/plans/settings-unification.md`. 언어 방식은 사용자 결정 A(피클=실시간, 피자·핫소스=재시작 유지).

## ⭐ 모든 세션 필독 — 작업 규칙

> 이 저장소는 **스트림별로 세션을 분리**해 운영한다. 어느 세션이든(사람이든 에이전트든) 시작 전에 아래 5개를 지킨다.

1. **한 세션 = 한 스트림.** 사용자가 지정한 스트림(🌐 웹 · 🍕 피자클립 · 🥒 피클 · 🌶 핫소스) **하나만** 작업한다. 한 세션에서 여러 스트림을 섞지 않는다.
2. **세션 시작 = 인덱스 → 스트림 핸드오프.** 이 루트 `handoff.md`를 먼저 읽어 위치를 잡고, 해당 스트림 핸드오프(아래 표)로 이동해 최신 상태를 파악한 뒤 시작한다.
3. **작업 기록은 그 스트림 핸드오프에만.** *마지막으로 한 일 / 다음에 할 일 / 컨텍스트* 는 전부 스트림 핸드오프에 쓴다. 이 루트 파일엔 **스트림 세부 금지** — 모노레포 공통(구조·배포·비밀·크로스컷)과 "각 스트림 최근 상태" 한 줄 요약만.
4. **커밋은 스트림 범위로 좁힌다.** `git add`는 **명시적 경로**로만 하고, 커밋 전 `git status`로 스테이징 범위를 확인한다. **다른 스트림의 미커밋 변경은 절대 함께 커밋하지 않는다** — 작업 트리엔 타 스트림 WIP가 흔히 공존한다.
5. **세션 끝(랩업) = 스트림 핸드오프 갱신 + 루트 한 줄.** 그 스트림 핸드오프에 이번 세션을 기록하고, 이 루트의 "각 스트림 최근 상태" 해당 줄과 상단 날짜만 손댄다(루트에 세부를 붙이지 않는다).

## 📍 핸드오프 5개 체계

| 스트림 | 핸드오프 파일 | 진입 신호 |
|---|---|---|
| 🌐 웹 (랜딩 사이트) | [`web/HANDOFF.md`](web/HANDOFF.md) | "pizza-clip.com / 사이트 수정하자" |
| 🍕 피자클립 앱 | [`apps/pizzaclip/docs/HANDOFF.md`](apps/pizzaclip/docs/HANDOFF.md) | "피자클립 앱 …" |
| 🥒 피클 앱 | [`apps/pickle/docs/HANDOFF.md`](apps/pickle/docs/HANDOFF.md) | "피클 앱 …" |
| 🌶 핫소스 앱 | [`apps/hotsauce/docs/HANDOFF.md`](apps/hotsauce/docs/HANDOFF.md) | "핫소스 앱 …" |
| 🗂 모노레포 공통 | `handoff.md` (이 파일) | 구조·배포·크로스컷 |

## 🗺 저장소 한눈에
- 구성: `web/`(Astro 공용 사이트) + `apps/{pizzaclip,pickle,hotsauce}/`(각 macOS Swift 앱, XcodeGen `project.yml` 기반).
- Git remote: `origin` = `github.com/parkppuri01/pizzaClip.git` (폴더명은 pizza-clip 이지만 repo 명은 **pizzaClip**).
- 원본 백업 보존 중: `../pizzaClip`·`../pic.kle`·`../hotsauce` (총 ~3.5GB). 며칠 실사용 후 문제없으면 삭제 예정.

## 🚀 배포 모델
- **웹**: `master` push → **Vercel 자동배포**. 배포 전 `cd web && npm run build` 통과 확인. (미들웨어 언어분기는 Vercel에서만 동작 → 배포 후 실기 확인.)
- **앱(공통 절차)**: `project.yml` 버전·빌드 ↑ → `xcodegen generate` → `scripts/release-test-dmg.sh`(Developer ID 서명 + Apple 공증 + staple, 앱·DMG 2회 라운드) → `scripts/sparkle-appcast.sh`(EdDSA appcast, `DOWNLOAD_BASE_URL=https://pizza-clip.com/<앱>`) → DMG+appcast 를 `web/public/<앱>/` 에 복사 → **사이트 다운로드 링크 + 릴리스노트 갱신** → 커밋 → master push. 앱별 함정·상세는 각 앱 핸드오프.
- 버전 규칙: 정식 배포 = 둘째자리(minor) ↑, 테스트 빌드 = 셋째자리(patch) ↑. 빌드마다 사용자에게 번호 알림.
- ⚠️ **웹 릴리스 시 2곳 잊지 말 것**: (a) 다운로드 버전(`web/src/consts.ts` `*_DOWNLOAD_URL` + 각 `*Page.astro` `softwareVersion`) (b) 릴리스노트(`web/src/i18n/info.ts`). appcast(자동업데이트)와 (a)(b)는 서로 별개.

## 🔐 비밀/자격 (커밋 금지 · gitignore)
- 서명 식별자: 각 앱 `Signing.xcconfig` (팀ID·Developer ID). 템플릿 `Signing.xcconfig.example` 복사.
- 배포 자격: 각 앱 `scripts/release.local.sh` (Apple 공증 notary keychain 프로파일 등). 템플릿 `*.example` 복사.

## ⏳ 모노레포 공통 남은 일 (스트림 무관)
- [ ] 원본 3개 백업 폴더 삭제 — `../pizzaClip`·`../pic.kle`·`../hotsauce` (실사용 검증 후).
- [ ] (선택) GitHub repo 이름 `pizzaClip` → `pizza-clip` 변경.

## 📌 각 스트림 최근 상태 (한 줄 · 상세는 각 핸드오프)
- 🌐 **웹**: 인포 릴리스노트 '더보기' 버튼 3컬럼 통합 + 피클 안내 카드 제거 배포 완료(`8b03255`). (직전: 세 앱 릴리스 반영 `8c26ea1`·`27d16a2`.) → `web/HANDOFF.md`
- 🍕 **피자클립 앱**: **1.3.1 정식 배포 완료**(설정창 일반 탭 3앱 통일 + 자동 업데이트 토글 + 기록개수→저장공간 이동). GitHub 릴리스 v1.3.1·루트 appcast 라이브. → `apps/pizzaclip/docs/HANDOFF.md`
- 🥒 **피클 앱**: **1.4.0 정식 배포 완료**(스크롤 캡처 **베타** 공개 — 브라우저 자동 + 수동 스티칭 하이브리드). 공증 DMG·appcast 라이브. 브라우저 모드 배율 ~2배 오차가 다음 릴리스 1순위. → `apps/pickle/docs/HANDOFF.md`
- 🌶 **핫소스 앱**: **1.2.0 공증 배포 완료**(팝업 사이트 배너 + 푸터 여유 + 설정 방침 링크, `bf02a7e`) + **앱스토어 1.2.0(빌드7) 업로드 완료** — 남은 건 App Store Connect 메타데이터·스크린샷·심사 제출. 웹 `/privacy` 신설·라이브. → `apps/hotsauce/docs/HANDOFF.md`

## 🗒 모노레포 통합 이력
구조 통합·초기 셋업 이력은 [`task.md`](task.md) 참고.
