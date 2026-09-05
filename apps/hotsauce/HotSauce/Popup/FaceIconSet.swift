import Foundation

/// 팝업 오른쪽 열의 얼굴 아이콘 세트. 설정 → 일반에서 고른다.
///
/// ## 새 세트를 추가하려면
/// 1. 아래 `case` 를 하나 늘리고 `label` 에 표시 이름을 적는다.
/// 2. PNG 3장을 `Resources/DesignAssets/` 에 넣는다 — 파일명 규칙은
///    **`face_<rawValue>_<good|normal|bad>.png`** (예: `face_pizza_good.png`).
///    원본은 `images/<세트이름>/` 에 두고 여기로 복사해 쓴다
///    (`images/` 는 gitignore — 디자인 원본은 저장소에 넣지 않는다).
/// 3. 끝. `xcodegen generate` 도 필요 없다(폴더 통째로 리소스에 들어간다).
///
/// ## ⚠️ 에셋 규격 — 이걸 어기면 팝업 열 정렬이 흐트러진다
/// - **1024×1024 정사각 PNG**
/// - **캔버스를 꽉 채울 것.** 기본 세트는 내용이 캔버스의 99.7% 다(실측).
///   여백을 두면 그 세트만 작아 보여서, 다른 행의 얼굴과 크기가 어긋나 보인다.
/// - 팝업은 61×61 유닛 정사각 프레임에 `scaledToFit` 으로 그린다(`PopupView.face`).
///   종횡비가 정사각이 아니면 프레임 안에서 한쪽이 남아 중심이 밀린다.
///
/// 파일이 번들에 없으면 조용히 기본 세트로 떨어진다 — 세트를 먼저 추가하고
/// 그림을 나중에 넣어도 앱이 깨지지 않는다.
enum FaceIconSet: String, CaseIterable, Identifiable {
    /// 출시 때부터 쓰던 얼굴. 파일명이 규칙과 달라서 따로 매핑한다.
    case classic
    case pizza
    case mouse
    case bear

    static let fallback: FaceIconSet = .classic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic: return L("Classic", "기본")
        case .pizza:   return L("Pizza", "피자")
        case .mouse:   return L("Mouse", "쥐")
        case .bear:    return L("Bear", "곰돌이")
        }
    }

    /// 상태별 에셋 이름. 해당 PNG 가 번들에 없으면 기본 세트 이름을 돌려준다.
    func assetName(for state: LoadState) -> String {
        guard self != .classic else { return Self.classicName(state) }
        let name = "face_\(rawValue)_\(Self.suffix(state))"
        return Assets.exists(name) ? name : Self.classicName(state)
    }

    /// UserDefaults 에 저장된 문자열 → 세트. 모르는 값이면 기본.
    static func resolve(_ raw: String) -> FaceIconSet {
        FaceIconSet(rawValue: raw) ?? fallback
    }

    private static func classicName(_ state: LoadState) -> String {
        switch state {
        case .good:   return "good_icon"
        case .normal: return "nomal_icon"   // 원본 파일명 오타지만 에셋이 그 이름이다
        case .bad:    return "bad_icon"
        }
    }

    private static func suffix(_ state: LoadState) -> String {
        switch state {
        case .good:   return "good"
        case .normal: return "normal"
        case .bad:    return "bad"
        }
    }
}
