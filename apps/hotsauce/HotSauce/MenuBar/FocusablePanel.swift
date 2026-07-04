import AppKit

/// borderless + nonactivatingPanel 은 기본적으로 키 입력을 못 받으므로
/// canBecomeKey 를 강제로 켠 패널. 포커스를 잃으면 스스로 닫힌다. (pizzaClip 패턴)
final class FocusablePanel: NSPanel {
    var onClose: (() -> Void)?
    /// 자물쇠 잠금. true면 포커스를 잃어도 팝업이 안 닫힌다(고정 보기).
    var isLocked = false

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func resignKey() {
        super.resignKey()
        if isLocked { return }   // 잠금 중이면 포커스를 잃어도 닫지 않는다
        orderOut(nil)
        onClose?()
    }

    override func cancelOperation(_ sender: Any?) {
        // ESC 로 닫기
        orderOut(nil)
        onClose?()
    }
}
