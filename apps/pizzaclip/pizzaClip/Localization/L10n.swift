import Foundation

/// pizzaClip 의 가벼운 2개국어(영어/한국어) 현지화 헬퍼.
///
/// 표준 `.strings`/`.lproj` 리소스 대신, 호출 지점에 영어·한국어를 함께 적는
/// `L("English", "한국어")` 방식이다. 문자열과 번역이 한 줄에 붙어 있어
/// 누락/드리프트가 없고, 별도 리소스 번들 연결도 필요 없다.
///
/// 언어는 **앱 시작 시 1회** 확정된다(`AppLocale.isKorean`). 그래서 Settings 에서
/// 언어를 바꾸면 "재시작 필요" 안내 후 적용된다 — AppKit 메뉴/NSAlert 처럼 시작
/// 시점에 한 번 만들어지는 UI 가 세션 도중 반쪽만 바뀌는 일을 막기 위함이다.

/// 사용자가 고를 수 있는 언어 옵션 (System / English / 한국어).
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case korean = "ko"
    case english = "en"

    var id: String { rawValue }

    /// Settings 피커에 보일 이름. "시스템"만 현재 언어 따라 번역, 나머지는 고정.
    var displayName: String {
        switch self {
        case .system:  return L("System", "시스템")
        case .english: return "English"
        case .korean:  return "한국어"
        }
    }
}

/// 현재 세션에서 실제로 적용된 언어를 보관한다.
enum AppLocale {
    static let defaultsKey = "appLanguage"

    /// 프로세스 시작 시 1회만 계산된다(static let = 최초 접근 시 고정).
    /// system 이면 OS 선호 언어를 따라 한국어 여부를 판단한다.
    static let isKorean: Bool = {
        let raw = UserDefaults.standard.string(forKey: defaultsKey)
            ?? AppLanguage.system.rawValue
        switch AppLanguage(rawValue: raw) ?? .system {
        case .english: return false
        case .korean:  return true
        case .system:
            let first = Locale.preferredLanguages.first ?? "en"
            return first.lowercased().hasPrefix("ko")
        }
    }()

    /// 날짜/숫자 포매터 등에 넘길 Locale (앱 언어 설정을 따름).
    static var current: Locale {
        Locale(identifier: isKorean ? "ko_KR" : "en_US")
    }
}

/// 영어/한국어 중 현재 앱 언어에 맞는 문자열을 돌려준다.
/// 사용 예: `Text(L("General", "일반"))`
func L(_ en: String, _ ko: String) -> String {
    AppLocale.isKorean ? ko : en
}
