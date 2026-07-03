# PIZZA CLIP — 인트로 영상 디자인 기준

브랜드 출처: `web/src/styles/tokens.css` 의 실제 토큰. 영상은 "심플하면서 고급스러운"(애플 제품 인트로 톤) — 여백을 크게, 한 박자에 한 메시지, 절제된 모션. 피자 위트는 정밀한 액센트로만.

## Palette (hex — 그대로 사용, 새 색 금지)

| 용도 | 이름 | hex |
| --- | --- | --- |
| 캔버스(배경) | 크림 | `#FCF6EF` |
| 헤드라인 | 네이비 잉크 | `#102138` |
| 본문 | 차콜 | `#333333` |
| 포인트/CTA | 벽돌 빨강 | `#A2371F` |
| 강조/메뉴 | 피자 옐로우 | `#FFB703` |
| 치즈(일러스트) | 라이트 옐로우 | `#F4C84B` |
| 페퍼로니 | 페퍼로니 레드 | `#E0492B` |
| 보조 틴트 | peach / coral / green | `#F2BC7E` / `#F1765C` / `#468365` |

크러스트/아웃라인: 잉크 네이비 `#102138` (브랜드 히어로의 굵은 검정 외곽선 대용, 약간 따뜻하게).

## Typography

- **OSP-DIN** (condensed) — 영문 디스플레이: `PIZZA CLIP`, `⌘C`, 숫자(01/02/03). woff2 `fonts/OSP-DIN.woff2`.
- **Pretendard** — 한글 헤드라인·본문. Black/ExtraBold=헤드라인, SemiBold/Medium=라벨, Regular=본문. `fonts/Pretendard-*.woff2`.
- **리디바탕(RIDIBatang)** — 필요 시 에디토리얼 한 줄. `fonts/RIDIBatang.woff2`.

타입 스케일(영상): 헤드라인 110–150px / 서브 36–46px / 라벨·모노 22–28px / 숫자 120–200px.

## Motion

- 진입은 전부 `fromTo`(결정적). 나가는 모션은 마지막 씬에서만.
- 씬 전환 = 들어오는 씬 컨테이너를 위에서 페이드인(+blur/scale 살짝). 크로스페이드 중심, 절제.
- 이즈 다양화(씬당 3종+), 속도 대비(피크 씬 빠르게 / 오프닝·클로징 느리게).
- 앰비언트 모션은 장식 요소에만 1개씩(유한 repeat+yoyo). 콘텐츠는 정지 = 고급.

## Do / Don't

- DO: 크림 여백, 굵은 2px+ 외곽선, 풀세추레이션 액센트 한 점, 미세 그레인·크롭마크로 "제작된" 질감.
- DON'T: 웹 콜라주처럼 색 띠 4개 동시 사용 금지(영상은 절제), 5%대 불투명 글로우 금지, 같은 이즈 반복 금지, `<br>` 강제개행 금지(자연 wrap), Math.random/Date.now 금지.

## 자산

- `assets/app-icon.png` — "I'm a PizzaClip" 클립보드 앱 아이콘(클로징).
- `assets/mascot-hi.png` — 인사하는 피자 마스코트(클로징 액센트).
- `assets/badge-round.png` — PIZZA CLIP 원형 뱃지(완성 스탬프 후보).
- `assets/menubar-icon.png` — 실제 macOS 메뉴바 아이콘.
- 피자 조각/키캡/자물쇠 등은 브랜드 외곽선 스타일로 인라인 SVG 작도(애니메이션 제어용).
