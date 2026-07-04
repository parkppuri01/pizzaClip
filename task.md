# Task — pizza-clip.com 모노레포

> 스트림별 진행/할일은 각 핸드오프에 기록 (→ [`handoff.md`](handoff.md) = 5개 핸드오프 인덱스).
> 이 파일은 **모노레포 통합·공통 태스크**만 다룬다.

## 목표
세 개의 macOS 앱(pizzaclip, pickle, hotsauce) + 공용 웹사이트(pizza-clip.com)를
`pizza-clip.com/` 모노레포 한 곳으로 통합하고, GitHub 단일 repo(pizzaClip.git)로 관리한다.

## 완료 — 모노레포 통합 (2026-07 초)
- [x] 구조 결정·파일 이동: `web/` 최상위 + `apps/{pizzaclip,pickle,hotsauce}/`, 기존 `.git` 이동으로 이력·리모트 그대로 보존
- [x] .gitignore 정리(서명키·디자인원본·대용량 영상·.omc 커밋 제외) + 릴리스 스크립트 appcast 경로 모노레포화
- [x] 루트 README(모노레포 안내) 작성, 안전 스캔(서명키·node_modules·대용량 영상 미커밋 확인)
- [x] master 커밋(`7f4bfd3`) + origin/master push, 검증(web build 9페이지 · 앱3개 xcodegen generate)
- [x] **핸드오프 5개 체계 확립** — 루트 인덱스 + `web/` + 3앱 각자. 각 스트림 작업은 자기 핸드오프에 기록

## 스트림별 릴리스 이력 (요약 · 상세는 각 핸드오프)
- 🌶 **핫소스**: 웹 신설 + 앱 1.0.0 첫 공식배포(`516d1e4`) → 웹 다듬기(`09743c1`·`028ea03`) 완료 → 앱 1.0.1 다듬기 진행 중(미배포). 상세 `apps/hotsauce/docs/HANDOFF.md`
- 🥒 **피클**: 1.3.2 배포(팝업 하단 저장폴더 경로 표시 + 자동업데이트 무인설치). 상세 `apps/pickle/docs/HANDOFF.md`
- 🍕 **피자클립** / 🌐 **웹**: 상세 `apps/pizzaclip/docs/HANDOFF.md` · `web/HANDOFF.md`

## 남은 일 (모노레포 공통 · 사용자 확인 후)
- [ ] 원본 3개 백업 폴더 삭제 — `../pizzaClip`·`../pic.kle`·`../hotsauce` (~3.5GB, 며칠 실사용 검증 후)
- [ ] (선택) GitHub repo 이름 `pizzaClip` → `pizza-clip` 변경
