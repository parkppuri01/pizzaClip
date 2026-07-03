import AppKit

/// borderless + nonactivatingPanel 은 기본적으로 키 입력을 못 받으므로
/// canBecomeKey 를 강제로 켠 패널. 포커스를 잃으면 스스로 닫힌다. (pizzaClip 패턴)
final class FocusablePanel: NSPanel {
    var onClose: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
        onClose?()
    }

    override func cancelOperation(_ sender: Any?) {
        // ESC 로 닫기
        orderOut(nil)
        onClose?()
    }
}
