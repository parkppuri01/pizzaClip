import Foundation
import Darwin

/// host_statistics 틱 차분으로 CPU 사용률을 구한다.
/// 런캣과 동일하게 5샘플 이동평균으로 순간 스파이크를 눌러준다.
final class CPUSampler {
    private var previousLoad: host_cpu_load_info?
    private var recentTotals: [Double] = []

    struct Reading {
        var total: Double
        var system: Double
        var user: Double
        var idle: Double
    }

    private func readTicks() -> host_cpu_load_info? {
        var size = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        return result == KERN_SUCCESS ? info : nil
    }

    /// 1초마다 호출. 직전 호출과의 틱 차이로 사용률 계산.
    func sample() -> Reading? {
        guard let current = readTicks() else { return nil }
        defer { previousLoad = current }
        guard let previous = previousLoad else { return nil }

        func tick(_ t: (natural_t, natural_t, natural_t, natural_t), _ i: Int) -> natural_t {
            switch i {
            case 0: return t.0
            case 1: return t.1
            case 2: return t.2
            default: return t.3
            }
        }
        func delta(_ index: Int32) -> Double {
            let i = Int(index)
            return Double(tick(current.cpu_ticks, i) &- tick(previous.cpu_ticks, i))
        }

        let user = delta(CPU_STATE_USER) + delta(CPU_STATE_NICE)
        let system = delta(CPU_STATE_SYSTEM)
        let idle = delta(CPU_STATE_IDLE)
        let total = user + system + idle
        guard total > 0 else { return nil }

        let reading = Reading(
            total: min(100, (user + system) / total * 100),
            system: min(100, system / total * 100),
            user: min(100, user / total * 100),
            idle: max(0, idle / total * 100))

        recentTotals.append(reading.total)
        if recentTotals.count > 5 { recentTotals.removeFirst() }
        return reading
    }

    /// 최근 5샘플 이동평균 (메뉴바 병 상태 판정용)
    var smoothedTotal: Double {
        guard !recentTotals.isEmpty else { return 0 }
        return recentTotals.reduce(0, +) / Double(recentTotals.count)
    }
}
