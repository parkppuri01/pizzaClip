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

    /// 이스터에그: 위험(빨강) 얼굴이 임계치 이상이면 값이 바뀌고, PopupView 의
    /// HotSauceBurst 가 이를 구독해 폭발을 재생한다. nil = 폭발 없음.
    @Published private(set) var burstID: UUID?
    /// 현재 과부하(빨강 4개 이상) 상태인지 — 팝업 열 때 재생 판단에 쓴다.
    private(set) var isOverloaded = false
    /// 빨강 얼굴이 몇 개부터 폭발할지(5개 중). 튜닝은 여기만 바꾸면 된다.
    ///
    /// 4 → 3 으로 낮췄다(2026-09-06). 4 는 사실상 안 터지는 값이었다 —
    /// CPU·메모리·네트워크는 쉽게 빨개지지만 나머지 둘의 문턱이 너무 높다
    /// (저장 90% 이상, 배터리 20% 미만+비충전). 만든 지 두 달이 되도록 실물을
    /// 본 사람이 없으면 이스터에그로서 값이 없다.
    private let overloadThreshold = 3

    /// 팝업을 열 때 호출 — 이미 과부하 상태면 폭발을 한 번 재생한다.
    func replayBurstIfOverloaded() {
        if isOverloaded { burstID = UUID() }
    }

    /// 이스터에그로 터뜨린 폭발을 이 시각까지는 refresh 가 지우지 않는다.
    private var burstHoldUntil: Date?
    /// 폭발 애니메이션 총 길이(HotSauceBurst: duration 3.0 + maxDelay 0.32 = 3.32)보다 넉넉히.
    private let burstHoldDuration: TimeInterval = 4.0

    /// 부하와 무관하게 폭발을 한 번 재생한다 — 메뉴바 아이콘 연타 이스터에그용.
    ///
    /// ⚠️ 그냥 `burstID` 만 바꾸면 안 된다. refresh 가 1초마다 돌면서 과부하가
    ///    아니면 `burstID = nil` 로 되돌리는데, 그러면 `.task(id:)` 가 취소돼
    ///    2.7초짜리 폭발이 1초 만에 끊긴다. 그래서 잠시 지우지 못하게 잠근다.
    func triggerBurst() {
        burstID = UUID()
        burstHoldUntil = Date().addingTimeInterval(burstHoldDuration)
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

        // 이스터에그: 5개 얼굴 중 빨강(.bad) 개수가 임계치 이상이면 폭발.
        // 위험에 "진입하는 순간" + 팝업이 열려 있을 때만 즉발(닫혀 있으면 열 때 재생).
        let badCount = [snapshot.cpu.state, snapshot.memory.state, snapshot.disk.state,
                        snapshot.battery.state, snapshot.network.state]
                        .filter { $0 == .bad }.count
        let nowOverloaded = badCount >= overloadThreshold
        if nowOverloaded {
            if !isOverloaded && isPopupVisible { burstID = UUID() }
        } else {
            // 이스터에그로 재생 중이면 건드리지 않는다(위 triggerBurst 주석 참고).
            if burstHoldUntil.map({ Date() >= $0 }) ?? true { burstID = nil }
        }
        isOverloaded = nowOverloaded
    }

    private func refreshHeavy() {
        snapshot.memory = memorySampler.sample()
        snapshot.disk = diskSampler.sample()
        snapshot.battery = batterySampler.sample()
    }
}
