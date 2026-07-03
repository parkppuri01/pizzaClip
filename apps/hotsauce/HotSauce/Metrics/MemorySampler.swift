import Foundation
import Darwin

/// vm_statistics64 + sysctl 로 메모리 사용량/압력/스왑을 읽는다.
final class MemorySampler {

    func sample() -> MemorySnapshot {
        var snapshot = MemorySnapshot()
        snapshot.totalBytes = ProcessInfo.processInfo.physicalMemory

        var size = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var stats = vm_statistics64()
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }
        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            let wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            let internalPages = UInt64(stats.internal_page_count) * pageSize
            let purgeable = UInt64(stats.purgeable_count) * pageSize
            let external = UInt64(stats.external_page_count) * pageSize

            // 활성 상태 보기(Activity Monitor)의 "메모리 사용됨" 근사치
            snapshot.usedBytes = internalPages &- min(purgeable, internalPages) &+ wired &+ compressed
            // "캐시된 파일" 근사치
            snapshot.cachedBytes = external &+ purgeable
            // 압력 근사치: (고정 + 압축) / 전체
            snapshot.pressurePercent = min(100,
                Double(wired &+ compressed) / Double(snapshot.totalBytes) * 100)
        }

        // 커널이 알려주는 공식 압력 단계 (1=normal, 2=warning, 4=critical)
        var level: Int32 = 1
        var levelSize = MemoryLayout<Int32>.size
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &levelSize, nil, 0) == 0 {
            snapshot.pressureLevel = Int(level)
        }

        // 스왑 사용량
        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0) == 0 {
            snapshot.swapUsedBytes = swap.xsu_used
        }

        return snapshot
    }
}
