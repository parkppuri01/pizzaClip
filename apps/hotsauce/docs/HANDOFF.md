# HotSauce — HANDOFF

세션 단위 역순 기록. 형제 프로젝트(pizzaClip, PicKle) 관행과 동일.

---

## 세션 12 — 2026-08-26: 🍎 앱스토어 라이브 → 직접배포 **마지막 배포 완료** · 채널 마감 시작

### 마지막으로 한 일
- **앱스토어 출시 확인** — `HotSauce - System Monitor` 1.3.0, 무료, macOS 13+, **2026-08-25 라이브**(iTunes lookup API 로 확인). 세션 11 에서 제출한 빌드9 가 심사를 통과했다.
- **직접배포 1.3.0(빌드10) 공증 배포 완료** = 계획대로 **직접배포 채널의 마지막 버전**. 커밋 `f31dd39` → master push → 프로덕션 검증 통과.
  - appcast 1.3.0/빌드10 · DMG 200(3,593,782B, appcast length 와 일치) · 페이지 CTA 2곳 App Store · `/info` 릴리스노트 한/영 · JSON-LD downloadUrl 도 스토어.
  - 웹 `/en/hotsauce` 가 307 로 뜨는 건 **미들웨어 언어분기의 정상 동작**이다(한국 IP → 한국어). `/en/pickle` 도 같다. 영어 사용자로 접속하면 200 + `/us/` 링크가 나온다.
- **이전 안내를 3곳에 심었다** — 도달 경로가 마땅치 않아서다. Sparkle 자동 다운로드가 기본 ON 이라 릴리스노트를 지나칠 수 있고, 팝업 배너는 설정에서 끌 수 있다.
  1. **실행 시 1회 안내 창**(`AppStoreMigration`) — 앱을 켜면 반드시 지나가는 유일한 경로. [나중에] / [App Store에서 받기].
  2. **설정창 상단 상설 안내** — 1회 창을 놓친 사용자용. 창 420→530.
  3. **Sparkle 릴리스노트 + 웹 릴리스노트**.
- **버튼은 `macappstore://` 로 App Store 앱을 직접 연다.** 스토어 국가는 앱 언어로 kr/us 분기.
- 릴리스 도구: `sparkle-appcast.sh` 가 릴리스노트의 `[텍스트](주소)` 를 링크로 변환하게 했다 — 이제 Sparkle 노트에서 스토어로 바로 갈 수 있다.
- 미결이던 커밋 판단 2건 해소: `dist/` 커밋 시작(피클과 파리티) · `images/` 48MB gitignore.

### 🔬 이번에 실측으로 확정한 것 — 이전은 실제로 이렇게 일어난다

**앱 파일은 자동으로 대체된다.** 양쪽 다 `HotSauce.app` 이고 App Store 도 `/Applications` 에 설치하므로 같은 자리를 덮어쓴다. 이 맥이 실제 사례다 — 세션 11 에서 설치한 직접배포 1.3.0 이 8/25 10:43 App Store 판으로 바뀌었고 **휴지통에 흔적이 없었다**(수동 삭제가 아니라 덮어쓰기).
→ 그래서 "옛 앱을 지우라"고 안내하지 **않는다.** 지울 게 없다.

**대신 재실행을 안내한다.** 파일이 교체돼도 메모리에 뜬 옛 프로세스는 계속 산다. 그 상태에서 새 앱을 실행하면 macOS 가 "이미 실행 중"으로 보고 안 띄워서, 사용자는 *"설치했는데 그대로네?"* 가 된다. **옛 앱을 `/Applications` 밖에 두고 쓴 사용자는 진짜로 병이 두 개 뜬다.**

**설정은 넘어가지 않는다.** 샌드박스라 저장 위치가 갈린다 — 직접배포판 `~/Library/Preferences/com.Team-jAm.HotSauce.plist` ↔ App Store 판 `~/Library/Containers/com.Team-jAm.HotSauce/`. 두 경로 다 이 맥에 실재함을 확인했다.

### 다음에 할 일
1. **직접배포 채널 마감 마무리 시점 결정** — appcast 와 DMG 는 **당분간 그대로 둔다.** 내리면 아직 구버전을 쓰는 사용자의 Sparkle 확인이 404 로 실패해 "마지막 안내"조차 못 받는다. 충분히 이전됐다고 판단되면 그때 정리.
2. **앱스토어 업데이트를 낼 일이 생기면 빌드 11 부터.** 빌드 10 은 직접배포에 소진됐다.
3. (이월) 폭발 파티클 전용 아트 · 옛 `HotSauce-1.0.0.dmg` 정리 · Pretendard `OFL.txt` 사본 · `PrivacyInfo.xcprivacy`.
4. (다른 스트림) 피클 앱 번들의 `.omc` 잡파일 — 세션 9 에서 발견했으나 스트림이 달라 손대지 않음.

### 주의사항 / 컨텍스트 — 이번에 실제로 막혔던 것들

- **🚨 이 앱에서 `NSAlert.runModal()` 은 쓰면 안 된다.** 창은 화면에 보이는데 **버튼이 눌리지 않는다**(사용자 실기기 확인 — 두 버튼 다 무반응). LSUIElement(`.accessory`) 앱이라 모달 세션이 제대로 서지 않는 것으로 보인다.
  - 같은 창이 `CGWindowList` 와 `screencapture` 에도 안 잡혔다. **전부 같은 원인의 증상이다.**
  - 처방: 설정 창이 쓰는 **`NSWindow` + `makeKeyAndOrderFront`** 경로. 이쪽은 실제 배포로 오래 검증됐다.
  - ⚠️ **교훈**: "창이 보인다"는 말과 "정상 동작한다"는 말은 다르다. 이번에 그걸 같은 뜻으로 읽고 NSAlert 로 되돌렸다가 한 바퀴 돌았다.
- **🚨 `NSWindow.center()` 도 이 앱에선 못 믿는다.** SwiftUI 레이아웃이 확정되기 전에 계산돼 창이 **화면 밖(y ≈ -1049)** 에 놓였다. 설정 창이 멀쩡한 이유는 거기선 `setContentSize` 로 크기를 못 박기 때문이다.
  - 처방: 크기를 먼저 확정(`layoutSubtreeIfNeeded` + `setContentSize(fittingSize)`)하고, **창을 표시한 "뒤"** 에 화면 좌표를 직접 계산해 배치(화면 안으로 클램프). 표시 전에만 잡으면 표시 직후 레이아웃이 한 번 더 돌면서 또 어긋난다.
- **🚨 `https://apps.apple.com/…` 를 열면 App Store 가 아니라 브라우저가 뜬다.** 거기서 "Mac App Store에서 보기"를 한 번 더 눌러야 한다 — 한 클릭이면 될 일이 세 클릭이 된다.
  - 처방: **`macappstore://apps.apple.com/…`** — LaunchServices 에 `/System/Applications/App Store.app` 으로 등록돼 있어 곧장 열린다(`itms-apps://` 도 같다). 실패 시 https 폴백.
- **App Store 로 설치된 앱은 `/Applications` 에서 덮어쓸 수 없다** — `root:wheel` 소유라 `rm`·`ditto` 가 전부 Permission denied 다. 직접배포판을 테스트하려면 **바탕화면 등 다른 경로**에 두고 실행하면 된다(설정 저장 위치가 컨테이너로 갈려 있어 서로 간섭하지 않는다).
- **스토어 URL 에 국가 코드를 반드시 넣는다.** 미국·한국 2개국에만 출시해서, 국가 없는 주소(`/app/id…`)는 미출시 지역에서 "사용할 수 없음"이 뜬다. `mt=12` 는 Mac App Store 지정.
- 설정창 530 은 **안내 박스가 먹는 92pt 를 420 에 더한 값**이다. 원본(420)과 나란히 렌더해 폼 가시 영역이 같은지 대조했다. '업데이트' 섹션이 스크롤해야 보이는 건 420 시절부터 그랬다.
- 안내 표시 여부는 `didShowAppStoreMigrationNotice`(UserDefaults). **테스트로 이 키가 박히면 실기기에서 안내가 안 뜬다** — 확인 후 `defaults delete` 로 지울 것.

---

## 세션 11 — 2026-08-15: 아이콘 macOS 규격화 + 배너 토글 + 1.3.0 앱스토어 **심사 제출 완료** 🎉

### 마지막으로 한 일
- **🍎 App Store 심사 제출 완료.** 1.3.0(빌드9) · 무료 · 미국/대한민국 2개국.
- **앱 아이콘 macOS 규격화** (세션 10의 이월 항목 해소) — 1024 꽉 찬 iOS식 → **824×824 연속곡률 스퀘어클 + 사방 100px 투명 여백 + 은은한 그림자**.
  - 변환은 SwiftUI `ImageRenderer` 로 1회성 CLI 를 짜서 처리(`RoundedRectangle(cornerRadius: 185.4, style: .continuous)`). Pixelmator 재출력 없이 품질 유지.
  - 검증: 알파 bbox 로 스퀘어클 위치 확인(본체 100~924px), 네 모서리 투명, **두 타깃 번들의 `AppIcon.icns` 해시가 소스와 일치**.
- **팝업 사이트 배너 ON/OFF 토글 신설** — 설정 → 일반 "팝업 하단 사이트 배너 표시"(기본 ON, 키 `showSiteBanner`).
  - 끄면 **배너 블록 141.5유닛만** 빠진다 → 캔버스 1176 → 1034.5 (468×611.5pt → 468×538pt). **사용자 요청대로 넓힌 푸터 띠 120 유닛은 그대로 유지.**
  - 구현: `DS.canvasHeight` 를 계산 프로퍼티로 전환 + `PopupView.footerShift` 로 구분선·푸터를 통째로 이동. 팝업이 떠 있는 채로 토글해도 즉시 반영되게 `StatusItemController` 에 `UserDefaults.didChangeNotification` 옵저버 추가.
  - 검증: 스냅샷 픽셀이 계산값과 정확히 일치(936×1224 / 936×1076 @2x), MAS 샌드박스 빌드도 렌더 정상.
- **버전 1.2.0 → 1.3.0, 빌드 9** (`project.yml`). 사용자 결정: 배너 토글은 새 기능이므로 팀 규칙(정식 배포=minor↑)에 맞춤. **ASC 버전 레코드도 1.0 → 1.2.0 → 1.3.0 으로 두 번 수정했다.**
- **빌드 9 아카이브 생성·업로드** — `xcodebuild archive` 로 Organizer 표준 경로에 직접 생성 후 Distribute App.
  - 세션 10의 지뢰 2개 재발 없음 확인: `CODE_SIGN_IDENTITY = Apple Development`(ad-hoc 아님) · **quarantine xattr 0건**.
  - 그 외 검증: Sparkle 0건(프레임워크·`otool`·SU\* 키), 샌드박스 엔타이틀먼트 정상, `.omc` 잡파일 0건, 직접배포 타깃 회귀 없음.
- **`docs/APPSTORE-SUBMISSION.md` 신규 작성** — 한/영 전체 메타데이터(부제·설명·키워드·프로모션 텍스트·URL·심사노트 영문 전문)를 복붙 가능한 형태로. 글자 수 제한은 전부 실제 계산으로 검산.
- **로컬 설치** — `/Applications/HotSauce.app` 을 1.1.3(빌드6) → 1.3.0 으로 교체. 사용자 실기기 테스트 정상 확인.

### 🎯 사용자 확정 — 직접배포 채널을 단계적으로 **마감**한다 (2026-08-15 결정)

앞으로의 배포 전략이 이번 세션에 확정됐다. **다음 세션은 이 전제로 움직여야 한다.**

1. **앱스토어 앱이 출시되면** → 그 시점에 직접배포판도 **1.3.0 으로 올리고 출시 알림을 함께 낸다.**
   - 즉 직접배포 1.3.0 은 "기능 릴리스"가 아니라 **앱스토어 이전 안내를 실어 보내는 마지막 배포**다.
2. **그 이후로는 앱스토어에서 받아 쓰게 하고, 직접배포 채널은 마감한다.**
   - 1.3.0 이 직접배포의 **마지막 버전**이 될 예정이다.

**마감 시 반드시 챙길 것 (아직 결정·작업 안 됨):**
- ⚠️ **기존 직접배포 사용자는 App Store 판으로 자동 이전되지 않는다** (번들 ID 는 같지만 직접배포판은 `~/Library/Preferences/`, MAS 판은 `~/Library/Containers/` 를 쓴다 — 세션 9 기록). **수동 재설치 안내가 필요하다.**
- ⚠️ **appcast 를 언제 어떻게 정리할지 결정해야 한다.** `web/public/hotsauce/appcast.xml` 을 내리면 구버전 사용자의 Sparkle 업데이트 확인이 실패한다. 1.3.0 항목을 **남겨두는 편이 안전**하고, 1.3.0 릴리스노트에 "이후 업데이트는 App Store 에서" 를 명시하는 방식이 자연스럽다.
- ⚠️ 웹 `/hotsauce` 페이지의 다운로드 버튼을 **App Store 배지로 교체**하는 작업(웹 스트림 과제).

### 다음에 할 일
1. **심사 결과 대기.** 리젝되면 사유를 `APPSTORE-SUBMISSION.md` 에 기록하고 대응.
2. **앱스토어 출시 확정 후 → 직접배포 1.3.0 공증 배포 (= 마지막 배포 + 이전 안내).**
   - 현재 웹 배포판은 1.2.0(빌드7)이라 **배너 토글·새 아이콘이 없다.**
   - 절차: `scripts/release-test-dmg.sh` → `scripts/sparkle-appcast.sh` → `web/public/hotsauce/` 복사 → `consts.ts` `HOTSAUCE_DOWNLOAD_URL` + `HotSaucePage.astro` `softwareVersion` + `i18n/info.ts` 릴리스노트.
   - ⚠️ **`web/src/i18n/info.ts` 에 핫소스 1.3.0 항목이 아직 없다.** 배너 토글 문구 **+ 앱스토어 이전 안내**를 포함해 새로 써야 한다.
   - ⚠️ 빌드 9는 앱스토어에 소진됐다 → 직접배포는 **빌드 10** 부터.
   - ⚠️ **순서가 중요하다** — 앱스토어 출시가 확정되기 전에 직접배포 1.3.0 을 내면 "이전 안내"의 대상이 아직 없는 상태가 된다.
3. **커밋 판단 2건 (이번 세션에서 손대지 않고 남김)**
   - `apps/hotsauce/images/` — **48MB 디자인 원본.** 루트 handoff 의 ".gitignore 로 디자인원본 제외" 방침과 맞지 않으므로 **gitignore 추가 권장**(커밋 금지).
   - `apps/hotsauce/dist/` — 52KB 릴리스 산출물(appcast 조각·릴리스노트). **피클은 `apps/pickle/dist/` 를 커밋하고 있다**(17개). 파리티를 맞추려면 커밋하는 쪽이 일관적.
4. (이월) 폭발 파티클 전용 아트 · 옛 `HotSauce-1.0.0.dmg` 정리 · Pretendard `OFL.txt` 사본 · `PrivacyInfo.xcprivacy`.

### 주의사항 / 컨텍스트 — 앱스토어 제출에서 실제로 막혔던 것들

- **🚨 앱 이름은 현지화마다 개별로 전역 중복 검사를 받는다. 그리고 검사는 문자열 단위다.**
  - 거부: `HotSauce : System Monitor`(콜론) → 거부. **`HotSauce` 단독으로 줄여도 거부.** 앱 레코드 생성 때 확보한 이름(기본 언어=한국어)이 다른 현지화에서 자동으로 통하지 않는다.
  - **✅ 통과: 한국어 `HotSauce` / English (U.S.) `HotSauce - System Monitor`(하이픈).**
  - **💡 핵심 교훈 — 거부된 콜론 버전과 통과한 하이픈 버전의 차이는 구분 기호 하나뿐이다.** `System Monitor` 라는 표현이 막힌 게 아니었다. 이름이 막히면 포기하지 말고 **구두점·띄어쓰기 변형(`-` / `–` / 공백 / 붙여쓰기)을 먼저 시도**할 것.
  - 덤: 미국 이름에 `System Monitor` 가 들어가 **이름도 검색 색인에 기여**한다(이름은 검색 가중치가 가장 높다).
  - 뒤따르는 "다른 필드가 유효하지 않으므로 …을 저장할 수 없습니다" 줄들은 **도미노일 뿐**이다. 이름 하나만 통과하면 함께 사라진다.
  - ⚠️ 이름 오류가 나면 **그 현지화 전체가 저장되지 않는다.** 고친 뒤 부제·설명·키워드가 실제로 들어갔는지 재확인 필요.
- **🚨 `/privacy` 는 사이트 미들웨어의 자동 언어분기 대상이 아니다.** 입력한 주소가 그대로 열린다.
  - ASC 개인정보처리방침 URL 은 **현지화별 입력 칸**이므로, 영어(미국)에는 반드시 `https://pizza-clip.com/en/privacy` 를 넣어야 한다. `/privacy` 를 넣으면 영어권 심사자에게 한국어 방침이 열린다.
  - 두 페이지 모두 라이브 확인(2026-08-15, 각각 200).
- **앱 안의 방침 링크는 이미 요건 충족.** 심사 지침 5.1.1 은 "ASC 메타데이터 **+ 앱 안**"을 요구하는데(전문 게재는 불필요, 링크로 충분), 설정창 버전 줄 옆 링크가 이를 만족하고 `SettingsView.privacyURL` 이 앱 언어로 `/privacy` ↔ `/en/privacy` 를 분기한다.
- **가격은 숫자 입력이 아니라 목록 선택**이다. 가격표 맨 위의 `무료`(₩0) 를 고른다. 국가는 기본이 "모든 국가"라 **미국·한국만 남기고 직접 해제**해야 한다. 무료 앱은 은행·세금 정보 등록이 불필요하다.
- **MAS 첫 실행이 오래 걸린다** — 샌드박스 컨테이너 생성 때문에 첫 `HOTSAUCE_SNAPSHOT` 실행이 60초를 넘겨 타임아웃될 수 있다. **두 번째 실행부터는 즉시 통과**하므로 코드 문제로 오인하지 말 것.
- **아이콘 변환 CLI 는 톱레벨 코드에서 `ImageRenderer` 를 못 쓴다** — `MainActor.assumeIsolated { }` 로 감싸야 컴파일된다. (`main.swift` 파일명 필수 제약은 세션 10 하네스와 동일.)
- 설정창 420 높이에서 '업데이트' 섹션은 스크롤해야 보인다. **이번 토글 추가로 생긴 문제가 아니라 기존 배포판부터 그랬다**(git baseline 렌더로 대조 확인). 손대지 않음.

---

## 세션 10 — 2026-08-14: 1.2.0 팝업 배너 + 푸터 여유 + 공증 배포 (✅ 완료·배포됨)

### 마지막으로 한 일
- **1.2.0(빌드7) 공증 배포 완료.** 커밋 `bf02a7e` → master push → 라이브 검증 통과(appcast 1.2.0/build7, DMG 200·3,452,466B, 페이지 다운로드 버튼 1.2.0, 릴리스노트 한·영).
- **팝업 사이트 배너 신설** — 네트워크 섹션과 푸터 구분선 사이. 누르면 `https://pizza-clip.com/`.
  - 에셋: `내부아이콘/핫소스배너1.png` → `Resources/DesignAssets/site_banner.png`로 복사(한글 파일명은 번들 조회 위험이라 ASCII 개명).
  - **기하는 눈대중이 아니라 이미지 측정에서 역산했다.** 원본 3000×498의 양 끝 아이콘이 정확히 206×206px, 중심 x=407.5 / 2635.5 → 스케일 `(790.6−126)/(2635.5−407.5)=0.298294 유닛/px` → 배너 **894.9×148.6, 중심 451.9**, 배너 아이콘 **61.45 유닛**(섹션 62·얼굴 61 사이). 렌더 PNG를 재측정해 좌우 열 편차 1유닛(0.5pt) 이내 확인.
  - 언어 분기는 사이트 미들웨어가 접속 국가로 처리 → 앱에서 `/en/`을 붙이지 않는다(붙여도 되돌려 보내짐).
- **푸터 띠 확장** 85.5 → 120 유닛(아이콘 여백 12→29, 탭 영역 70→80). 배너 위 여백 45.5는 섹션 사이 간격(45.3/47.7/46.7)에 맞춘 값.
- **설정창 개인정보처리방침 링크 + 포커스 링 제거** — SwiftUI `Link`가 macOS에서 버튼으로 만들어져 창의 첫 응답자가 되는 게 원인. `focusable(false)` + `show()`에서 한 턴 미룬 `makeFirstResponder(nil)` 2중 방어. 실제 `SettingsWindowController.show()` 경로로 첫 열기·재열기 모두 포커스 없음 확인.
- **캔버스 1000 → 1176** (팝업 468×520 → 468×611.5pt).
- **앱스토어 업로드 — 빌드7 거부 → 빌드8 재업로드 필요.** App ID 등록 + App Store Connect 앱 레코드(macOS · 이름 HotSauce · Apple ID `6801170433` · 번들 `com.Team-jAm.HotSauce` · SKU `hotsauce-mac-001` · 전체 액세스) 생성 완료.
  - 빌드7은 Organizer 상태 `Uploaded to Apple`(Team `jaekeun park`, Intel·Apple Silicon)까지 갔으나, 몇 분 뒤 **`ITMS-91109: Invalid package contents`** 메일로 거부됐다 → 아래 주의사항의 **xattr** 항목.
  - **지뢰 2개를 밟았다**: ① `CODE_SIGN_IDENTITY` (No Team Found in Archive) ② xattr `com.apple.quarantine` (ITMS-91109). 둘 다 `project.yml` 에서 영구 조치했고 주의사항에 상세히 남겼다.
  - `project.yml` 빌드 번호를 **8** 로 올려뒀다(7은 소진). ⚠️ 직접 배포 1.2.0 은 **빌드7로 이미 배포·라이브** 상태이고 appcast 도 7이다 — 직접 배포를 다시 낼 일이 생기면 빌드 번호가 8부터라는 점만 인지할 것(현재 라이브에는 영향 없음).
  - **✅ 빌드8 재업로드 완료**(2026-08-14). 두 지뢰를 다 고친 뒤 올렸고 거부 메일 없음. 다만 ASC 버전 레코드가 아직 `1.0` 이라 빌드 연결 전에 고쳐야 한다(아래 "다음에 할 일" 1번).

### 다음에 할 일
1. **🚨 App Store Connect 버전 레코드가 `1.0` 이다 — `1.2.0` 으로 고칠 것 (최우선)**
   - 앱 목록에 "macOS **1.0** 제출 준비 중" 으로 떠 있는데, 업로드한 빌드는 `CFBundleShortVersionString = 1.2.0` 이다.
   - ASC 는 **버전 레코드와 같은 버전 문자열을 가진 빌드만** "빌드" 목록에 보여준다 → 지금 상태로는 **빌드 8 이 목록에 안 뜬다.**
   - 조치: ASC → HotSauce → 사이드바 `macOS 앱 → 1.0 제출 준비 중` → 상단 **버전** 입력란을 `1.2.0` 으로 수정·저장. (제출 준비 중 상태라 자유롭게 수정 가능.)
   - 앱스토어 첫 버전이 1.0 일 필요는 없다. 형식만 맞고 이후 계속 커지면 된다. 직접 배포판이 이미 1.2.0 이라 **맞추는 쪽이 옳다**(채널별 버전 어긋남·릴리스노트 불일치 방지).
2. **App Store Connect 마무리** (빌드8 업로드는 2026-08-14 완료):
   - 버전을 1.2.0 으로 고친 뒤 "빌드" 섹션에서 **빌드 8 연결**.
   - 남은 메타데이터: 스크린샷(1280×800 등으로 통일, **팝업 열린 데스크톱 캡처** — 메뉴바 앱이라 팝업이 안 보이면 심사에서 문제) · 설명·키워드·연령등급 · 지원 URL `https://pizza-clip.com/hotsauce` · 개인정보처리방침 URL `https://pizza-clip.com/privacy`.
   - **App Privacy 설문 = "Data Not Collected"** (방침 2번이 "직접 다운로드 버전만 해당"으로 명시돼 있어 모순 없음).
   - **심사노트 필수** — LSUIElement라 리뷰어가 앱을 못 찾아 리젝되는 사례가 흔하다. "메뉴바 우측 핫소스 병 아이콘 클릭" + 스크린샷을 반드시 기재.
3. **기본 언어가 한국어**라 영어권에도 한국어 설명이 뜬다 → 버전 페이지에서 English (U.S.) 현지화 추가 필요. 문구는 `web/src/i18n/hotsauce.ts` 재활용 가능.
4. **앱 아이콘이 macOS 규격이 아니다** (이월 항목의 정체를 이번에 측정으로 확정):
   - `assets/HotSauceAppIcon.png` 는 1024×1024 캔버스를 **100% 꽉 채운다**(투명 여백 0px) = **iOS 방식**.
   - macOS 규격은 1024 캔버스 안에 **824×824 스퀘어클(80.5%)** + 사방 100px 투명 여백이다. 그림자·반사 공간이자 Dock 에서 크기가 들쭉날쭉해 보이지 않게 하는 장치.
   - 증상: ASC 앱 목록에서 iOS 앱(ZRcamera)보다 작아 보이고, Dock·Launchpad 에서 다른 앱보다 크고 각져 보인다. **심사에는 지장 없다.**
   - 조치: 1024 안에 824 스퀘어클로 다시 그려 `assets/HotSauceAppIcon.png` 교체 → `./scripts/build-icon.sh`. 코드로 축소·마스크하면 뭉개지므로 Pixelmator 재출력이 품질상 낫다.
5. (선택·이월) 폭발 파티클 전용 아트 · 옛 `HotSauce-1.0.0.dmg` 정리 · Pretendard `OFL.txt` 사본(`Fonts/NOTICE.txt`에 curl 명령 있음) · `PrivacyInfo.xcprivacy`.

### 주의사항 / 컨텍스트
- **설정창 렌더 검증 하네스**(재사용 가능) — 앱 코드에 훅을 추가하지 않고 설정창을 눈으로 볼 수 있다. 실제 `SettingsWindowController.show()`를 그대로 호출하고 `screencapture`로 찍으므로 포커스 링까지 재현된다:
  ```bash
  swiftc -o probe main.swift HotSauce/Settings/SettingsView.swift HotSauce/Localization/L10n.swift \
    -framework AppKit -framework SwiftUI -framework ServiceManagement   # MAS 변형은 -D MAS
  ```
  ⚠️ 하네스에서 `app.appearance`를 명시하지 않으면 다크로 잡혀 배너 흰 글자가 흰 배경에 묻힌다(앱 버그 아님). 최상위 실행문을 쓰려면 파일명이 반드시 `main.swift`여야 한다.
- **🚨 MAS 타깃에 `CODE_SIGN_IDENTITY` 를 직접 쓰지 말 것** (2026-08-14 실제로 배포가 막혔던 지뢰):
  - 증상: Organizer 에서 Distribute App 을 누르면 **"No Team Found in Archive"** 로 거부. 아카이브를 뜯어보면 `TeamIdentifier=not set`, `embedded.provisionprofile` 없음 = **ad-hoc 서명**.
  - 원인: XcodeGen 은 `CODE_SIGN_STYLE: Automatic` 인 타깃에 `"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Apple Development"` 를 **자동으로 넣는다.** Xcode 에서는 조건부(`[sdk=…]`) 설정이 무조건부보다 우선하므로, `project.yml` 에 쓴 `CODE_SIGN_IDENTITY: "Apple Distribution"` 은 **한 번도 적용된 적이 없고** 오히려 해석 결과가 `-`(ad-hoc)로 떨어졌다.
  - 확인법: `xcodebuild -target HotSauce-MAS -configuration Release -showBuildSettings | grep CODE_SIGN_IDENTITY` → `-` 가 나오면 잘못된 상태, `Apple Development` 면 정상.
  - 조치: `project.yml` 에서 `CODE_SIGN_IDENTITY` 줄을 **제거**하고 자동 서명에 맡긴다. 배포용 인증서는 Distribute App 단계에서 Xcode 가 고른다.
  - 직접 배포(HotSauce) 타깃은 `CODE_SIGN_STYLE: Manual` 이라 이 조건부 키가 안 생기고, 게다가 `release-test-dmg.sh` 가 `codesign` 으로 다시 서명하므로 애초에 영향이 없다 — **MAS 타깃만 걸린다.**
  - ⚠️ Xcode Build Settings UI 에서 고치면 `HotSauce.xcodeproj` 에 저장되는데, 이 파일은 gitignore + XcodeGen 생성물이라 다음 `xcodegen generate` 에 **통째로 사라진다.** 반드시 `project.yml` 에서 고칠 것.
- **🚨 번들 안 파일의 확장속성(xattr)이 앱스토어 업로드를 거부시킨다** (2026-08-14 실제 거부됨):
  - 증상: 업로드는 성공(`Uploaded to Apple`)하는데 몇 분 뒤 메일로 **`ITMS-91109: Invalid package contents`** — "The package contains one or more files with the com.apple.quarantine extended file attribute, such as …/Resources/bat2_icon.png".
  - 원인: 디자인 PNG 를 Finder·다운로드 경유로 넣으면 `com.apple.quarantine` 이 따라온다. 실제로 `bat2_icon.png` · `bat_icon_charge.png` · `site_banner.png` 3개가 물고 있었고, Xcode 리소스 복사가 xattr 를 그대로 보존해 번들까지 전파됐다.
  - 조치: (1) 소스 1회 청소 `xattr -cr HotSauce/`, (2) **두 타깃에 `postBuildScripts` 로 `xattr -cr "${TARGET_BUILD_DIR}/${WRAPPER_NAME}"` 상시 적용.** macOS 15+ 는 파일 접근만 해도 `com.apple.provenance` 를 다시 붙이므로 소스 청소만으로는 재발을 못 막는다 → 빌드마다 터는 게 정답.
  - 코드 서명은 모든 빌드 페이즈 **뒤**에 돌아서 이 스크립트가 서명을 깨지 않는다(`codesign --verify --deep --strict` 통과로 확인).
  - 확인법: `find <앱> -exec xattr {} \; | sort | uniq -c` → `com.apple.quarantine` 이 0건이면 OK. `com.apple.provenance` 는 남아도 무방하다(ITMS-91109 는 quarantine 만 지목).
  - 빌드 7은 이 문제로 거부돼 **소진**됐다. 재업로드는 빌드 8부터.
- **Apple Distribution 인증서는 아직 없다** (키체인에 Developer ID Application + Apple Development 만 있음). 1.2.0 업로드는 자동 서명이 개발용 인증서로 아카이브하고 Distribute 단계에서 처리해 통과했다. 필요해지면 Xcode → Settings → Accounts → 팀 선택 → Manage Certificates… → `+` → Apple Distribution.
- **이 맥은 키보드 탐색이 켜져 있다**(`AppleKeyboardUIMode = 2`) → 모든 컨트롤에 포커스 링이 그려진다. 포커스 관련 이슈를 재현할 때 이 전제를 기억할 것.
- **배너를 다른 그림으로 교체하면 정렬 계산을 다시 해야 한다** — 좌표는 그림 안 아이콘 픽셀 위치에 묶여 있다. `PopupView.siteBanner` 주석에 계산식이 그대로 적혀 있다.
- **오른쪽 아이콘 열의 "안쪽으로 들어가 보이는" 느낌은 위치 문제가 아니다** — 측정상 얼굴·배너·설정이 전부 편차 2유닛 이내다. 얼굴은 꽉 찬 색 블록, 링크·설정은 가는 윤곽선이라 시각적 무게가 달라서 그렇게 보인다. 사용자 판단으로 **그대로 두기로 결정**. 근본 해결은 배너 그림의 링크 아이콘을 채움 스타일로 다시 그리는 것.
- **얼굴 x가 두 값으로 갈려 있다**(cpu·메모리·저장 788.9 / 배터리·네트워크 791.3, 2.4유닛 차) — 원본 pxd에서 넘어온 기존 오차. 정리 제안했으나 이번엔 손대지 않음.
- 릴리스 시 버전 갱신 지점은 그대로: `project.yml` · `consts.ts` · `HotSaucePage.astro` softwareVersion · `i18n/info.ts` 릴리스노트. **Info.plist 쌍둥이는 버전을 `$(MARKETING_VERSION)`으로 받으므로 따로 손댈 필요 없다.**

---

## 세션 9 — 2026-08-06: 앱스토어 출시 준비 — 듀얼 타깃 전환 (✅ 코드 완료 · 배포됨 · 커밋 `0ea58f2`)

### 마지막으로 한 일
- **샌드박스 실측 먼저.** 앱스토어는 App Sandbox 가 강제라, 핫소스가 쓰는 시스템 API 9종을 프로브 앱(adhoc 서명 + `com.apple.security.app-sandbox`)으로 샌드박스 ON/OFF 각각 돌려 비교했다. 결과:
  - **통과** — CPU `host_statistics` · 메모리 `host_statistics64` · `sysctl`(압력/스왑) · 루트 볼륨 용량 · `getifaddrs`(속도·로컬IP) · **IOKit `AppleSmartBattery`(온도·사이클까지)** · `NSWorkspace.openApplication`(활성 상태 보기 실행).
  - **차단** — CoreWLAN `CWWiFiClient.interface()` 가 **nil**. → `com.apple.security.network.client` 를 주면 정상 복귀(rssi 값 확인). **이게 유일한 실제 차단이었다.**
  - ⚠️ 이걸 놓치면 크래시가 아니라 **조용히 틀린 값** — `NetworkSampler.signalBars()` 가 RSSI 를 못 읽으면 유선으로 간주해 신호를 **항상 5칸**으로 표시한다.
- **결론: 지표 수집 엔진은 코드 수정이 필요 없다.** 공사는 배포 인프라 쪽뿐이었다.
- **타깃 2개로 분리**(`project.yml`) — 사용자 결정 "직접 배포 + 앱스토어 둘 다 유지":
  - `HotSauce` — 기존 그대로(Developer ID · Sparkle · 공증 DMG). 동작 변화 없음.
  - `HotSauce-MAS` — App Sandbox · **Sparkle 의존성 없음** · `Info-MAS.plist` · `HotSauce-MAS.entitlements` · `CODE_SIGN_STYLE=Automatic` + `Apple Distribution`.
  - 코드 분기는 `#if MAS` **하나뿐**: `AppDelegate`(Sparkle import·updater·노티 옵저버), `StatusItemController`(우클릭 '업데이트 확인'), `SettingsView`('업데이트' 섹션 + `SUAutomaticallyUpdate` + 알림 이름).
  - 설정창 높이를 `SettingsWindowMetrics` 로 한 곳에 모음 — MAS 는 업데이트 섹션이 없어 500×330, 직접 배포는 500×420 유지.
- **신규 파일**: `HotSauce/HotSauce-MAS.entitlements`(sandbox + network.client, 실측 근거 주석 포함) · `HotSauce/Resources/Info-MAS.plist` · `Signing-MAS.xcconfig.example`(+ 로컬 `Signing-MAS.xcconfig` 생성·gitignore) · `HotSauce/Resources/Fonts/NOTICE.txt`(Pretendard OFL 고지).
- **양쪽 Info.plist 보강**: `NSHumanReadableCopyright` 채움 + `LSApplicationCategoryType=public.app-category.utilities`. MAS 쪽엔 `ITSAppUsesNonExemptEncryption=false` 추가, **SU\* 키 5개는 애초에 없음**.
- **검증 4중**: (1) 두 타깃 다 Release 빌드 성공(에러 0). (2) MAS 번들에 `Frameworks/` 없음 + `otool -L` 에 Sparkle 없음 + Info.plist 에 SU\* 키 0건. (3) 직접 배포 번들은 `Sparkle.framework`·`SUFeedURL` 그대로 = 회귀 없음. (4) **MAS 빌드를 샌드박스 엔타이틀먼트로 서명해 실제 실행 → 팝업 PNG 렌더 성공**(CPU 28%·메모리 79%·저장 50%·배터리 100%/30.7°C/104사이클·로컬IP·업다운 속도 전부 정상, 신호 5칸은 실제 rssi −43 이라 진짜 값).
- **🐞 덤으로 실배포 버그 발견·수정 — 앱 번들에 툴링 상태 파일이 섞여 나가고 있었음.**
  - `HotSauce/Resources/DesignAssets/.omc/state/` 의 `agent-replay-*.jsonl`(765B) · `subagent-tracking-state.json`(131B) 이 XcodeGen 에 리소스로 잡혀 앱 `Contents/Resources/` 에 복사됨. **`web/public/hotsauce/HotSauce-1.1.3.dmg`(공개 배포본)와 `/Applications` 설치본에서 실물 확인.** 2026-07-04 자 파일이라 그 이후 릴리스에 계속 실려 나간 것으로 보인다.
  - 내용은 에이전트 실행 텔레메트리(`agent`/`agent_type`/`event`/`success`/`t`)로 **대화·소스 내용은 아님** → 유출 피해는 사실상 없음. 다만 앱에 들어갈 파일이 아니고, 앱스토어 심사에서 정체불명 파일은 불필요한 트집거리다.
  - 원인: `.omc/` 는 gitignore 라 저장소는 깨끗한데, **빌드는 gitignore 를 안 본다**. 소스 폴더에 있으면 그냥 번들에 들어간다.
  - 수정: 두 타깃 `sources.excludes` 에 `"**/.omc"`·`"**/.omc/**"` 추가 + 리소스 폴더의 옛 `.omc` 삭제. 재생성·재빌드 후 두 번들 모두 잡파일 0건 확인.
  - ⚠️ **피클도 같은 문제**(`apps/pickle/PicKle/.omc` → `/Applications/PICkle.app` 에 1건). 다른 스트림이라 손대지 않음 — 별도 작업으로 남김. 피자클립은 `.omc` 가 타깃 폴더 밖이라 번들 깨끗(0건).
- **웹**: `/privacy` · `/en/privacy` 신설 — App Store Connect 필수 입력인 개인정보처리방침. 내용은 `middleware.js` 의 실제 수집 로직(real/ver/uniq/geo 키, IP 월별 소금 해시, 400일 TTL, `pclang` 쿠키)과 1:1로 맞춰 씀. 빌드 11→13페이지, 회귀 0, 한/영·hreflang·모바일 렌더 확인.
  - "세 앱 모두 외부 전송 없음" 주장을 실제로 검증함 — 피자클립·피클 소스에 `URLSession`/`dataTask`/분석 SDK 0건, 통신은 Sparkle appcast 확인뿐(방침 2번에 기술된 그것). 방침 문구가 사실과 일치.
- **개인정보처리방침 진입점 3곳 배치**:
  - 웹 푸터 **세 개 전부**(`Footer.astro` 피자 · `PickleFooter.astro` · `HotSauceFooter.astro`) + `ui.ts` 에 `footerPrivacy`(한 "개인정보처리방침" / 영 "Privacy"). 방침이 세 앱 공통이라 한 앱만 넣으면 나머지에서 도달 불가.
  - **앱 설정창** — 버전 줄 옆에 `v1.1.3 (build 6) · 개인정보처리방침` 으로 이어붙였다. **줄을 새로 만들지 않은 이유**: 세 앱 설정창 500×420 통일 규격을 지키려고. 앱 언어에 따라 `/privacy` ↔ `/en/privacy` 로 분기(`/privacy` 는 미들웨어 자동 언어분기 대상이 아니라 앱이 고른 주소가 그대로 열린다).
  - 샌드박스에서 외부 URL 열기 실측 완료(`NSWorkspace.open` → 기본 브라우저). 앱스토어 빌드에서 링크가 죽지 않는다.
- **⚠️ 자체 정정 — 설정창 MAS 높이 330 → 420 원복**: 커밋 `0ea58f2` 에서 "MAS 는 업데이트 섹션이 없으니 330" 으로 줄였는데 **계산 없이 잡은 값이었고, 실제로 렌더해보니 '언어' 섹션이 잘렸다.** 검증된 420 으로 되돌리고 `SettingsWindowMetrics` 의 `#if MAS` 분기를 제거했다. 아래가 조금 비는 건 무해하지만 섹션 잘림은 치명적이고, 420 은 3앱 통일 규격이라 파리티도 유지된다.
  - 검증 방법(재사용 가능): 앱 소스를 그대로 컴파일하는 렌더 하네스로 설정창을 PNG 로 뽑았다 — `swiftc main.swift Settings/SettingsView.swift Localization/L10n.swift -framework AppKit -framework SwiftUI -framework ServiceManagement` (MAS 변형은 `-D MAS`). 앱 코드에 검증용 훅을 추가하지 않고도 설정창을 눈으로 볼 수 있다. 단 하네스는 외형(appearance)을 명시하지 않으면 다크로 잡혀 배너 흰 글자가 흰 배경에 묻힌다.

### 다음에 할 일
1. **Apple 쪽 사전 작업**(사용자만 가능): Developer 포털에서 App ID 등록 → Mac App Store 프로비저닝 프로파일 → Apple Distribution 인증서. `Signing-MAS.xcconfig` 에 팀 ID 는 이미 채워둠.
2. **App Store Connect 메타데이터**: 이름·부제·설명·키워드·카테고리·연령등급·스크린샷(1280×800 등)·지원 URL·개인정보처리방침 URL(`https://pizza-clip.com/privacy`).
3. **⚠️ 심사 리스크 대비** — LSUIElement 라 리뷰어가 앱을 못 찾아 리젝되는 사례가 흔하다. App Review Information 에 "메뉴바 우측 핫소스 병 아이콘 클릭" + 스크린샷을 **반드시** 적을 것. Guideline 4.2(최소 기능)도 설명으로 방어.
4. **남은 보강**: `PrivacyInfo.xcprivacy`(macOS 는 아직 강제 아님) · Pretendard `OFL.txt` 사본 확보(NOTICE.txt 에 curl 명령 적어둠) · 앱 이름 "HotSauce" 스토어 선점 여부 확인 · 앱 아이콘 둥근 모서리(이월).
5. (이월) 폭발 파티클 전용 아트 · 옛 `HotSauce-1.0.0.dmg` 정리.

### 주의사항 / 컨텍스트
- **두 타깃 산출물이 둘 다 `HotSauce.app`** → 같은 `-derivedDataPath` 로 빌드하면 서로 덮어쓴다. 반드시 분리:
  ```bash
  xcodebuild -scheme HotSauce     -derivedDataPath build      …   # 직접 배포
  xcodebuild -scheme HotSauce-MAS -derivedDataPath build-mas  …   # 앱스토어
  ```
- **Info.plist 가 쌍둥이 2개**(`Info.plist` / `Info-MAS.plist`). 버전·아이콘·로컬라이제이션 등 번들 정보를 바꿀 땐 **양쪽 다** 고쳐야 한다. 양쪽 파일 머리에 경고 주석을 달아뒀다.
- **번들 ID 는 둘 다 `com.Team-jAm.HotSauce`** 로 뒀다. 직접 배포판(비샌드박스)은 `~/Library/Preferences/`, MAS 판은 `~/Library/Containers/` 를 쓰므로 설정은 서로 섞이지 않는다. 기존 1.1.3 직접 설치 사용자는 **App Store 판으로 자동 이전되지 않는다** — 웹에 이전 안내가 필요.
- **디버그 훅은 두 빌드 모두에 유지**(`HOTSAUCE_SHOW_POPUP`/`HOTSAUCE_SNAPSHOT`). 한때 MAS 에서 빼려다 되돌렸다 — 샌드박스에서도 **컨테이너 안 경로면 정상 저장**되고, 앱스토어 빌드도 UI 검증 수단이 필요하기 때문. 환경변수를 안 주면 아무 일도 안 하므로 심사에 무해.
- **MAS 팝업 검증법**: `HOTSAUCE_SNAPSHOT="$HOME/Library/Containers/com.Team-jAm.HotSauce/Data/popup.png"` — 컨테이너 밖 경로(/tmp 등)로 주면 샌드박스가 막아 저장이 안 된다.
- `SUPPORT_EMAIL`(`web/src/consts.ts`)에 개인 메일이 공개 페이지로 노출된다. 별도 문의용 주소를 쓰려면 이 상수만 바꾸면 전 페이지 반영.
- **미커밋 상태** — 앱 코드·웹 privacy·문서 전부 작업트리에만 있음.

---

## 세션 8 — 2026-07-15: 1.1.3 섹션 제목 옆 퍼센트 표시 (✅ 완료·배포됨 · 기록은 소급 작성)

> 이 세션은 당시 랩업 없이 끝나 HANDOFF·task 에 빠져 있었다. 커밋 `ba91981` 기준으로 세션 9에서 소급 정리.

### 마지막으로 한 일
- **1.1.3(빌드6) 공증 배포 완료.** 커밋 `ba91981` → master push.
- **기능 1건**: 팝업 섹션 제목 옆에 현재 수치를 퍼센트로 병기 (`CPU  43%` 꼴). `PopupView.sectionTitle` 에 `percent: Double?` 파라미터를 추가하고 CPU(`cpu.totalPercent`)·메모리(`usedFraction*100`)·저장 용량(`usedFraction*100`)·배터리에 전달. **게이지와 같은 기준값**을 쓴다. 네트워크는 해당 없음, 배터리 미장착 시 생략.
- **배포 범위**: `project.yml` 1.1.3/6 → 공증 DMG(`web/public/hotsauce/HotSauce-1.1.3.dmg`) → EdDSA appcast → `consts.ts` `HOTSAUCE_DOWNLOAD_URL` → `HotSaucePage.astro` `softwareVersion` → `info.ts` 릴리스노트(한/영) 추가.
- 로컬 `/Applications` 에 1.1.3(build6) 설치·실행 중.

---

## 세션 7 — 2026-07-09: 설정창 3앱 통일 + 1.1.2 정식 배포 (✅ 완료·배포됨)

### 마지막으로 한 일
- **1.1.2(빌드5) 공증 배포 완료.** 세션 6의 SSID·위치권한 제거분 + 이번 설정창 통일을 함께 배포. 커밋 `47580e0`(핫소스 소스) → master push → Vercel 라이브 검증 통과(appcast 1.1.2, DMG 200, 페이지 다운로드 버튼 1.1.2).
- **설정창 3앱 통일**(`Settings/SettingsView.swift`): 단일 폼 → 통일 '일반' 레이아웃 = 아이콘 헤더(`NSApp.applicationIconImage`) + "HotSauce" + tagline"메뉴바 시스템 모니터" + 버전 `v{short} (build {build})` → `Form(.grouped)`: 로그인시작 / 언어(세그먼트) / 업데이트. 창 `.frame(width:380)`→`500×420`(+`SettingsWindowController` NSWindow `setContentSize` 명시).
- **자동 다운로드 토글 신설**(`@AppStorage("SUAutomaticallyUpdate")=true`) — `AppDelegate`의 강제 `automaticallyDownloadsUpdates=true` **제거**(이제 사용자가 끄면 실제로 꺼짐, 기본 ON은 plist 폴백으로 보장). '업데이트 확인'을 `onCheckForUpdates` 클로저 → `.hotsauceCheckForUpdates` notification 배선으로 교체. 언어 `.system` 라벨 "시스템 설정 따름"→"시스템", enum 순서 시스템|한국어|English 통일.
- **배포 절차**: project.yml 1.1.2/5 → 서명 Release 빌드 → `release-test-dmg.sh`(공증 Accepted·staple·Gatekeeper) → `DOWNLOAD_BASE_URL=https://pizza-clip.com/hotsauce ./scripts/sparkle-appcast.sh` → `web/public/hotsauce/` 복사 → consts `HOTSAUCE_DOWNLOAD_URL` 1.1.2 + `HotSaucePage.astro` softwareVersion 1.1.2 + `info.ts` 릴리스노트(한/영: 1.1.2 + **웹에서 누락됐던 1.1.0·1.1.1 보강**) → 커밋 push → 라이브 검증. 로컬 `/Applications`에 1.1.2(build5) 서명본 설치·실행 중.

### 다음에 할 일
- (선택) 앱 아이콘 둥근 모서리 마스크 · 폭발 파티클 전용 아트 · 옛 `HotSauce-1.0.0.dmg` 정리 (세션 4 이월).

### 주의사항 / 컨텍스트
- **언어 방식**: 핫소스는 인라인 `L("en","ko")` + 재시작 방식 유지(사용자 결정 A). 피클만 실시간 전환이라 언어 아래 재시작 안내가 없음 — **의도된 차이**(원하면 피자·핫소스를 피클의 `.lproj` 실시간 방식으로 이관하는 게 후속 과제).
- 설정창 통일은 세 앱 **동형 복제**(공유 파일 아님, 독립 Xcode 프로젝트). 계획서 `.omc/plans/settings-unification.md`.
- dist/ 는 관례대로 미커밋(web/public에만 배포본 커밋). 세션 6의 "미커밋" 상태는 이번에 커밋·배포로 해소됨.

---

## 세션 6 — 2026-07-06: Wi-Fi 이름(SSID)·위치권한 제거 (✅ 코드 완료 · 미배포·미커밋)

### 마지막으로 한 일
- **사용자 요청**: "Wi-Fi 이름 나오는 부분 없애줘 — 위치권한 물어보는 게 거부감. 관련 코드 전부 빼줘. Wi-Fi 이름은 표시 안 해도 됨." → 세션 4/5에서 넣었던 SSID 표시 + CoreLocation 위치권한을 **전부 제거**(= SSID 기능 도입 이전 상태로 원복).
- **수정 파일 5개**:
  - `Metrics/Snapshot.swift`: `NetworkSnapshot.ssid` 필드 삭제.
  - `Metrics/NetworkSampler.swift`: `wifiInfo() -> (bars, ssid)` 튜플을 원래 `signalBars() -> Int` 로 복원. 신호 판정 조건의 `interface.ssid() != nil ||` 도 떼어내 `interface.rssiValue() != 0` 만으로 판정(SSID 흔적 완전 제거). **신호세기(칸수)는 그대로 유지**. `import CoreWLAN` 은 신호세기(RSSI)에 필요하므로 **유지**.
  - `Popup/PopupView.swift`: `networkSection` 에서 "네트워크 이름" 줄 삭제 + 나머지 2줄 `centerY` 원복(로컬IP·신호 831.2→802.8, 업·다운 860→831.2). **`sectionIcon` 의 `size:62` 는 세션3의 별개 변경이라 건드리지 않음**(원본 96으로 되돌리지 않음).
  - `App/AppDelegate.swift`: `import CoreLocation`, `locationManager` 프로퍼티, `NSApp.activate(...)`+`locationManager.delegate = self` 블록, `CLLocationManagerDelegate` extension **전부 삭제**.
  - `Resources/Info.plist`: `NSLocationWhenInUseUsageDescription`, `NSLocationUsageDescription` 키 삭제.
- **원본 대조**: `git show 1104f70~1`(=1.1.0 SSID 추가 직전)의 `networkSection`·`signalBars` 원본과 1:1 비교해 좌표·로직을 정확히 복원.
- **검증 3중**: (1) `grep -riE "ssid|CoreLocation|CLLocation|locationManager|NSLocation|requestWhenInUse"` → **0건**. (2) Release 컴파일 빌드(`CODE_SIGNING_ALLOWED=NO`) **성공**. (3) `HOTSAUCE_SNAPSHOT` 팝업 렌더 → Wi-Fi 줄 사라지고 네트워크 2줄 정상, 신호세기 ●●●●● 유지 육안 확인.
- **사용자 결정**: 배포·설치·커밋 **모두 안 함**("코드만 유지"). 변경은 작업트리에만 있음(미커밋).

### 다음에 할 일
- **설정창(Settings) 편집** — `HotSauce/Settings/SettingsView.swift`(자체 NSWindow: SMAppService 로그인 시작 · 언어 · 업데이트 확인). 구체 편집 내용은 세션 시작 시 사용자에게 확인.
- (이 세션 변경을 실제 반영하려면 — 사용자 지시 시)
  - 내 Mac만: 재빌드 → `/Applications` 설치.
  - 정식 배포: 1.1.2 bump → 공증 DMG → appcast → `web/public/hotsauce/` 복사 → **버전 3곳**(`project.yml` · `consts.ts` · `HotSaucePage.astro` softwareVersion) → push.

### 주의사항 / 컨텍스트
- **현재 실행 앱은 아직 1.1.1**(위치권한 쓰는 옛 버전). 이번 변경은 소스에만 있음. `build/` 에 검증용 미서명 빌드가 있으나 **설치 안 함**.
- **SSID 제거 범위**: 화면 표시 + Info.plist 설명 + AppDelegate 권한요청 + Sampler 저장·`ssid()` 호출까지 전부. `import CoreWLAN` 만 남김(신호세기용, 위치권한 무관).
- 위치권한을 뺐으므로 앱 첫 실행 시 **위치 허용 팝업이 더는 뜨지 않음**(사용자 요청의 핵심). 기존 1.1.1 설치자의 시스템 설정에 남은 위치 항목은 새 버전이 위치를 안 쓰므로 무의미.
- **미커밋 상태**: 다음 세션에서 설정창 작업을 커밋할 때 이 5개 파일도 함께 커밋할지(또는 별개 커밋으로 분리할지) 결정 필요.

---

## 세션 5 — 2026-07-05: 1.1.1 버그픽스 3종 + 네트워크 이름 재배치 (✅ 완료·배포됨)

### 마지막으로 한 일
- **1.1.1(빌드4) 공증 배포 완료.** 커밋 `6544a62` → master push → Vercel 라이브 검증 통과(appcast 1.1.1, DMG 200, 페이지 버튼 1.1.1).
- 버그 3종 + 레이아웃 1건:
  - **자물쇠 클릭 안 됨**(유일한 실제 코드 결함): `PopupView` 자물쇠의 `.contentShape(Rectangle())`가 `.placedCenter`(=offset) **뒤**에 있어 탭 영역이 팝업 좌상단 원위치에 남던 버그. footer(설정·활성보기)와 동일 패턴 — 그림(Image)과 별도 `Color.clear` 탭영역(placedCenter 845,41.4 w60 h60)으로 분리해 수정. → 사용자 실사용 확인됨.
  - **타이틀 폰트 불일치**: 세션4의 "u(35)≈18pt=피클과 동일"이 **오판**이었음. 피클 히스토리 타이틀은 실제 `.system(size:13, weight:.semibold)`(SF). `DesignTokens`에서 `headerFontSize` 제거 → `headerFont: Font = .system(size:13, weight:.semibold)` 추가, `PopupView.header`가 `DS.headerFont` 사용. 사용자 선택="피클과 완전 통일".
  - **위치권한·Wi-Fi 이름 안 뜸**: **근본 원인은 사용자 Mac의 위치 서비스 전역 OFF**였음(코드 아님). 켜니 즉시 해결. 코드도 표준으로 보강 — `AppDelegate`에서 무조건 `requestWhenInUseAuthorization` 제거, `NSApp.activate(ignoringOtherApps:)` + delegate만 설정. `locationManagerDidChangeAuthorization` 상태 분기(.notDetermined→request / .authorized→`startUpdatingLocation`+desiredAccuracy ThreeKilometers / .denied→폴백) + `didFailWithError` 추가. → **startUpdatingLocation 이 SSID 채움의 실질 트리거**임이 실사용으로 확인됨.
  - **네트워크 이름 위치**(사용자 요청): SSID를 로컬 IP 바로 위로. `networkSection` 세로좌표(802.8/831.2/860) 유지하고 내용만 재배치(이름 → 로컬IP·신호 → 업·다운).
- **배포 절차**: project.yml 1.1.1/빌드4 → `xcodegen generate` → Developer ID 서명 Release 빌드 → `release-test-dmg.sh`(앱+DMG 공증 Accepted·staple·Gatekeeper 통과) → `sparkle-appcast.sh`(EdDSA) → `web/public/hotsauce/` 복사 → `consts.ts` + `HotSaucePage.astro` softwareVersion 1.1.1 → 웹빌드 검증(11p) → 커밋 push → 라이브 검증.
- **로컬 설치**: 정식 공증 1.1.1 을 `/Applications` 에도 설치(그전까지 실행되던 테스트 adhoc 1.1.0 빌드 교체). Developer ID 서명이라 이후 재빌드에도 위치 권한이 안정 유지됨(project.yml 주석 참고). 단 adhoc→Developer ID 서명 전환이라 정식본 첫 실행 시 위치 권한을 1회 재요청할 수 있음 — 사용자 확인 대기 중.

### 다음에 할 일
- (선택) 위치 서비스 OFF/권한 거부 시 팝업이나 설정에 "Wi-Fi 이름을 보려면 위치 서비스를 켜세요" 힌트 UI 추가 고려(지금은 조용히 "—" 폴백이라 사용자가 이유를 모름).
- (이월) 세션4 선택 항목: 앱 아이콘 둥근 모서리, 폭발 파티클 전용 아트, 옛 `HotSauce-1.0.0.dmg` 정리.

### 주의사항 / 컨텍스트
- **릴리스 시 버전 갱신 3곳**: `project.yml`(MARKETING_VERSION+CURRENT_PROJECT_VERSION), `consts.ts`(HOTSAUCE_DOWNLOAD_URL), **`HotSaucePage.astro`의 `softwareVersion`**. 마지막 것은 세션2 1.0.0 이후 세션4에서 갱신 누락됐던 걸 이번에 발견·수정. 놓치기 쉬우니 체크.
- **위치권한 = 시스템 설정 의존**: SSID는 macOS 14+에서 위치권한 필수(Apple DTS 공식). 위치 서비스 전역 OFF면 프롬프트도 안 뜨고 즉시 denied. `tccutil reset Location <bundle>`은 **실패함**(Location은 특수 TCC, 표준 인프라 아님) — 리셋 필요 시 시스템 설정에서 수동.
- **커밋 범위**: 핫소스 소스 3개 + project.yml + web 배포물 8파일. HANDOFF.md·.claude·`dist/`는 제외(세션4 관행 유지, HANDOFF는 미커밋 로컬).

---

## 세션 4 — 2026-07-05: 1.1.0 기능 4종 + 공증 배포 (✅ 완료·배포됨)

### 마지막으로 한 일
- **1.1.0(빌드3) 4개 기능 + 공증 DMG 배포 완료.** 커밋 `1104f70` → master push → Vercel 라이브.
- 세션 3의 "미커밋 로컬 변경"(BatterySampler `externalConnected`, 앱 아이콘 등)도 이번 커밋에 함께 포함됨.
- 기능별:
  - **Wi-Fi 이름(SSID)**: `Snapshot.swift` `NetworkSnapshot.ssid` + `NetworkSampler.swift` `wifiInfo()`(bars+ssid 동시 반환) + `PopupView.swift` 네트워크 섹션 새 줄(left 242, centerY 860). **Option B 채택** — `AppDelegate`에 CoreLocation 위치권한 요청(`requestWhenInUseAuthorization`) + Info.plist `NSLocationWhenInUseUsageDescription`. macOS 14+는 권한 허용해야 이름 표시, 거부 시 "—".
  - **자물쇠 잠금**: `FocusablePanel.isLocked`(resignKey 가드) + `PopupView` 헤더 우상단 SF Symbol 토글(lock.open/lock.fill, placedCenter 845,41.4) + `StatusItemController.makePanel`에서 `panelRef`로 배선.
  - **배터리 충전 아이콘**: `bat2_icon` → **`bat_icon_charge`** (`내부아이콘/` → `Resources/DesignAssets/` 복사, PopupView batterySection).
  - **폭발 이스터에그**: 신규 `Popup/HotSauceBurst.swift`(PickleBurst 이식, 이미지=`menubar_1`, gravity 500, 파티클 40개) + `MetricsEngine.burstID`(빨강 `.bad` 4개+ rising edge, `isPopupVisible`일 때 즉발/닫혀 있으면 `replayBurstIfOverloaded()`로 팝업 열 때 발동) + PopupView ZStack 최상단 오버레이.
  - **타이틀 폰트 확대**: `DesignTokens.headerFontSize` 22→35 (u(35)≈18pt, 피클 타이틀과 동일).
  - **완전 자동 업데이트**: `AppDelegate`에서 `updater.automaticallyChecksForUpdates=true` + `automaticallyDownloadsUpdates=true` 코드 확정 (Info.plist엔 이미 `SUAutomaticallyUpdate=true`).
- **배포 절차 실행**: `project.yml` 1.1.0/빌드3 → Release 빌드(Developer ID 서명) → `release-test-dmg.sh`(앱+DMG 공증 2라운드 Accepted·staple, Gatekeeper 통과) → `sparkle-appcast.sh`(EdDSA appcast) → `web/public/hotsauce/`에 DMG+appcast 복사 → `consts.ts` 다운로드 버튼 1.1.0 → push → **라이브 검증**(appcast 1.1.0/build3, DMG 200, 페이지 버튼 1.1.0).
- **계획 문서**: `docs/PLAN-1.1.0.md` (조사·결정·코드 스케치 전부).

### 다음에 할 일
- **실사용 검증 2건**(자동 검증 불가 — 사용자 확인 필요):
  1. 1.1.0 첫 실행 시 뜨는 **위치 허용 팝업 → "허용"** 후 팝업 네트워크에 Wi-Fi 이름이 실제로 뜨는지.
  2. **폭발 이스터에그 실물** — 빨강 4개+ 상황. 테스트하려면 `MetricsEngine.overloadThreshold`를 잠깐 1~2로 낮춰 팝업 열고 확인 후 원복.
- (선택) 앱 아이콘 둥근 모서리 마스크 — 세션 3에서 넘어온 미결(`hotsauce_mainicon` 각짐). 사용자 확인 후 재생성.
- (선택) 폭발 파티클 전용 "폭탄 핫소스" 아트로 교체 — `HotSauceBurst.swift`의 `Assets.image("menubar_1")` 문자열 1줄만 바꾸면 됨.
- (선택) `web/public/hotsauce/HotSauce-1.0.0.dmg`는 기존 링크 보호용으로 유지 중 — 정리하려면 삭제.

### 주의사항 / 컨텍스트
- **위치권한 ↔ 배포 무관**: 이 앱은 Sparkle+DMG 직접배포(비샌드박스 Developer ID, 엔타이틀먼트 `<dict/>` 확인). 앱스토어 앱이 아니라 위치권한 추가가 배포에 아무 영향 없음. (설령 앱스토어라도 usage string 있으면 승인됨.)
- **미커밋 `dist/`**: `apps/hotsauce/dist/`(appcast.xml, appcast-item-*.xml, notes-1.1.0.md)는 로컬 산출물이라 커밋 안 함(1.0.0과 동일 관행). 배포본은 `web/public/hotsauce/`에만 커밋.
- **커밋 범위**: 핫소스 소스 + 웹 배포 20개 파일만. 피클·무관 web(InfoPage/i18n)·`.claude`·루트 handoff/task는 제외(다른 스트림 보존).
- **팝업 검증**: `HOTSAUCE_SNAPSHOT=<png>` PNG 렌더로 확인(타이틀·자물쇠·충전아이콘·SSID 줄·레이아웃 OK). 단 스냅샷 모드는 `isPopupVisible=false`라 **폭발은 안 뜸** → 실물은 실사용에서만.
- 이 HANDOFF.md 갱신은 로컬 작업트리에만 있음(미커밋) — 다음 세션 session-init이 읽음.

---

## 세션 3 — 2026-07-04: 1.0.1 다듬기 (→ 세션 4에서 1.1.0으로 완료·배포됨)

> 루트 `handoff.md`에 임시로 있던 내용을 이관. **아직 안 끝났고 배포 안 함.** 다음 hotsauce 세션은 여기서 이어받는다.

### 마지막으로 한 일
- **커밋됨**: 배터리 충전 시 왼쪽 아이콘을 플러그(`bat2_icon`)로 전환 (`1de0c42`, repo 버전은 **1.0.0 그대로**). pxd 숨김레이어(plug-svgrepo-com) 기반.
- **미커밋(로컬/테스트빌드 1.0.1빌드4에만 반영)**:
  - 배터리 조건 `IsCharging` → **`ExternalConnected`(꽂힘)** 로 변경 (최적화충전으로 IsCharging이 꽂혀도 자주 false).
  - 타이틀 폰트·아이콘 축소 (27→22, 64→48).
  - 사이드바 아이콘 5개 **62px·x=126** 정렬 (활성상태보기와 통일).
  - 앱 아이콘 `hotsauce_mainicon.png`로 교체 (`AppIcon.icns` 재생성).
- 테스트 빌드 **`1.0.1(빌드4)`** = `/Applications/HotSauce.app`에 설치·실행 중. **배포 안 함**(공증·appcast·push 없음). `project.yml`은 여전히 1.0.0(빌드타임 override로 테스트).

### 다음에 할 일 (바로 착수)
1. **남은 요청 3개 구현** (`apps/hotsauce/HotSauce/`):
   - **네트워크 이름(Wi-Fi SSID)** 한 줄 추가 → `Metrics/Snapshot.swift`의 `NetworkSnapshot`에 `ssid` 필드 + `Metrics/NetworkSampler.swift`에서 `CWWiFiClient.shared().interface()?.ssid()` 캡처 + `Popup/PopupView.swift`의 `networkSection`에 표시(로컬IP 근처, 레이아웃 빡빡하니 배치 주의).
   - **자물쇠 잠금** → 헤더 우상단 토글. 잠금 시 `MenuBar/FocusablePanel.swift`의 `resignKey`가 `orderOut` 안 하게(잠금 상태를 `MetricsEngine` 등 공유 상태로 두고 뷰·패널이 함께 참조).
   - **병 폭발 이스터에그** → 5개 섹션(cpu/memory/disk/battery/network) 중 `.bad` 4개+ 일 때 트리거. **피클/피자클립 이스터에그 구현부터 재조사**. 병 이미지는 `DesignAssets/title_icon.png`(TEAM JAM 병) 또는 `menubar_1.png` 재사용 가능.
2. **앱 아이콘 둥근 모서리** 여부 결정 — 지금 `hotsauce_mainicon.png`가 꽉 찬 정사각형이라 독/파인더에서 각져 보임. 사용자 확인 후 필요하면 마스크 적용해 재생성.
3. 완료·검증 후 **미커밋 앱 변경 전부 커밋**: `BatterySampler.swift`·`Snapshot.swift`·`DesignTokens.swift`·`PopupView.swift`·`Resources/AppIcon.icns`·`assets/HotSauceAppIcon.png` 등.

### 주의사항 / 컨텍스트
- **배터리 아이콘 로직**: `battery.externalConnected`(꽂힘) 기준. `IsCharging`은 최적화충전 때문에 꽂혀도 자주 false → 안 씀. `bat2_icon`(플러그)은 `bat_icon`과 픽셀 동일(1024×833). `Assets.exists()` 폴백 있어 에셋 없어도 안 깨짐. (사용자 "플러그가 작아 보인다" → 배터리 모양이 원래 납작(높이 81%)해서 그런 것, 크기는 동일 — "그대로 두기" 결정.)
- **🚫 computer-use로 팝업 스크린샷 불가** — LSUIElement(메뉴바 전용)라 허용목록에 못 올림. **팝업 UI 검증은 사용자가 직접** 메뉴바 병 아이콘 클릭. (좌표 기반 수정 후 사용자 확인 루프.)
- **테스트 빌드/설치**: `cd apps/hotsauce && xcodebuild -project HotSauce.xcodeproj -scheme HotSauce -configuration Release MARKETING_VERSION=1.0.1 CURRENT_PROJECT_VERSION=N CODE_SIGNING_ALLOWED=NO build`(컴파일 체크) 또는 서명 포함(`CODE_SIGNING_ALLOWED` 빼면 Developer ID). 설치: `pkill -x HotSauce; ditto <DerivedData>/…/Release/HotSauce.app /Applications/HotSauce.app; open`. 로컬 실행은 공증 없어도 OK(`spctl` reject는 정상 — quarantine 없어 실행됨).
- **배포는 아직**: 앱 릴리스(버전 bump→공증→DMG→appcast→push, 8단계)는 사용자가 따로 요청 시. 웹은 master push=Vercel 자동배포.
- **디자인 원본 `apps/hotsauce/hotsauce.pxd`**: 실은 zip(내부 `metadata.info`=SQLite + `data/UUID`=`PTBitmapBuffer` 비트맵). SQLite `document_layers`/`layer_info`로 레이어 이름·flags(하위비트=visible) 조회 가능. 벡터 도형(type 3)은 비트맵 캐시 없어 직접 추출 불가 → 필요 아이콘은 사용자가 Pixelmator로 내보내(`내부아이콘/`은 gitignore, 번들은 `HotSauce/Resources/DesignAssets/`).
- **⚠️ NBSP 주의**: `NavMinimal.astro` 등에 non-breaking space(U+00A0) 섞여 있어 Edit 매칭 실패 가능 → Python 라인 교체 우회.
- ~~(구 경고) pickle 미커밋 변경~~ → **해소됨**: pickle은 이 기간에 **1.3.2 배포 완료**([`../../pickle/docs/HANDOFF.md`](../../pickle/docs/HANDOFF.md)).

---

## 세션 2 — 2026-07-04: 웹 신설 + 1.0.0 공식 배포

- **웹 페이지 신설**: pizza-clip.com 모노레포 `web/`(Astro)에 핫소스를 세 번째 앱으로 추가. 시안(`web/hotsauce_page.png`) 그대로 재현 — 크림 히어로(틸 심전도-병 포스터) → 슬레이트 설명카드 → 빨강 스티커섹션 → 샌드 CTA. 한/영 공용(`components/pages/HotSaucePage.astro` + `i18n/hotsauce.ts`).
- **3앱 확장**: 인트로 3번째 카드, 네비 크로스링크를 "상대 1개 → 나머지 앱 전부"로 개조(피자/피클 페이지 회귀 0 검증 — dev+빌드+프로덕션), 정보 3열 릴리스노트(v1.0.0), llms.txt 3앱 갱신, 색토큰(`--hs-teal/slate/red/sand/poster/ink`)·미들웨어 언어분기 추가.
- **1.0.0 첫 공식 배포**: `project.yml` 0.1.0→1.0.0(빌드1→2) → `release-test-dmg.sh`로 공증 DMG(앱+DMG 2회 Accepted·staple) → `sparkle-appcast.sh`로 EdDSA appcast → `web/public/hotsauce/`에 DMG+appcast 복사 → `consts.ts` `HOTSAUCE_RELEASED=true` → 커밋 `516d1e4` push → Vercel 배포 → 프로덕션 검증(핫소스 URL 200·언어 자동분기·기존 페이지 회귀0).
- **자동업데이트**: 팀원 0.1.0(빌드1) 설치자는 1.0.0(빌드2)으로 자동 업데이트됨.
- 웹쪽 상세(앱 추가 패턴·릴리스 절차·NBSP 주의)는 모노레포 루트 `handoff.md` 참고.

---

## 세션 1 후반 — 2026-07-02 밤: 사용자 피드백 반영

- **병 매핑 사용자 확정**: 기본(쾌적)=빨강, 중부하=노랑, 고부하=레인보우 — 기존 구현 그대로, 종결.
- **팝업 축소**: 540×600 → **468×520pt** (`DS.scale` 0.6→0.52).
  사용자 요구 "75% + 피클보다 조금 크게"가 서로 충돌(피클 460×500 > 540의 75%인 405) →
  피클 비교 조건을 우선해 0.52 채택. 상세 수치 텍스트는 `DS.statFontPoints = 8.7pt` 절대값으로
  고정(최소 가독 크기 — 더 줄이지 말 것). 나머지(아이콘/게이지/제목/헤더)는 scale 따라 축소.
- **얼굴 표정 판정 완화**: 기준이 느슨해 사실상 항상 민트였음 →
  CPU 35/70%(순간값), 메모리는 게이지와 같은 사용률 60/80% 기준 + 커널 압력 단계(2/4)로 격상.
  검증: idle 렌더(메모리 66% → 노랑) / `yes`×8 부하 렌더(CPU 86% → 빨강) 둘 다 확인.
- **앱 아이콘 확정**: `사이트 디자인/메인아이콘.png`("I'm a Hot Sauce person" 하늘색 카드)를
  `assets/HotSauceAppIcon.png` 로 복사 → build-icon.sh 로 icns 재생성. 사용자 지정.
- 주의: 세션 스크래치(/private/tmp/...)는 수 시간 뒤 비워짐 — 렌더 출력 폴더는 mkdir -p 후 사용.

---

## 세션 1 — 2026-07-02: 앱 최초 구현

### 한 일
- **디자인 추출**: hotsauce.pxd(Pixelmator, ZIP+SQLite)에서 레이어 좌표·색·폰트 전부 추출.
  - 좌표계: 논리 900×1000 유닛(Y축 bottom-up, 중심점 기준). 캔버스는 그 2배(1800×2000px).
  - 색: 배경 #3A3A3C / 텍스트 #DEE0E2 / 구분선 #929292 / 게이지 #B6422E /
    얼굴 민트 #007C77·주황 #D97F04·빨강 #B6422E / 모서리 반경 40u
  - 폰트: 전부 Pretendard-Regular (헤더 27u, 섹션 제목 20u, 상세 14.5u — 유닛×0.6=pt)
- **사용자 확정사항**: 번들 ID `com.Team-jAm.HotSauce`(변경 금지), 팝업 540×600pt(scale 0.6),
  메뉴바 병 3종은 상태 자동 변경, 얼굴 3단계 = 민트(쾌적)/노랑(중부하)/빨강(고부하)
- **구현**: XcodeGen 프로젝트(피클 템플릿), Swift 5.9, macOS 13+, LSUIElement
  - `Metrics/`: CPU(host_statistics 틱 차분+5샘플 이동평균), 메모리(vm_statistics64+압력 sysctl+스왑),
    디스크(volumeAvailableCapacityForImportantUsage), 배터리(AppleSmartBattery IOKit),
    네트워크(getifaddrs 차분+CoreWLAN RSSI). 1초/5초 이중 폴링(런캣 방식)
  - `Popup/`: 디자인 좌표를 유닛 그대로 코드에 옮긴 절대배치 SwiftUI 뷰 (`DS.scale` 하나로 크기 조절)
  - `MenuBar/`: NSStatusItem 좌/우클릭 분기, FocusablePanel(포커스 잃으면 닫힘)
  - `Settings/`: 자체 NSWindow (SMAppService 로그인 시작, 언어, 업데이트 확인)
  - Sparkle 2 (형제와 같은 EdDSA 공개키, feed https://pizza-clip.com/hotsauce/appcast.xml)
  - Pretendard-Regular.otf 번들 (Info.plist ATSApplicationFontsPath=".", 리소스 평탄화 주의)
- **검증**: Release 빌드 성공, 실행 확인, `HOTSAUCE_SNAPSHOT=<png>` 훅으로 팝업 렌더 → 디자인과 대조 OK
- **멀티에이전트 리뷰(반박 검증 통과분만 수정)**:
  1. NetworkSampler — ifi_obytes/ifi_ibytes 는 32비트라 4GiB 랩어라운드/인터페이스 소멸 시
     UInt64 언더플로로 속도가 천문학적으로 표시되는 버그 → 인터페이스별 UInt32 랩 안전 차분으로 수정
  2. BatterySampler — IORegistry "Temperature" 는 0.1K 단위(centi-°C 아님).
     ÷100 은 실온에서만 우연히 맞음 → `raw/10 - 273.15` 로 수정 (애플 PowerManagement 소스로 교차 확인)
- **스크립트**: build-icon.sh / release-test-dmg.sh / sparkle-appcast.sh (피클에서 이식, 이름 치환)

### 다음 세션 (웹)
1. pizzaClip web 레포에 hotsauce 페이지 추가 (디자인: `web/hotsauce_page.png`, `a/hotsauce_page.pxd`)
2. 첫 릴리스: project.yml 버전 bump → Release 빌드 → `scripts/release-test-dmg.sh` →
   `DOWNLOAD_BASE_URL=https://pizza-clip.com/hotsauce scripts/sparkle-appcast.sh` →
   DMG+appcast.xml 을 web 레포 `web/public/hotsauce/` 에 복사 → push
3. git init + 첫 커밋은 사용자 확인 후 (아직 git 저장소 아님)

### 열린 질문 / 주의
- **병↔상태 매핑 확인 필요**: 현재 쾌적=빨강병(menubar_1), 중부하=노랑(2), 고부하=레인보우(3).
  반대(쾌적=레인보우, 고부하=빨강)를 원하면 `Snapshot.swift` `bottleAssetName` 세 줄만 스왑.
- 메모리 "압력 %"는 (wired+compressed)/전체 근사치. 얼굴 상태는 커널 공식 압력 단계 사용.
- 배터리 없는 데스크톱 맥은 배터리 섹션이 "—" 표시.
- Wi-Fi RSSI 는 CoreWLAN — 최신 macOS 에서 위치 권한 없이 0 이 나오면 유선 취급(5칸). 실기기별 확인 필요.
- 디버그 훅: `HOTSAUCE_SHOW_POPUP=1`(팝업 자동 표시), `HOTSAUCE_SNAPSHOT=<경로>`(팝업 PNG 저장 후 종료).
- 새 .swift 파일 추가 시 `xcodegen generate` 재실행 필수.
