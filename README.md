# pizza-clip.com — 모노레포

세 개의 macOS 앱과, 이들을 소개·배포하는 공용 웹사이트(**pizza-clip.com**)를 한 저장소에서 관리합니다.

## 📁 구조

```
pizza-clip.com/
├── web/                  # 공용 웹사이트 (Astro) → https://pizza-clip.com  (Vercel 배포)
└── apps/
    ├── pizzaclip/        # PizzaClip — macOS 앱 (Xcode / xcodegen)
    ├── pickle/           # PICkle    — macOS 앱
    └── hotsauce/         # HotSauce  — macOS 앱 (런칭 전)
```

## 🌐 웹사이트 (`web/`)

- 스택: Astro, 다국어(ko/en), Vercel 배포. 세 앱의 랜딩·다운로드·릴리스노트를 담당.
- 로컬 실행:
  ```bash
  cd web
  npm install
  npm run dev      # 개발 서버
  npm run build    # 프로덕션 빌드
  ```
- 배포: `master` 브랜치에 push → Vercel 자동 배포 (Vercel Root Directory = `web`).

## 🖥️ 앱 (`apps/*`)

각 앱은 [xcodegen](https://github.com/yonaskolb/XcodeGen) 기반입니다 (`.xcodeproj` 는 커밋하지 않고 생성).

```bash
cd apps/pizzaclip        # 또는 pickle · hotsauce
xcodegen generate        # project.yml → .xcodeproj 생성
open *.xcodeproj
```

- 서명키 `Signing.xcconfig` 는 각 앱 폴더에 **로컬로만** 보관합니다(git 제외). `Signing.xcconfig.example` 참고.
- 릴리스: `apps/<app>/scripts/release.sh` — DMG 빌드·서명·공증·GitHub Releases 업로드 후, 사이트의 `web/public/appcast.xml`(자동 업데이트용)을 갱신합니다.

## 🔗 Git / GitHub

- 원격 저장소: `github.com/parkppuri01/pizzaClip.git`
- 기본 브랜치: `master`

## 📝 용량 정책

`build/`, `node_modules/`, 앱 `dist/`(빌드 산출물), 디자인 원본(`web/site-renewal/`, `*.pxd`, 대용량 가이드 미디어 등)은 용량이 커서 **git에 올리지 않고 로컬에만** 보관합니다. 각 `.gitignore` 참고.
