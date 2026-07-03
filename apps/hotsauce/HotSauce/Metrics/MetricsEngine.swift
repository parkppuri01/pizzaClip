import Foundation
import Combine

/// 런캣과 같은 2단 폴링 구조:
/// - 1초마다: CPU 샘플(5샘플 이동평균) + 네트워크 속도
/// - 5초마다(또는 팝업이 열려 있으면 매초): 메모리/디스크/배터리 등 무거운 항목
final class MetricsEngine: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot()

    /// 메뉴바 병 상태가 바뀔 때만 호출된다.
    var onStateChange: ((LoadState) -> Void)?

    /// 팝업이 열려 있는 동안은 모든 지표를 매초 갱신.
    var isPopupVisible = false {
        didSet { if isPopupVisible { refreshHeavy() } }
    }

    private let cpuSampler = CPUSampler()
    private let memorySampler = MemorySampler()
    private let diskSampler = DiskSampler()
    private let batterySampler = BatterySampler()
    private let networkSampler = NetworkSampler()

    private var timer: Timer?
    private var tickCount = 0
    private var lastReportedState: LoadState?

    func start() {
        refreshHeavy()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        tickCount += 1

        if let reading = cpuSampler.sample() {
            snapshot.cpu = CPUSnapshot(
                totalPercent: reading.total,
                systemPercent: reading.system,
                userPercent: reading.user,
                idlePercent: reading.idle)
        }
        snapshot.network = networkSampler.sample()

        if isPopupVisible || tickCount % 5 == 0 {
            refreshHeavy()
        }

        // 메뉴바 병: 5샘플 이동평균 기준으로 상태 판정 (순간 튐 방지)
        let smoothed = CPUSnapshot(totalPercent: cpuSampler.smoothedTotal)
        let state = smoothed.state
        if state != lastReportedState {
            lastReportedState = state
            onStateChange?(state)
        }
    }

    private func refreshHeavy() {
        snapshot.memory = memorySampler.sample()
        snapshot.disk = diskSampler.sample()
        snapshot.battery = batterySampler.sample()
    }
}
