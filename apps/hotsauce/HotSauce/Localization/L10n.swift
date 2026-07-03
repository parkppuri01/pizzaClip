import Foundation
import SwiftUI

/// 초경량 현지화 (pizzaClip 패턴): 호출 지점에 영/한을 병기해서 누락이 없다.
/// 예: L("Quit", "종료")
func L(_ english: String, _ korean: String) -> String {
    AppLocale.isKorean ? korean : english
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case korean = "ko"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return L("System", "시스템 설정 따름")
        case .english: return "English"
        case .korean: return "한국어"
        }
    }
}

enum AppLocale {
    /// 앱 시작 시 1회 고정 — AppKit 메뉴가 세션 도중 반쪽만 바뀌는 것 방지.
    /// 언어 변경은 앱 재시작 후 반영된다.
    static let isKorean: Bool = {
        let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        switch stored {
        case "ko": return true
        case "en": return false
        default:
            return Locale.preferredLanguages.first?.hasPrefix("ko") ?? false
        }
    }()
}
