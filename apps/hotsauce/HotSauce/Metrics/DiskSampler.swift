import Foundation

/// 루트 볼륨의 총용량/사용량. Finder와 같은 기준(중요 데이터용 여유 공간)을 쓴다.
final class DiskSampler {

    func sample() -> DiskSnapshot {
        var snapshot = DiskSnapshot()
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
            ])
            if let total = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacityForImportantUsage {
                snapshot.totalBytes = UInt64(total)
                snapshot.usedBytes = UInt64(max(0, Int64(total) - available))
            }
        } catch {
            // 볼륨 정보를 못 읽으면 0/1 그대로 둔다 (게이지 0%)
        }
        return snapshot
    }
}
