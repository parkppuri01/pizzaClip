import Foundation
import IOKit

/// IORegistry 의 AppleSmartBattery 에서 잔량/온도/사이클을 읽는다.
/// 데스크톱 맥(배터리 없음)은 isPresent=false 로 표시만 비운다.
final class BatterySampler {

    func sample() -> BatterySnapshot {
        var snapshot = BatterySnapshot()

        let service = IOServiceGetMatchingService(
            kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return snapshot }
        defer { IOObjectRelease(service) }

        var propsRef: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = propsRef?.takeRetainedValue() as? [String: Any] else {
            return snapshot
        }

        snapshot.isPresent = (props["BatteryInstalled"] as? Bool) ?? true

        if let current = props["CurrentCapacity"] as? Int {
            if let max = props["MaxCapacity"] as? Int, max > 100 {
                // 인텔 맥: mAh 값이라 비율로 환산
                snapshot.levelPercent = Int((Double(current) / Double(max) * 100).rounded())
            } else {
                // 애플 실리콘: 이미 % 값
                snapshot.levelPercent = min(100, current)
            }
        }

        if let raw = props["Temperature"] as? Int {
            // IORegistry "Temperature" 는 0.1 켈빈 단위 (SBS Temperature() 규약).
            // 예: raw 3040 → 30.85°C. (÷100 으로 나누면 실온 근처에서만 우연히 맞아 보임)
            let celsius = Double(raw) / 10.0 - 273.15
            if celsius > 0, celsius < 120 { snapshot.temperatureCelsius = celsius }
        }

        snapshot.cycleCount = props["CycleCount"] as? Int
        snapshot.isCharging = (props["IsCharging"] as? Bool) ?? false
        return snapshot
    }
}
