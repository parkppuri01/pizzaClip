# Handoff — pizza-clip.com 모노레포 (인덱스)

> 최종 업데이트: 2026-07-05
> **이 파일은 모노레포 전체 인덱스 + 교차(공통) 컨텍스트 전용.** 각 스트림의 실제 작업 기록은 아래 각자 핸드오프에 남긴다. 여기엔 개별 스트림 세부를 넣지 않는다.

## 📍 핸드오프 5개 체계 (작업은 해당 스트림 핸드오프에 기록)

| 스트림 | 핸드오프 파일 | 진입 신호 |
|---|---|---|
| 🌐 웹 (랜딩 사이트) | [`web/HANDOFF.md`](web/HANDOFF.md) | "pizza-clip.com / 사이트 수정하자" |
| 🍕 피자클립 앱 | [`apps/pizzaclip/docs/HANDOFF.md`](apps/pizzaclip/docs/HANDOFF.md) | "피자클립 앱 …" |
| 🥒 피클 앱 | [`apps/pickle/docs/HANDOFF.md`](apps/pickle/docs/HANDOFF.md) | "피클 앱 …" |
| 🌶 핫소스 앱 | [`apps/hotsauce/docs/HANDOFF.md`](apps/hotsauce/docs/HANDOFF.md) | "핫소스 앱 …" |
| 🗂 모노레포 공통 | `handoff.md` (이 파일) | 구조·배포·크로스컷 |

**운영 규칙**
- 한 세션 = 한 스트림. 그 세션의 *마지막으로 한 일 / 다음에 할 일 / 컨텍스트* 는 **해당 스트림 핸드오프에만** 쓴다.
- 이 루트 파일엔 스트림 세부를 넣지 않는다 — 모노레포 구조·배포·비밀관리·크로스컷 이슈, 그리고 아래 "각 스트림 최근 상태" 한 줄 요약만.
- **커밋 범위도 스트림으로 좁힌다.** 다른 스트림의 미커밋 변경을 함께 커밋하지 말 것(명시적 경로 스테이징).

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
- 🌐 **웹**: 핫소스 페이지 스티커·박스 다듬기 커밋·배포 완료(`028ea03`). → `web/HANDOFF.md`
- 🍕 **피자클립 앱**: → `apps/pizzaclip/docs/HANDOFF.md`
- 🥒 **피클 앱**: **1.3.2 배포 완료**(팝업 하단 저장폴더 경로 표시 + 자동업데이트 무인설치 전환). → `apps/pickle/docs/HANDOFF.md`
- 🌶 **핫소스 앱**: **1.0.1 다듬기 진행 중·미배포**(배터리/타이틀/사이드바/아이콘 로컬빌드 완료; SSID·자물쇠·병폭발 이스터에그 남음). → `apps/hotsauce/docs/HANDOFF.md` 세션 3

## 🗒 모노레포 통합 이력
구조 통합·초기 셋업 이력은 [`task.md`](task.md) 참고.
