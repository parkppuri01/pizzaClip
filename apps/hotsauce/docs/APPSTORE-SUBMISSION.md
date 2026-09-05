# HotSauce — App Store Connect 제출 정보

> 작성 2026-08-15 · 갱신 2026-09-06 · 대상 버전 **1.4.0 (빌드 11)** · 출시 **무료 / 미국·대한민국**
> 1.3.0(빌드 9)은 2026-08-25 출시 완료. 이 문서는 그 위에 올리는 **업데이트** 기준으로 갱신했다.
> 아래 값을 그대로 복사해 App Store Connect 에 붙여넣으면 된다.
> ✅ 표시는 채워 넣을 값, 📌 는 선택지에서 고를 값.

---

## 🚨 먼저 할 일 — ASC 에 **1.4.0** 버전을 새로 추가

1.3.0 이 이미 출시(2026-08-25)된 상태라, 업데이트를 내려면 **새 버전 레코드**를 만들어야 한다.
(1.3.0 페이지를 고치는 게 아니다 — 출시된 버전은 수정할 수 없다.)

**조치**: ASC → HotSauce → 왼쪽 사이드바 `macOS 앱` 옆의 **`+` (버전 또는 플랫폼 추가)**
→ **macOS** → 버전 번호 `1.4.0` 입력 → 생성.

> 생성하면 '제출 준비 중' 상태의 1.4.0 페이지가 뜨고, **설명·키워드·스크린샷·URL 은
> 1.3.0 것이 그대로 복사돼 온다.** 그래서 이번에 손댈 것은 사실상
> **"이 버전의 새로운 기능"(아래 4-5) 하나뿐**이다. 나머지 섹션은 참고용으로 남겨둔다.

### 빌드 11 업로드 방법 (아카이브는 생성 완료)

1. **Xcode → Window → Organizer** (⌥⇧⌘O) → Archives 탭
2. **`HotSauce-MAS 1.4.0 build11`** (2026-09-06) 선택
3. **Distribute App** → **App Store Connect** → **Upload** → 자동 서명에 맡기고 진행
4. 업로드 후 10~30분 처리 대기 → "처리 완료" 메일 도착 → ASC 1.4.0 페이지의 '빌드' 섹션에서 선택

> ⚠️ **빌드 번호가 11 인 이유**: 9 = 앱스토어 1.3.0(출시분), 10 = 직접배포 1.3.0(마지막 배포)로
> 각각 소진됐다. ASC 는 같은 번호를 두 번 받지 않는다.

### 1.4.0 에 담긴 변경 (심사 관점 요약)

| 변경 | 심사 영향 |
|---|---|
| 팝업 얼굴 아이콘 세트 4종(기본·피자·쥐·곰돌이) + 설정 Picker | 없음 — 번들 내 이미지 교체일 뿐 |
| 메뉴바 아이콘 5회 연타 이스터에그(폭죽 재생) | 없음 — 애니메이션 재생, 권한·통신 무관 |
| 폭죽 페이드아웃 제거 + 재생 시간 2.4→3.0초 | 없음 |
| 과부하 폭죽 임계치 빨강 4개 → 3개 | 없음 |
| 첫 실행 시 '로그인 시 자동 시작' 자동 등록(1회) | ⚠️ 아래 심사노트에 한 줄 추가함 |

---

## 1. 앱 정보 (App Information) — 버전과 무관한 공통 정보

| 항목 | 값 |
|---|---|
| 이름 (Name) | ✅ 한국어: `HotSauce`<br>✅ English (U.S.): `HotSauce - System Monitor` (하이픈)<br>**현지화마다 다르다 — 아래 ⚠️ 참고** |
| 부제 (Subtitle, 30자 이내) | ✅ 한국어: `메뉴바 시스템 모니터 · CPU 메모리 배터리` (25자)<br>✅ English: `Menu Bar CPU, RAM & Battery` (27자) |
| 번들 ID | `com.Team-jAm.HotSauce` (등록됨) |
| SKU | `hotsauce-mac-001` (등록됨) |
| Apple ID | `6801170433` |
| 기본 언어 (Primary Language) | 📌 **한국어** (현재 설정) |
| 카테고리 (Primary) | 📌 **유틸리티 (Utilities)** ※ 번들의 `LSApplicationCategoryType` 과 일치해야 함 |
| 카테고리 (Secondary) | 📌 **개발자 도구 (Developer Tools)** — 선택 사항, 비워도 무방 |
| 콘텐츠 권한 (Content Rights) | 📌 **제3자 콘텐츠를 포함하지 않음** |
| 연령 등급 (Age Rating) | 📌 **4+** (아래 2절 설문 참고) |

> ### ⚠️ 실제로 겪은 함정 — 이름에 설명어를 붙이면 "이미 사용 중" 오류
>
> 영어(미국) 이름에 `HotSauce : System Monitor` 를 넣었더니 이렇게 막혔다:
>
> ```
> 입력한 앱 이름이 이미 사용 중이므로 영어(미국)의 필드를 저장할 수 없습니다.
> 해당 현지화 버전에서 다른 필드가 유효하지 않으므로 영어(미국)의 이름 필드를 저장할 수 없습니다.
> 해당 현지화 버전에서 다른 필드가 유효하지 않으므로 영어(미국)의 부제 필드를 저장할 수 없습니다.
> ```
>
> **그리고 `HotSauce` 단독으로 줄여도 똑같이 막혔다.** (앱 레코드 생성 때 쓴 이름이라 통과할 줄 알았으나 아니었다.)
>
> ### ✅ 최종 통과한 이름 (2026-08-15)
> - 한국어: **`HotSauce`**
> - English (U.S.): **`HotSauce - System Monitor`** ← **하이픈**
>
> **거부된 `HotSauce : System Monitor`(콜론)와 통과한 `HotSauce - System Monitor`(하이픈)의 차이는 구분 기호 하나뿐이다.**
> 즉 `System Monitor` 라는 표현 자체가 막힌 게 아니었다. 중복 검사는 **문자열 단위**로 걸리므로,
> 막히면 포기하지 말고 **구두점·띄어쓰기 변형(`-` / `–` / 공백 / 붙여쓰기)을 먼저 시도해볼 것.**
>
> - **앱 이름은 현지화마다 개별로 전역 중복 검사를 받는다.** 앱 레코드를 만들 때 확보한 이름(= 기본 언어인 한국어)이 다른 현지화에서 자동으로 통하지는 않는다.
> - `HotSauce` 단독이 영어에서 막힌 원인은 밖에서 확정 불가. 둘 중 하나다:
>   ① **다른 개발자가 선점** — 출시하지 않아도 레코드만 만들면 이름이 잠긴다(그래서 스토어 검색에는 안 보인다). 실제로 App Store 에 정확히 `HotSauce` 인 앱은 없고 `HotSauce.com`·`Gimme The HotSauce` 같은 유사 이름만 있다.
>   ② **자기 한국어 현지화와 충돌** — 한국어가 이미 `HotSauce` 를 쥐고 있어 영어가 같은 문자열을 요구하면 막히는 사례가 보고된다.
> - **한국어 이름 `HotSauce` 는 그대로 유지.** 한국에서는 HotSauce, 미국에서는 `HotSauce - System Monitor` 로 보인다(나라별 다른 이름은 허용된다).
> - 덤: 미국 이름에 `System Monitor` 가 들어가면서 **이름도 검색 색인에 기여**한다(이름은 검색 가중치가 가장 높다).
> - **뒤따르는 "다른 필드가 유효하지 않으므로…" 줄들은 도미노일 뿐**이다 — 이름 하나만 통과하면 함께 사라진다.
> - ⚠️ 이름 오류가 나면 **그 현지화 전체가 저장되지 않는다.** 이름을 고친 뒤 부제·설명·키워드가 실제로 들어갔는지 다시 확인하고 저장할 것.
> - `이의를 제기하십시오` 링크는 **해당 이름의 상표권을 보유한 경우에만** 쓴다.
> - 검색 손해는 없다 — `monitor` 등 설명어는 이미 **부제와 키워드**가 담당한다. 애플도 이름에 설명어를 욱여넣는 것을 권장하지 않는다.

---

## 2. 연령 등급 설문 (Age Rating)

모든 항목에 **없음 / 아니요** 로 답한다 → 결과 **4+**

| 설문 항목 | 답 |
|---|---|
| 폭력(만화/판타지, 사실적), 성적 내용, 노출, 욕설, 유혈, 공포 | 없음 |
| 알코올·담배·마약 사용 또는 언급 | 없음 |
| 도박(시뮬레이션 포함) | 없음 |
| 콘테스트 / 사용자 생성 콘텐츠 | 없음 |
| 웹 브라우징 기능 없음 (외부 링크는 기본 브라우저로 열림) | 아니요 |
| 무제한 웹 접근 | 아니요 |
| 개인정보 또는 위치 공유 | 아니요 |

---

## 3. 가격 및 사용 가능 여부 (Pricing and Availability)

| 항목 | 값 |
|---|---|
| 가격 (Price) | 📌 **무료** — 가격 목록 맨 위의 `무료`(₩0) 를 **선택**한다. 0 을 입력하는 칸이 아니다 |
| 국가 또는 지역 | 📌 **직접 선택** → **대한민국(South Korea)** · **미국(United States)** 두 곳만 체크 |
| 사전 주문 (Pre-Order) | 📌 사용 안 함 |
| 배포 방식 | 📌 **공개 (Public)** — App Store 에서 검색·다운로드 가능 |

> 💡 "모든 국가" 가 기본값이라 **직접 미국·한국만 남기고 나머지를 해제**해야 한다.
> 나중에 국가를 추가하는 건 심사 없이 언제든 가능하다.
>
> 💡 **무료 앱은 은행 계좌·세금 정보를 등록할 필요가 없다.** 유료 앱이라면 '유료 앱 계약'(Paid Apps
> Agreement)에 은행·세무 정보를 모두 채워야 제출이 가능하지만, 무료는 계정 생성 시 이미 동의된
> 무료 앱 계약만으로 충분하다.

---

## 4. 버전별 정보 (macOS 앱 → 1.4.0)

### 4-1. 프로모션 텍스트 (Promotional Text, 170자 이내 · 심사 없이 수정 가능)

**한국어** (73자)
```
겉으론 조용한 내 Mac, 사실은 열심히 달리는 중일지도. CPU·메모리·배터리·저장 공간·네트워크를 메뉴바에서 한눈에 확인하세요.
```

**English (U.S.)** (139자)
```
Your Mac looks calm — but is it? Check CPU, memory, battery, disk, and network at a glance, right from a hot-sauce bottle in your menu bar.
```

### 4-2. 설명 (Description, 4000자 이내)

**한국어**
```
겉으로는 아무 일 없는 척해도, 뒤에서는 CPU가 뛰고 메모리가 바쁘고 배터리가 조용히 줄어들고 있을지 모릅니다. HotSauce는 내 Mac이 얼마나 열심히 일하고 있는지 메뉴바에서 바로 보여줍니다.

■ 메뉴바에서 한눈에
복잡한 창을 열 필요가 없습니다. 메뉴바의 핫소스 병 아이콘을 누르면 지금 내 Mac 상태가 한 화면에 펼쳐집니다.

■ 무엇을 볼 수 있나요
· CPU — 전체 사용률과 시스템/사용자/대기 비율
· 메모리 — 사용률, 메모리 압력, 사용량, 캐시, 스왑
· 저장 공간 — 사용량과 전체 용량
· 배터리 — 잔량, 온도, 충전 사이클 수 (충전 중이면 아이콘이 바뀝니다)
· 네트워크 — 로컬 IP, 신호 세기, 업로드·다운로드 속도

■ 부하에 따라 변하는 병 아이콘
Mac이 여유로우면 빨간 병, 바빠지면 노란 병, 아주 뜨거우면 무지개 병으로 바뀝니다. 메뉴바를 힐끗 보는 것만으로 지금 상태를 알 수 있습니다. 각 항목 옆의 얼굴 표정도 함께 바뀝니다.

■ 활성 상태 보기 바로 열기
더 자세히 파고들고 싶을 땐 팝업 아래의 버튼으로 macOS 활성 상태 보기를 바로 열 수 있습니다.

■ 개인정보를 수집하지 않습니다
계정도, 로그인도, 광고도, 분석 도구도 없습니다. 읽어들인 지표는 화면에 표시할 뿐 어디로도 전송하지 않습니다. 모든 것이 사용자의 Mac 안에서만 일어납니다.

■ 한국어와 영어를 지원합니다
설정에서 시스템 언어를 따르거나 한국어·English 중에서 직접 고를 수 있습니다.

■ 사용 방법
HotSauce는 메뉴 막대에서만 동작하는 앱입니다. 실행하면 Dock 이 아니라 화면 오른쪽 위 메뉴 막대에 핫소스 병 아이콘이 나타납니다. 그 아이콘을 클릭하세요.

macOS 13 이상 · Apple Silicon 및 Intel Mac 지원 · 무료

Team JAM 의 다른 Mac 앱도 만나보세요 — PizzaClip(클립보드 관리)과 PICkle(스크린샷 워크플로).
```

**English (U.S.)**
```
Your Mac seems idle on the surface, but behind the scenes the CPU is racing, memory is busy, and the battery is quietly draining. HotSauce shows you exactly how hard your Mac is working — right from the menu bar.

■ Everything at a glance
No heavy windows to open. Click the hot-sauce bottle in your menu bar and your Mac's current state unfolds in a single view.

■ What you can see
· CPU — total load, plus system / user / idle breakdown
· Memory — usage, memory pressure, used, cached, and swap
· Storage — used space and total capacity
· Battery — charge level, temperature, and cycle count (the icon changes while charging)
· Network — local IP, signal strength, upload and download speed

■ A bottle that changes with the load
When your Mac is relaxed the bottle is red; as it gets busy it turns yellow; and when things get really hot it goes rainbow. One glance at the menu bar tells you where you stand. The face next to each metric changes too.

■ Open Activity Monitor in one click
Want to dig deeper? A button at the bottom of the popup opens macOS Activity Monitor right away.

■ No data collection
No accounts, no sign-in, no ads, no analytics. The metrics it reads are only drawn on screen — nothing is ever sent anywhere. Everything stays on your Mac.

■ English and Korean
Follow your system language, or pick English or Korean yourself in Settings.

■ How to use it
HotSauce lives only in the menu bar. When you launch it, no Dock icon appears — instead a hot-sauce bottle shows up in the menu bar at the top-right of your screen. Click that icon.

macOS 13 or later · Apple Silicon and Intel · free

Check out the other Mac apps from Team JAM — PizzaClip (clipboard manager) and PICkle (screenshot workflow).
```

### 4-3. 키워드 (Keywords, 100자 이내 · 쉼표 구분 · 공백 넣지 말 것)

> **부제와 중복을 걷어낸 버전이다.** 애플 검색은 `앱 이름 + 부제 + 키워드`를 합쳐 색인하므로,
> 부제에 넣은 말(메뉴바·시스템·모니터·CPU·메모리·배터리 / menu·bar·cpu·ram·battery)을
> 키워드에 또 넣으면 **자리만 낭비**된다. 그 자리를 다른 검색어로 채웠다.

**한국어** (70자)
```
램,디스크,저장공간,네트워크,온도,사용량,성능,모니터링,활성상태보기,맥북,상태바,위젯,발열,인터넷속도,시스템정보,하드웨어,스왑
```

**English (U.S.)** (95자)
```
system,monitor,menubar,memory,network,disk,storage,performance,activity,stats,temperature,usage
```

> ⚠️ 주의 사항
> - 앱 이름(HotSauce)·카테고리명은 이미 검색에 반영되므로 키워드에 다시 넣지 않는다.
> - **쉼표 뒤에 공백을 넣지 말 것** — 공백도 100자에 포함된다.
> - 앱이 실제로 하지 않는 기능어(최적화·클리너·부스터 등)는 넣지 않았다. 오인을 유발하면 심사에서 지적받을 수 있다.
> - 영문은 `menubar`(붙여쓴 한 단어)를 남겼다 — 부제의 `Menu Bar`(띄어쓴 두 단어)와 검색 토큰이 다를 수 있어서다.

### 4-4. URL

**URL 은 현지화마다 따로 입력한다. 영어(미국) 로 드롭다운을 바꾼 뒤 반드시 아래 값으로 교체할 것.**

| 항목 | 한국어 | 영어(미국) |
|---|---|---|
| 지원 URL (필수) | `https://pizza-clip.com/hotsauce` | `https://pizza-clip.com/en/hotsauce` |
| 마케팅 URL (선택) | `https://pizza-clip.com/` | `https://pizza-clip.com/` |
| **개인정보처리방침 URL (필수)** | `https://pizza-clip.com/privacy` | **`https://pizza-clip.com/en/privacy`** |

> ### ⚠️ `/privacy` 는 자동 언어분기가 안 된다
> `/hotsauce` 같은 일반 페이지는 사이트 미들웨어가 접속 국가로 언어를 자동 분기하지만,
> **`/privacy` 는 분기 대상이 아니라 입력한 주소가 그대로 열린다.**
> 영어(미국) 칸에 `/privacy`(한국어) 를 넣어두면 **영어권 심사자에게 한국어 방침이 열린다** — 리젝 사유가 될 수 있다.
> 두 페이지 모두 라이브 확인 완료(2026-08-15, 각각 200 응답):
> `https://pizza-clip.com/privacy` (한) · `https://pizza-clip.com/en/privacy` (영)

> ### ✅ 앱 안의 방침 링크는 이미 충족됨
> 심사 지침 5.1.1 은 방침 링크를 **ASC 메타데이터 + 앱 안** 양쪽에 두라고 요구한다(전문 게재는 불필요, 링크로 충분).
> 핫소스는 **설정창 버전 줄 옆의 `개인정보처리방침` 링크**가 이를 충족하고,
> `SettingsView.privacyURL` 이 앱 언어에 따라 `/privacy` ↔ `/en/privacy` 로 알아서 분기한다. **추가 작업 없음.**

### 4-5. 이 버전의 새로운 기능 (What's New) — **이번에 유일하게 새로 써야 할 항목**

> 이스터에그(메뉴바 5연타)는 **일부러 다 밝히지 않았다.** 정확히 몇 번인지 적으면
> 이스터에그가 아니라 그냥 기능이 된다. "여러 번 눌러보라"까지만 흘린다.

**한국어** (4000자 제한 · 아래는 191자)
```
· 팝업의 얼굴을 고를 수 있어요 — 기본, 피자, 쥐, 곰돌이 네 가지. 설정 → 모양에서 바꿉니다.
· 맥이 힘들어할 때 터지는 핫소스 폭죽이 흐려지지 않고 끝까지 선명하게 떨어져요.
· 폭죽이 터지는 조건을 조금 낮췄어요. 이제 맥이 정말 바쁠 때 가끔 만날 수 있습니다.
· 메뉴바의 핫소스 병을 빠르게 여러 번 눌러보세요. 뭔가 있을지도 몰라요. 🌶️
· 처음 설치하면 '로그인 시 자동 시작'이 켜진 채로 시작합니다. 설정에서 언제든 끌 수 있어요.
```

**English (U.S.)** (아래는 447자)
```
· Pick the faces in your popup — Classic, Pizza, Mouse, or Bear. Change them in Settings → Appearance.
· The hot-sauce burst no longer fades out early. Every bottle stays sharp until it falls off screen.
· Lowered the bar for that burst, so you can actually catch it when your Mac is working hard.
· Try clicking the hot-sauce bottle in your menu bar a few times, quickly. There might be something there. 🌶️
· Launch at login now starts enabled on a fresh install. You can turn it off in Settings anytime.
```

> 💡 **설명(4-2)도 한 줄 보태면 좋다** — 얼굴 아이콘 4종은 스토어 페이지에서 눈에 띄는
> 차별점인데 지금 설명에는 없다. 기능 목록에 아래 한 줄을 끼워 넣는 것을 권한다.
> (설명 수정은 심사를 다시 받지만, 어차피 이번에 심사에 올라가므로 추가 비용이 없다.)
>
> 한국어: `· 팝업 얼굴을 기본·피자·쥐·곰돌이 중에서 골라 쓸 수 있어요.`
> English: `· Choose your popup faces: Classic, Pizza, Mouse, or Bear.`

### 4-6. 저작권 (Copyright)

```
2026 TEAM jAm
```
> 번들의 `NSHumanReadableCopyright` 는 `© 2026 TEAM jAm. All rights reserved.` 이지만,
> ASC 저작권 란은 **© 기호와 "All rights reserved" 없이 연도 + 소유자**만 적는 게 규칙이다.

### 4-7. 스크린샷 (준비해두신 것 업로드)

| 요구사항 | 내용 |
|---|---|
| 필수 크기 | **1280×800** 또는 1440×900 / 2560×1600 / 2880×1800 중 하나로 통일 |
| 개수 | 최소 1장, 최대 10장 |
| ⚠️ 필수 조건 | **팝업이 열려 있는 데스크톱 화면**이어야 한다 — 메뉴바 앱이라 팝업이 안 보이면 심사에서 "기능을 확인할 수 없다"는 지적을 받는다 |
| 권장 구성 | ① 팝업 전체 + 메뉴바 아이콘이 함께 보이는 샷 ② 부하 상태(노랑/무지개 병) 샷 ③ 설정 창 샷 |
| 주의 | 스크린샷에 실제 개인정보(로컬 IP 등)가 크게 노출되면 가려서 올리는 편이 낫다 |

---

## 5. App Privacy (앱 개인정보 보호) 설문

앱 정보 사이드바 → **앱 개인정보 보호** → "데이터 수집" 질문에서:

📌 **"이 앱에서 사용자로부터 데이터를 수집하지 않습니다"** (Data Not Collected) 선택

- 근거: 계정·로그인 없음, 광고/분석 SDK 없음, 지표를 화면 표시 외 전송하지 않음, 네트워크 통신 없음
- 개인정보처리방침 2번 항목이 "웹사이트 접속 기록은 **직접 다운로드 버전 사이트**에만 해당"으로 명시돼 있어 이 답변과 모순되지 않는다
- 개인정보처리방침 URL 도 여기서 한 번 더 입력해야 한다 → `https://pizza-clip.com/privacy`

---

## 6. 앱 심사 정보 (App Review Information) — ⚠️ 가장 중요

로그인 계정은 **필요 없음**(체크 해제). 아래 **메모(Notes)** 를 반드시 채운다.

> LSUIElement 앱(메뉴바 전용, Dock 아이콘 없음)이라 **리뷰어가 앱을 못 찾아 리젝되는 사례가 매우 흔하다.** 이 메모가 방어선이다.

**Notes 붙여넣기 (영문 — 심사팀은 영어로 읽는다)**
```
IMPORTANT — HOW TO LAUNCH THIS APP

HotSauce is a menu bar utility (LSUIElement). It intentionally does NOT show a
Dock icon or a main window when launched.

After launching the app, please look at the MENU BAR at the top-right of the
screen. You will see a small red hot-sauce bottle icon.

  1. LEFT-CLICK the hot-sauce bottle icon in the menu bar.
     -> The main popup opens, showing CPU, Memory, Storage, Battery and
        Network statistics for the Mac.
  2. RIGHT-CLICK the same icon for the context menu (Settings / Quit).
  3. The gear icon at the bottom-right of the popup opens Settings.

The bottle icon changes color with system load (red = light, yellow = medium,
rainbow = heavy), so its appearance may differ depending on the state of the
review machine.

ABOUT FUNCTIONALITY (Guideline 4.2)
The app reads system metrics via public macOS APIs (host_statistics, sysctl,
IOKit AppleSmartBattery, getifaddrs, CoreWLAN) and presents them in a single
custom-designed popup, with load-based visual states and one-click access to
Activity Monitor. It is a complete, standalone utility, not a repackaged web
page or a thin wrapper.

PRIVACY
No accounts, no sign-in, no ads, no analytics, no data collection whatsoever.
All metrics are read and displayed locally and never leave the device. The app
is sandboxed; the com.apple.security.network.client entitlement is required
only because CoreWLAN (Wi-Fi signal strength) returns nil without it.

WHAT'S NEW IN 1.4.0
The popup's face icons are now user-selectable (Settings > Appearance): Classic,
Pizza, Mouse or Bear. This only swaps bundled images; no new capability is used.

One behaviour worth flagging: on a FRESH INSTALL the app registers itself as a
login item once, using SMAppService. A menu bar monitor is only useful if it is
running, so this is the expected default for this category of app. It happens
ONLY on first launch, it is clearly reflected in Settings > General > "Launch at
login", and if the user turns it off the app never re-enables it.

Thank you for reviewing!
```

**연락처 정보**

| 항목 | 값 |
|---|---|
| 이름 / 성 | ✅ (본인 이름) |
| 전화번호 | ✅ (본인 번호, 국가번호 포함 `+82…`) |
| 이메일 | ✅ `jekeun.p@gmail.com` |

---

## 7. 버전 출시 (Version Release)

📌 **"이 버전을 수동으로 출시"** 권장

- 심사 통과 후 원하는 시점에 직접 출시 버튼을 누를 수 있다
- 웹사이트·릴리스노트 갱신 타이밍과 맞추기 좋다
- 자동 출시로 하면 심사 통과 즉시(새벽일 수도) 스토어에 올라간다

---

## 8. 제출 전 최종 점검표

**1.4.0 업데이트에서 실제로 해야 하는 것 (짧다)**

- [ ] ASC 에 **1.4.0 버전 레코드 새로 추가** (위 🚨 절)
- [ ] Organizer 에서 **빌드 11 업로드** 후 처리 완료 대기
- [ ] 빌드 섹션에서 **빌드 11** 선택
- [ ] **"이 버전의 새로운 기능"** 한/영 입력 (4-5) ← 이번의 핵심
- [ ] 제출

> 📌 **스크린샷·설명은 1.3.0 것을 그대로 간다**(사용자 결정 2026-09-06).
>    얼굴 아이콘 세트를 보여주는 샷은 다음 업데이트 때 함께 고려한다 —
>    4-5 아래 💡 의 설명 추가 제안도 그때까지 보류.

**아래는 1.3.0 때 이미 채운 것들 — 새 버전에 자동 복사되므로 확인만 하면 된다**

- [ ] 부제·설명·키워드·프로모션 텍스트 (한국어) 그대로 넘어왔는지
- [ ] **English (U.S.) 현지화** 그대로 넘어왔는지 — 기본 언어가 한국어라 빠지면 미국에서도 한국어가 뜬다
- [ ] 지원 URL · 마케팅 URL · 개인정보처리방침 URL
- [ ] **영어(미국) 방침 URL 이 `/en/privacy` 인지** (`/privacy` 면 심사자에게 한국어 방침이 열린다)
- [ ] 연령 등급 4+ · App Privacy "데이터를 수집하지 않습니다"
- [ ] 가격 무료 · 국가 **미국·대한민국 두 곳만**
- [ ] **앱 심사 정보 메모에 메뉴바 안내 기재** (가장 중요)
- [ ] 저작권 `2026 TEAM jAm`
- [ ] 수동 출시 선택
- [ ] "심사를 위해 제출" 클릭

---

## 9. English (U.S.) 현지화 추가하는 법

기본 언어가 한국어라, 영어권 사용자에게도 한국어 설명이 나간다. 반드시 추가할 것.

1. 버전 페이지(1.4.0) 좌측 상단의 **언어 드롭다운**(현재 "한국어") 클릭
2. 목록 아래 **`언어 추가` / `Add Language`** 선택
3. **English (U.S.)** 선택
4. 위 4절의 **English (U.S.)** 값들을 채워 넣는다 — 부제 · 프로모션 텍스트 · 설명 · 키워드 · URL · 새로운 기능
5. **스크린샷도 언어별로 따로 올려야 한다** (같은 이미지를 재사용해도 무방)

---

## 참고 — 이 문서의 출처

- 앱 카피: `web/src/i18n/hotsauce.ts` (웹 페이지 문구 재구성)
- 릴리스노트: `web/src/i18n/info.ts` (핫소스 1.3.0 항목까지 반영 완료)
  ⚠️ **1.4.0 이 출시되면 `info.ts` 에 1.4.0 항목을 추가할 것.** 웹은 앱스토어와 별개라
     자동으로 따라가지 않는다. 출시 확정 후에 넣어야 "없는 버전"을 안내하지 않는다.
- 개인정보 근거: `web/src/i18n/privacy.ts` + 세션 9 샌드박스 실측 결과
- 번들 정보: `apps/hotsauce/HotSauce/Resources/Info-MAS.plist`
- 심사 리스크·지뢰: `apps/hotsauce/docs/HANDOFF.md` 세션 9·10·12
