import SwiftUI
import AppKit

/// hotsauce.pxd 에서 추출한 디자인 원본 좌표계(900×1000)와 색상.
/// 모든 뷰 좌표는 디자인 유닛으로 쓰고, scale 로 실제 포인트로 환산한다.
/// 팝업 크기를 바꾸고 싶으면 scale 하나만 바꾸면 된다.
/// 0.52 → 468×520pt (피클 팝업 460×500 보다 조금 크게 — 사용자 확정)
enum DS {
    static let scale: CGFloat = 0.52

    static func u(_ value: CGFloat) -> CGFloat { value * scale }

    static let canvasWidth: CGFloat = 900
    static let canvasHeight: CGFloat = 1000
    static var popupSize: CGSize { CGSize(width: u(canvasWidth), height: u(canvasHeight)) }

    // ── 색상 (pxd 벡터 데이터 + 렌더 샘플에서 추출한 정확한 값) ──
    static let background = Color(red: 0x3A / 255, green: 0x3A / 255, blue: 0x3C / 255)
    static let text = Color(red: 0xDE / 255, green: 0xE0 / 255, blue: 0xE2 / 255)
    static let divider = Color(red: 0x92 / 255, green: 0x92 / 255, blue: 0x92 / 255)
    static let gaugeFill = Color(red: 0xB6 / 255, green: 0x42 / 255, blue: 0x2E / 255)
    static let gaugeBorder = Color(red: 0xDE / 255, green: 0xE0 / 255, blue: 0xE2 / 255)

    static let cornerRadius: CGFloat = 40  // 디자인 유닛

    // ── 폰트: 디자인 전체가 Pretendard-Regular ──
    static func font(_ designSize: CGFloat) -> Font {
        .custom("Pretendard-Regular", size: u(designSize))
    }

    static let headerFontSize: CGFloat = 27   // "Hot sauce - 시스템 모니터"
    static let titleFontSize: CGFloat = 20    // 섹션 제목 (CPU, 메모리 …)

    /// 상세 수치 텍스트는 "더 줄면 안 보이는 최소 크기"라서 팝업 축소와 무관하게
    /// 절대 포인트로 고정한다. (디자인 14.5u × 0.6 = 8.7pt — 사용자 확정)
    static let statFontPoints: CGFloat = 8.7

    static var statFont: Font {
        .custom("Pretendard-Regular", size: statFontPoints)
    }
}

/// 번들에 넣은 디자인 PNG 로더.
enum Assets {
    static func image(_ name: String) -> NSImage {
        if let image = NSImage(named: name) { return image }
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            image.setName(name)
            return image
        }
        return NSImage(size: NSSize(width: 1, height: 1))
    }
}

// ── 디자인 좌표(topLeading 기준) 배치 헬퍼 ──
extension View {
    /// 왼쪽 끝 x + 세로 중심 y 로 배치 (텍스트처럼 폭이 변하는 요소용)
    func placedLeft(_ left: CGFloat, centerY: CGFloat, rowHeight: CGFloat = 30) -> some View {
        self
            .fixedSize()
            .frame(height: DS.u(rowHeight))
            .offset(x: DS.u(left), y: DS.u(centerY - rowHeight / 2))
    }

    /// 중심 좌표 + 크기로 배치 (아이콘, 게이지 등 고정 크기 요소용)
    func placedCenter(_ centerX: CGFloat, _ centerY: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        self
            .frame(width: DS.u(w), height: DS.u(h))
            .offset(x: DS.u(centerX - w / 2), y: DS.u(centerY - h / 2))
    }
}
