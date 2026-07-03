import Foundation

/// 디자인 시안의 표기 형식을 그대로 따르는 포맷터 모음.
/// 예: "시스템 : 12.3%", "사용 메모리 : 16.0 GB", "스왑 : 999.9MB", "업로드 : 100.0 kB/s"
enum Fmt {

    static func percent1(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    /// 메모리 계열: 1024 기반 GB, 소수 1자리 (시안: "16.0 GB")
    static func memoryGB(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    /// 스왑: MB, 소수 1자리, 단위 붙여쓰기 (시안: "999.9MB")
    static func swapMB(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1024 {
            return String(format: "%.1fGB", mb / 1024)
        }
        return String(format: "%.1fMB", mb)
    }

    /// 디스크: Finder 와 같은 1000 기반 GB (시안: "100.0 GB / 512.0 GB")
    static func diskGB(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 1000 {
            return String(format: "%.2f TB", gb / 1000)
        }
        return String(format: "%.1f GB", gb)
    }

    /// 네트워크 속도 (시안: "100.0 kB/s")
    static func speed(_ bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1000
        if kb >= 1000 {
            return String(format: "%.1f MB/s", kb / 1000)
        }
        return String(format: "%.1f kB/s", kb)
    }

    /// 신호 5칸 (시안: "● ● ○ ○ ○")
    static func signalDots(_ bars: Int) -> String {
        let filled = max(0, min(5, bars))
        let dots = (0..<5).map { $0 < filled ? "●" : "○" }
        return dots.joined(separator: " ")
    }
}
