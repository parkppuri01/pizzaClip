import Foundation

/// 시스템 상태 3단계 — 팝업 얼굴 아이콘 & 메뉴바 병 색상이 이 값을 따라간다.
enum LoadState {
    case good    // 쾌적 (민트 얼굴)
    case normal  // 중부하 (주황 얼굴)
    case bad     // 고부하 (빨강 얼굴)

    var faceAssetName: String {
        switch self {
        case .good: return "good_icon"
        case .normal: return "nomal_icon"
        case .bad: return "bad_icon"
        }
    }

    /// 메뉴바 병 매핑: 쾌적=빨강(기본 병), 중부하=노랑, 고부하=레인보우.
    /// 순서를 바꾸고 싶으면 여기 파일명만 바꾸면 된다.
    var bottleAssetName: String {
        switch self {
        case .good: return "menubar_1"
        case .normal: return "menubar_2"
        case .bad: return "menubar_3"
        }
    }
}

struct CPUSnapshot {
    var totalPercent: Double = 0
    var systemPercent: Double = 0
    var userPercent: Double = 0
    var idlePercent: Double = 100

    /// 얼굴/병 판정 — 게이지가 보여주는 값(전체 사용률)을 그대로 따른다.
    /// 50/80 기준은 일상 사용에서 거의 안 바뀌어서 35/70 으로 민감하게 조정.
    var state: LoadState {
        if totalPercent < 35 { return .good }
        if totalPercent < 70 { return .normal }
        return .bad
    }
}

struct MemorySnapshot {
    var pressurePercent: Double = 0
    var usedBytes: UInt64 = 0
    var cachedBytes: UInt64 = 0
    var swapUsedBytes: UInt64 = 0
    var totalBytes: UInt64 = 1
    /// sysctl kern.memorystatus_vm_pressure_level: 1=normal 2=warning 4=critical
    var pressureLevel: Int = 1

    var usedFraction: Double { Double(usedBytes) / Double(totalBytes) }

    /// 얼굴 판정 — 게이지(사용률)를 기본으로 하고, 커널 공식 압력 단계가
    /// 더 나쁘면 그쪽으로 격상한다. (커널 단계만 보면 평소에 거의 안 바뀜)
    var state: LoadState {
        var byUsage: LoadState = .good
        if usedFraction >= 0.8 { byUsage = .bad }
        else if usedFraction >= 0.6 { byUsage = .normal }

        switch pressureLevel {
        case 4: return .bad
        case 2: return byUsage == .bad ? .bad : .normal
        default: return byUsage
        }
    }
}

struct DiskSnapshot {
    var usedBytes: UInt64 = 0
    var totalBytes: UInt64 = 1

    var usedFraction: Double { Double(usedBytes) / Double(totalBytes) }

    var state: LoadState {
        if usedFraction < 0.7 { return .good }
        if usedFraction < 0.9 { return .normal }
        return .bad
    }
}

struct BatterySnapshot {
    var isPresent: Bool = false
    var levelPercent: Int = 0
    var temperatureCelsius: Double? = nil
    var cycleCount: Int? = nil
    var isCharging: Bool = false
    /// 충전기(어댑터) 연결 여부. IsCharging은 최적화충전으로 자주 false라 아이콘 판단엔 이걸 쓴다.
    var externalConnected: Bool = false

    var state: LoadState {
        guard isPresent else { return .good }  // 데스크톱 맥: 배터리 없음 = 정상
        if levelPercent >= 50 || isCharging { return .good }
        if levelPercent >= 20 { return .normal }
        return .bad
    }
}

struct NetworkSnapshot {
    var localIP: String? = nil
    /// 0~5 (Wi-Fi 신호 세기. 유선이면 5, 연결 없으면 0)
    var signalBars: Int = 0
    var uploadBytesPerSec: Double = 0
    var downloadBytesPerSec: Double = 0
    var isConnected: Bool = false

    var state: LoadState {
        guard isConnected else { return .bad }
        if signalBars >= 4 { return .good }
        if signalBars >= 2 { return .normal }
        return .bad
    }
}

/// 팝업과 메뉴바가 구독하는 전체 스냅샷 한 덩어리.
struct SystemSnapshot {
    var cpu = CPUSnapshot()
    var memory = MemorySnapshot()
    var disk = DiskSnapshot()
    var battery = BatterySnapshot()
    var network = NetworkSnapshot()
}
